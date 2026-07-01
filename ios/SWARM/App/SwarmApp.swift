// SWARM — app entry. Hosts the SpriteKit GameScene and overlays the SwiftUI
// menu / level-up / game-over UI driven by GameModel.

import SwiftUI
import SpriteKit

@main
struct SwarmApp: App {
    @StateObject private var host = GameHost()

    var body: some Scene {
        WindowGroup {
            GameRootView(host: host)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

final class GameHost: ObservableObject {
    let model = GameModel()
    let scene = GameScene()
    init() {
        scene.scaleMode = .resizeFill
        scene.size = CGSize(width: 430, height: 932)
        scene.model = model
        let s = scene
        model.onStart = { s.startRun() }
        model.onChoose = { id in s.applyUpgrade(id) }
        model.onRestart = { s.restartToMenu() }
    }
}

struct GameRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var host: GameHost
    @ObservedObject private var model: GameModel
    init(host: GameHost) { self.host = host; _model = ObservedObject(wrappedValue: host.model) }

    var body: some View {
        ZStack {
            SpriteView(scene: host.scene, preferredFramesPerSecond: 60)
                .ignoresSafeArea()

            switch model.phase {
            case .menu: MenuOverlay(model: model)
            case .levelUp: LevelUpOverlay(model: model)
            case .dead: GameOverOverlay(model: model)
            case .meta: MetaOverlay(model: model)
            case .settings: SettingsOverlay(model: model)
            case .playing: EmptyView()
            }
        }
        .background(SwarmTheme.bg)
        .preferredColorScheme(.dark)
        .onAppear {
            GameCenterManager.shared.authenticate()
            GameCenterManager.shared.retryPresentAuthIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            GameCenterManager.shared.retryPresentAuthIfNeeded()
            GameCenterManager.shared.retryPendingSubmit()
        }
    }
}
