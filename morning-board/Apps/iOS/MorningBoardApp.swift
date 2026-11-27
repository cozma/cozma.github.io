import SwiftUI
import MorningBoardKit

@main
struct MorningBoardApp: App {
    @StateObject private var model = CompanionModel()

    var body: some Scene {
        WindowGroup {
            CompanionRootView()
                .environmentObject(model)
        }
    }
}

@MainActor
final class CompanionModel: ObservableObject {
    @Published var snapshot: MorningSnapshot
    @Published var preferences = BoardPreferences()
    @Published var healthAuthorized = false
    @Published var statusMessage = "Grant Health access to publish today’s board."

    private let store: any BoardStore
    private let health: any HealthReading

    init(
        store: any BoardStore = InMemoryBoardStore(seed: DemoSnapshots.restedMorning()),
        health: any HealthReading = DemoHealthReader()
    ) {
        self.store = store
        self.health = health
        self.snapshot = DemoSnapshots.restedMorning()
    }

    func requestHealthAccess() async {
        do {
            healthAuthorized = try await health.requestAuthorization()
            statusMessage = healthAuthorized
                ? "Health connected. Publish when you’re ready."
                : "Health access was not granted."
            if healthAuthorized {
                await refreshFromHealth()
            }
        } catch {
            statusMessage = "Could not reach Health: \(error.localizedDescription)"
        }
    }

    func refreshFromHealth() async {
        do {
            let samples = try await health.loadTodaySamples(cueStyle: preferences.cueStyle)
            snapshot = SnapshotBuilder.build(from: samples)
            statusMessage = "Snapshot ready · \(snapshot.readinessBand.displayName) \(snapshot.readinessScore)"
        } catch {
            statusMessage = "Refresh failed: \(error.localizedDescription)"
        }
    }

    func publishToTV() async {
        guard preferences.publishEnabled else {
            statusMessage = "Publishing is turned off in preferences."
            return
        }
        do {
            try await store.save(snapshot)
            statusMessage = "Published to iCloud · Apple TV can pull \(snapshot.dayKey)"
        } catch {
            statusMessage = "Publish failed: \(error.localizedDescription)"
        }
    }
}

struct CompanionRootView: View {
    @EnvironmentObject private var model: CompanionModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    permissionCard
                    previewCard
                    actions
                }
                .padding(24)
            }
            .background(Color(red: 0.07, green: 0.09, blue: 0.12).ignoresSafeArea())
            .navigationTitle("Morning Board")
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("iPhone companion")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Collect from Health. Publish a small snapshot for Apple TV.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text(model.statusMessage)
                .font(.footnote)
                .foregroundStyle(.orange.opacity(0.9))
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                model.healthAuthorized ? "Health access on" : "Health access needed",
                systemImage: model.healthAuthorized ? "checkmark.heart.fill" : "heart"
            )
            .foregroundStyle(.white)
            Text("Sleep, HRV, resting heart rate, steps, workouts. Summaries only are synced — not raw samples.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Toggle("Publish board to Apple TV", isOn: $model.preferences.publishEnabled)
                .tint(.orange)
        }
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(model.snapshot.readinessScore)")
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .foregroundStyle(.white)
                VStack(alignment: .leading) {
                    Text(model.snapshot.readinessBand.displayName.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(.orange)
                    Text("Readiness")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text(model.snapshot.insight)
                .foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 18) {
                metric("Sleep", value: sleepLabel)
                metric("HRV", value: hrvLabel)
                metric("Steps", value: stepsLabel)
            }
        }
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button("Connect Apple Health") {
                Task { await model.requestHealthAccess() }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Refresh snapshot") {
                Task { await model.refreshFromHealth() }
            }
            .buttonStyle(SecondaryButtonStyle())

            Button("Publish to Apple TV") {
                Task { await model.publishToTV() }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sleepLabel: String {
        guard let sleep = model.snapshot.sleepHours else { return "—" }
        return String(format: "%.1fh", sleep)
    }

    private var hrvLabel: String {
        guard let hrv = model.snapshot.hrvNightMs else { return "—" }
        return "\(Int(hrv.rounded())) ms"
    }

    private var stepsLabel: String {
        guard let steps = model.snapshot.stepsYesterday else { return "—" }
        return steps.formatted()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.orange.opacity(configuration.isPressed ? 0.7 : 0.95), in: Capsule())
            .foregroundStyle(.black)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(configuration.isPressed ? 0.08 : 0.12), in: Capsule())
            .foregroundStyle(.white)
    }
}

