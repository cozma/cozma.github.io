import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var coordinator: RunAlertCoordinator

    var body: some View {
        Group {
            if #available(watchOS 9.0, *) {
                NavigationStack {
                    mainScroll
                        .navigationTitle("Vine Watch")
                }
            } else {
                NavigationView {
                    mainScroll
                        .navigationTitle("Vine Watch")
                }
            }
        }
    }

    private var mainScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Why Are You Running?")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                Text(coordinator.detection.lastStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(
                    coordinator.canPlayThroughSpeaker
                        ? "Speaker mode (newer watch)"
                        : "Text + image mode (older watch)",
                    systemImage: coordinator.canPlayThroughSpeaker
                        ? "speaker.wave.2.fill"
                        : "photo"
                )
                .font(.caption2)

                if let presentation = coordinator.lastPresentation {
                    Text("Last alert: \(label(for: presentation))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button("Test alert") {
                    Task { await coordinator.testAlert() }
                }
                .buttonStyle(.borderedProminent)

                Button(coordinator.detection.isMonitoring ? "Pause listening" : "Resume listening") {
                    Task {
                        if coordinator.detection.isMonitoring {
                            coordinator.detection.stop()
                        } else {
                            await coordinator.detection.start()
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }

    private func label(for presentation: AlertPresentation) -> String {
        switch presentation {
        case .speakerAndBanner: return "speaker + banner"
        case .textAndImage: return "text + image"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RunAlertCoordinator(canPlayThroughSpeaker: true))
}
