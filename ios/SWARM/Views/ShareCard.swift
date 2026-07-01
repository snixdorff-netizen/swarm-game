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
    static func image(for payload: DeathSharePayload, scale: CGFloat = 2.0) -> UIImage? {
        let view = DeathShareCardView(payload: payload)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.uiImage
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.backgroundColor = .clear
        context.coordinator.host = host
        DispatchQueue.main.async {
            let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
            if let popover = activity.popoverPresentationController {
                popover.sourceView = host.view
                popover.sourceRect = CGRect(x: host.view.bounds.midX, y: host.view.bounds.midY, width: 1, height: 1)
                popover.permittedArrowDirections = .any
            }
            host.present(activity, animated: true)
        }
        return host
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator {
        weak var host: UIViewController?
    }
}