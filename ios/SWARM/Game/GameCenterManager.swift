// Game Center authentication + best-time leaderboard submit.
// Gracefully no-ops on simulator or when Game Center is unavailable.

import GameKit
import UIKit

@MainActor
final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    static let leaderboardID = "ai.swarm.game.besttime"

    @Published private(set) var statusLine: String = ""
    @Published private(set) var isAvailable: Bool = false

    private var pendingBestTime: Int?
    private var authHandlerInstalled = false
    private weak var pendingAuthVC: UIViewController?

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
        guard !authHandlerInstalled else {
            retryPresentAuthIfNeeded()
            return
        }
        authHandlerInstalled = true
        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let vc = viewController {
                    self.pendingAuthVC = vc
                    self.statusLine = "Sign in to Game Center"
                    self.presentAuth(vc)
                    return
                }
                self.pendingAuthVC = nil
                if player.isAuthenticated {
                    self.isAvailable = true
                    self.statusLine = "Signed in to Game Center"
                    self.flushPendingSubmit()
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
        }
        #endif
    }

    func submitBestTime(_ seconds: Int) {
        guard seconds > 0 else { return }
        #if targetEnvironment(simulator)
        return
        #else
        if isAvailable, GKLocalPlayer.local.isAuthenticated {
            submitNow(seconds)
        } else {
            pendingBestTime = max(pendingBestTime ?? 0, seconds)
        }
        #endif
    }

    func retryPresentAuthIfNeeded() {
        guard let vc = pendingAuthVC else { return }
        presentAuth(vc)
    }

    private func flushPendingSubmit() {
        guard let pending = pendingBestTime else { return }
        pendingBestTime = nil
        submitNow(pending)
    }

    private func submitNow(_ seconds: Int) {
        GKLeaderboard.submitScore(
            seconds,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.leaderboardID]
        ) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    NSLog("Leaderboard submit failed: %@", error.localizedDescription)
                    self.statusLine = "Leaderboard sync failed"
                }
            }
        }
    }

    private func presentAuth(_ vc: UIViewController) {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            statusLine = "Sign in to Game Center"
            return
        }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        guard top.presentedViewController !== vc else { return }
        top.present(vc, animated: true)
    }
}