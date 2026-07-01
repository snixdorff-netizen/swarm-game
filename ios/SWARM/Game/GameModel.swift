// Bridge between the SpriteKit gameplay (GameScene) and the SwiftUI shell.
// SwiftUI renders menu / level-up / game-over overlays; the scene drives everything else.
// Mutated only on the main thread (scene update + SwiftUI actions both run on main).

import Combine
import Foundation

struct UpgradeCard: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String   // SF Symbol
    let levelText: String
}

final class GameModel: ObservableObject {
    enum Phase { case menu, playing, levelUp, dead, meta, settings }

    @Published var phase: Phase = .menu
    @Published var choices: [UpgradeCard] = []

    // HUD (updated live by the scene)
    @Published var hp: Int = 100
    @Published var maxHp: Int = 100
    @Published var level: Int = 1
    @Published var xp: CGFloat = 0
    @Published var xpToNext: CGFloat = 5
    @Published var timeSec: Int = 0
    @Published var kills: Int = 0

    // End-of-run snapshot
    @Published var coresEarned: Int = 0

    let meta = MetaStore()
    private var cancellables = Set<AnyCancellable>()

    var bestTime: Int { meta.bestTime }
    var cores: Int { meta.cores }

    init() {
        meta.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // Wired by the scene
    var onStart: () -> Void = {}
    var onChoose: (String) -> Void = { _ in }
    var onRestart: () -> Void = {}

    func start() { onStart() }
    func pick(_ id: String) { onChoose(id) }
    func restart() { onRestart() }
    func openMeta() { phase = .meta }
    func closeMeta() { phase = .menu }
    func openSettings() { guard phase == .menu else { return }; phase = .settings }
    func closeSettings() { phase = .menu }
    func buyMeta(_ id: String) {
        guard let up = MetaCatalog.all.first(where: { $0.id == id }) else { return }
        meta.buy(up)
    }
}