import SwiftUI
import MorningBoardKit

@main
struct MorningBoardTVApp: App {
    @StateObject private var model = TVBoardModel()

    var body: some Scene {
        WindowGroup {
            TVBoardRootView()
                .environmentObject(model)
        }
    }
}

@MainActor
final class TVBoardModel: ObservableObject {
    enum Phase {
        case loading
        case empty
        case ready
        case stale
    }

    @Published var snapshot: MorningSnapshot?
    @Published var phase: Phase = .loading
    @Published var statusMessage = "Pulling today’s board from iCloud…"

    private let store: any BoardStore
    private let staleAfter: TimeInterval

    init(
        store: any BoardStore = InMemoryBoardStore(seed: DemoSnapshots.restedMorning()),
        staleAfter: TimeInterval = 60 * 60 * 18
    ) {
        self.store = store
        self.staleAfter = staleAfter
    }

    func refresh() async {
        phase = .loading
        do {
            guard let latest = try await store.latestSnapshot() else {
                snapshot = nil
                phase = .empty
                statusMessage = "No board yet. Open the iPhone app, connect Health, then Publish."
                return
            }
            snapshot = latest
            let age = Date().timeIntervalSince(latest.generatedAt)
            if age > staleAfter {
                phase = .stale
                statusMessage = "Board looks stale. Open iPhone Morning Board to refresh Health."
            } else {
                phase = .ready
                statusMessage = latest.isDemo
                    ? "Demo snapshot · replace by publishing from iPhone"
                    : "Updated \(latest.generatedAt.formatted(date: .omitted, time: .shortened))"
            }
        } catch {
            phase = .empty
            statusMessage = "Could not reach iCloud: \(error.localizedDescription)"
        }
    }
}

struct TVBoardRootView: View {
    @EnvironmentObject private var model: TVBoardModel
    @Namespace private var boardFocus

    var body: some View {
        ZStack {
            MorningAtmosphere()
            content
                .padding(.horizontal, 80)
                .padding(.vertical, 60)
        }
        .focusScope(boardFocus)
        .task { await model.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView("Loading morning board")
                .font(.title3)
        case .empty:
            EmptyBoardView(message: model.statusMessage) {
                Task { await model.refresh() }
            }
        case .ready, .stale:
            if let snapshot = model.snapshot {
                MorningBoardView(
                    snapshot: snapshot,
                    statusMessage: model.statusMessage,
                    isStale: model.phase == .stale,
                    onRefresh: { Task { await model.refresh() } },
                    focusNamespace: boardFocus
                )
            }
        }
    }
}

struct MorningBoardView: View {
    let snapshot: MorningSnapshot
    let statusMessage: String
    let isStale: Bool
    let onRefresh: () -> Void
    var focusNamespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(greeting)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                    Text(snapshot.readinessBand.displayName)
                        .font(.system(size: 84, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(snapshot.insight)
                        .font(.system(size: 34, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))
                        .frame(maxWidth: 980, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                readinessDial
            }
            .focusSection()

            HStack(alignment: .top, spacing: 28) {
                BoardMetricTile(
                    title: "Sleep",
                    value: sleepValue,
                    detail: sleepDetail,
                    source: sourceName(for: "sleep")
                )
                BoardMetricTile(
                    title: "Load",
                    value: loadValue,
                    detail: loadDetail,
                    source: sourceName(for: "steps")
                )
                BoardMetricTile(
                    title: "Last session",
                    value: workoutValue,
                    detail: workoutDetail,
                    source: nil
                )
            }
            .focusSection()

            HStack {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(isStale ? Color.orange : Color.white.opacity(0.55))
                Spacer()
                Button("Refresh", action: onRefresh)
                    .prefersDefaultFocus(in: focusNamespace)
            }
        }
    }

    private var readinessDial: some View {
        VStack(spacing: 8) {
            Text("\(snapshot.readinessScore)")
                .font(.system(size: 120, weight: .light, design: .rounded))
                .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.38))
            Text("READINESS")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(width: 260)
        .padding(.vertical, 18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var greeting: String {
        "Good morning · \(snapshot.dayKey)"
    }

    private var sleepValue: String {
        guard let sleep = snapshot.sleepHours else { return "—" }
        return String(format: "%.1fh", sleep)
    }

    private var sleepDetail: String {
        if let score = snapshot.sleepScore {
            return "Score \(score)"
        }
        return snapshot.sleepHours == nil ? "Waiting on sync" : "Last night"
    }

    private var loadValue: String {
        guard let steps = snapshot.stepsYesterday else { return "—" }
        return steps.formatted()
    }

    private var loadDetail: String {
        if let cal = snapshot.moveCaloriesYesterday {
            return "\(Int(cal)) move cal yesterday"
        }
        return "Steps yesterday"
    }

    private var workoutValue: String {
        snapshot.lastWorkout?.name ?? "—"
    }

    private var workoutDetail: String {
        guard let workout = snapshot.lastWorkout else { return "No workout logged" }
        return "\(workout.durationMinutes) min · \(workout.activityType)"
    }

    private func sourceName(for metric: String) -> String? {
        snapshot.sources.first(where: { $0.metric == metric })?.displayName
    }
}

struct BoardMetricTile: View {
    let title: String
    let value: String
    let detail: String
    let source: String?

    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                if let source {
                    Text(source)
                        .font(.caption2)
                        .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.38).opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
            .padding(28)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.card)
    }
}

struct EmptyBoardView: View {
    let message: String
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Morning Board")
                .font(.largeTitle.weight(.semibold))
            Text(message)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 760)
            Text("1. Install Morning Board on iPhone\n2. Connect Apple Health\n3. Tap Publish to Apple TV")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Try again", action: onRefresh)
        }
    }
}

struct MorningAtmosphere: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.09, blue: 0.14),
                Color(red: 0.10, green: 0.14, blue: 0.22),
                Color(red: 0.16, green: 0.12, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            RadialGradient(
                colors: [Color(red: 1.0, green: 0.72, blue: 0.38).opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 700
            )
            .ignoresSafeArea()
        }
    }
}
