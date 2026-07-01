// Game Center authentication + best-time leaderboard submit.
// Gracefully no-ops on simulator or when Game Center is unavailable.

import GameKit
import UIKit

final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    static let leaderboardID = "ai.swarm.game.besttime"

    @Published private(set) var statusLine: String = ""
    @Published private(set) var isAvailable: Bool = false

    private override init() {
        super.init()
        #if targetEnvironment(simulator)
        statusLine = "Game Center unavailable (simulator)"
        isAvailable = false
        #else
        statusLine = "Connecting to Game Center…"
        #endif
    }

    func authenticate() {
        #if targetEnvironment(simulator)
        return
        #else
        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if let vc = viewController {
                self.presentAuth(vc)
                return
            }
            if player.isAuthenticated {
                self.isAvailable = true
                self.statusLine = "Signed in to Game Center"
            } else {
                self.isAvailable = false
                if let error {
                    self.statusLine = "Game Center unavailable"
                    NSLog("Game Center auth error: %@", error.localizedDescription)
                } else {
                    self.statusLine = "Game Center unavailable"
                }
            }
        }
        #endif
    }

    func submitBestTime(_ seconds: Int) {
        guard seconds > 0, isAvailable, GKLocalPlayer.local.isAuthenticated else { return }
        GKLeaderboard.submitScore(
            seconds,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.leaderboardID]
        ) { error in
            if let error {
                NSLog("Leaderboard submit failed: %@", error.localizedDescription)
            }
        }
    }

    private func presentAuth(_ vc: UIViewController) {
        DispatchQueue.main.async {
            guard let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: { $0.isKeyWindow })?
                .rootViewController else { return }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            top.present(vc, animated: true)
        }
    }
}