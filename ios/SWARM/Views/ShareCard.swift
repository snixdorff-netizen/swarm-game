// Renders a shareable death-summary card for UIActivityViewController.

import SwiftUI

struct DeathSharePayload {
    let timeSec: Int
    let kills: Int
    let level: Int
    let bestTime: Int
}

struct DeathShareCardView: View {
    let payload: DeathSharePayload

    var body: some View {
        ZStack {
            SwarmTheme.bg
            VStack(spacing: 18) {
                Text("SWARM")
                    .font(SwarmTheme.title(44))
                    .foregroundColor(SwarmTheme.cyan)
                    .tracking(4)
                Text("I survived \(timeStr(payload.timeSec))")
                    .font(SwarmTheme.ui(26, .bold))
                    .foregroundColor(SwarmTheme.foam)
                HStack(spacing: 28) {
                    shareStat("\(payload.kills)", "kills")
                    shareStat("LV \(payload.level)", "reached")
                    shareStat(timeStr(payload.bestTime), "best")
                }
                Text("Outlast the horde.")
                    .font(SwarmTheme.ui(14))
                    .foregroundColor(SwarmTheme.foam.opacity(0.55))
            }
            .padding(36)
        }
        .frame(width: 400, height: 520)
    }

    private func shareStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SwarmTheme.ui(22, .bold))
                .foregroundColor(SwarmTheme.lime)
            Text(label)
                .font(SwarmTheme.ui(12))
                .foregroundColor(SwarmTheme.foam.opacity(0.6))
        }
    }
}

enum ShareCardRenderer {
    @MainActor
    static func image(for payload: DeathSharePayload) -> UIImage? {
        let view = DeathShareCardView(payload: payload)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}