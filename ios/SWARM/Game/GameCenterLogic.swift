// Pure helpers for Game Center queue/submit decisions (unit-testable).

import Foundation

enum GameCenterLogic {
    static func mergedPending(existing: Int?, new seconds: Int) -> Int {
        max(existing ?? 0, seconds)
    }

    static func shouldQueueSubmit(isAvailable: Bool, isAuthenticated: Bool) -> Bool {
        !isAvailable || !isAuthenticated
    }

    static func shouldSubmitLeaderboard(newBest: Bool, seconds: Int) -> Bool {
        newBest && seconds > 0
    }

    /// Returns nil when the in-flight score matches pending (submit succeeded).
    static func pendingAfterSuccessfulSubmit(submitted: Int, pending: Int?) -> Int? {
        guard pending == submitted else { return pending }
        return nil
    }
}