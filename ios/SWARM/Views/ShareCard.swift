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

    func makeCoordinator() -> Coordinator { Coordinator(items: items) }

    func makeUIViewController(context: Context) -> ShareHostViewController {
        let host = ShareHostViewController()
        host.coordinator = context.coordinator
        return host
    }

    func updateUIViewController(_ uiViewController: ShareHostViewController, context: Context) {}

    final class Coordinator {
        let items: [Any]
        var presented = false
        init(items: [Any]) { self.items = items }
    }
}

final class ShareHostViewController: UIViewController {
    weak var coordinator: ActivityShareSheet.Coordinator?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let coordinator, !coordinator.presented else { return }
        coordinator.presented = true
        view.layoutIfNeeded()
        let activity = UIActivityViewController(activityItems: coordinator.items, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = .any
        }
        present(activity, animated: true)
    }
}