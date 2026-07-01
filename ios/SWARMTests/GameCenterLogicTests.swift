import XCTest
@testable import SWARM

final class GameCenterLogicTests: XCTestCase {

    func testMergedPendingTakesMax() {
        XCTAssertEqual(GameCenterLogic.mergedPending(existing: nil, new: 42), 42)
        XCTAssertEqual(GameCenterLogic.mergedPending(existing: 30, new: 42), 42)
        XCTAssertEqual(GameCenterLogic.mergedPending(existing: 50, new: 42), 50)
    }

    func testShouldQueueSubmit() {
        XCTAssertTrue(GameCenterLogic.shouldQueueSubmit(isAvailable: false, isAuthenticated: true))
        XCTAssertTrue(GameCenterLogic.shouldQueueSubmit(isAvailable: true, isAuthenticated: false))
        XCTAssertFalse(GameCenterLogic.shouldQueueSubmit(isAvailable: true, isAuthenticated: true))
    }

    func testShouldSubmitLeaderboard() {
        XCTAssertTrue(GameCenterLogic.shouldSubmitLeaderboard(newBest: true, seconds: 90))
        XCTAssertFalse(GameCenterLogic.shouldSubmitLeaderboard(newBest: false, seconds: 90))
        XCTAssertFalse(GameCenterLogic.shouldSubmitLeaderboard(newBest: true, seconds: 0))
    }

    func testShouldSubmitScoreLeaderboard() {
        XCTAssertTrue(GameCenterLogic.shouldSubmitScoreLeaderboard(newBest: true, score: 1200))
        XCTAssertFalse(GameCenterLogic.shouldSubmitScoreLeaderboard(newBest: false, score: 1200))
        XCTAssertFalse(GameCenterLogic.shouldSubmitScoreLeaderboard(newBest: true, score: 0))
    }

    func testPendingAfterSuccessfulSubmit() {
        XCTAssertNil(GameCenterLogic.pendingAfterSuccessfulSubmit(submitted: 90, pending: 90))
        XCTAssertEqual(GameCenterLogic.pendingAfterSuccessfulSubmit(submitted: 90, pending: 120), 120)
        XCTAssertNil(GameCenterLogic.pendingAfterSuccessfulSubmit(submitted: 90, pending: nil))
    }

    #if targetEnvironment(simulator)
    @MainActor
    func testSimulatorGameCenterUnavailable() {
        let mgr = GameCenterManager.shared
        XCTAssertFalse(mgr.isAvailable)
        XCTAssertEqual(mgr.statusLine, "Game Center unavailable (simulator)")
        mgr.submitBestTime(60) // no-op on simulator
    }
    #endif
}