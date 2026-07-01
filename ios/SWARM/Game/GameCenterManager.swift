// Game Center authentication + best-time leaderboard submit.
// Gracefully no-ops on simulator or when Game Center is unavailable.

import GameKit
import UIKit

@MainActor
final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    static let leaderboardID = "ai.swarm.game.besttime"

    @Published private(set) var statusLine: String = ""
    @Published private(set) var syncStatusLine: String = ""
    @Published private(set) var isAvailable: Bool = false

    private var pendingBestTime: Int?
    private var authHandlerInstalled = false
    private weak var pendingAuthVC: UIViewController?
    private var authRetryTask: Task<Void, Never>?

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
        if authHandlerInstalled {
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
                self.authRetryTask?.cancel()
                if player.isAuthenticated {
                    self.isAvailable = true
                    self.statusLine = "Signed in to Game Center"
                    self.trySubmitPending()
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
        pendingBestTime = GameCenterLogic.mergedPending(existing: pendingBestTime, new: seconds)
        if GameCenterLogic.shouldQueueSubmit(isAvailable: isAvailable, isAuthenticated: GKLocalPlayer.local.isAuthenticated) {
            return
        }
        trySubmitPending()
        #endif
    }

    func retryPresentAuthIfNeeded() {
        guard let vc = pendingAuthVC else { return }
        presentAuth(vc)
    }

    func retryPendingSubmit() {
        #if !targetEnvironment(simulator)
        trySubmitPending()
        #endif
    }

    private func trySubmitPending() {
        guard let pending = pendingBestTime,
              isAvailable,
              GKLocalPlayer.local.isAuthenticated else { return }
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
                    self.pendingBestTime = GameCenterLogic.mergedPending(existing: self.pendingBestTime, new: seconds)
                    self.syncStatusLine = "Leaderboard sync pending"
                } else {
                    self.pendingBestTime = GameCenterLogic.pendingAfterSuccessfulSubmit(
                        submitted: seconds,
                        pending: self.pendingBestTime
                    )
                    if self.pendingBestTime == nil {
                        self.syncStatusLine = ""
                    } else {
                        self.trySubmitPending()
                    }
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
            scheduleAuthRetry()
            return
        }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        guard top.presentedViewController !== vc else { return }
        top.present(vc, animated: true)
    }

    private func scheduleAuthRetry() {
        authRetryTask?.cancel()
        authRetryTask = Task { @MainActor in
            for delay in [0.4, 1.0, 2.0] {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled, self.pendingAuthVC != nil else { return }
                self.retryPresentAuthIfNeeded()
            }
        }
    }
}