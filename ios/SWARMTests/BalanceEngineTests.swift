import XCTest
@testable import SWARM

final class BalanceEngineTests: XCTestCase {
    func testSpawnIntervalDecreasesWithTime() {
        let early = BalanceEngine.spawnInterval(runTime: 5)
        let late = BalanceEngine.spawnInterval(runTime: 80)
        XCTAssertGreaterThan(early, late)
        XCTAssertGreaterThanOrEqual(late, 0.12)
    }

    func testSpawnBatchGrowsWithTime() {
        XCTAssertEqual(BalanceEngine.spawnBatchSize(runTime: 0), 2)
        XCTAssertGreaterThan(BalanceEngine.spawnBatchSize(runTime: 54), 2)
    }

    func testEnemyKindTiersUnlock() {
        XCTAssertEqual(BalanceEngine.enemyKind(runTime: 10, roll: 0.5).rawValue, EnemyKind.basic.rawValue)
        XCTAssertEqual(BalanceEngine.enemyKind(runTime: 30, roll: 0.3).rawValue, EnemyKind.fast.rawValue)
        XCTAssertEqual(BalanceEngine.enemyKind(runTime: 50, roll: 0.2).rawValue, EnemyKind.shooter.rawValue)
        XCTAssertEqual(BalanceEngine.enemyKind(runTime: 70, roll: 0.1).rawValue, EnemyKind.tank.rawValue)
    }

    func testEnemyStatsScaleWithTime() {
        let early = BalanceEngine.enemyStats(kind: .basic, runTime: 5)
        let late = BalanceEngine.enemyStats(kind: .basic, runTime: 90)
        XCTAssertGreaterThan(late.hp, early.hp)
        XCTAssertGreaterThan(late.damage, early.damage)
    }

    func testXpThresholdEscalates() {
        let next = BalanceEngine.xpThresholdAfterLevel(current: 6)
        XCTAssertGreaterThan(next, 6)
    }

    func testMilestoneBanners() {
        XCTAssertEqual(BalanceEngine.milestoneBanner(for: 30), "30 SECONDS — KEEP GOING")
        XCTAssertNil(BalanceEngine.milestoneBanner(for: 45))
    }

    func testBossSpawnAtNinety() {
        XCTAssertEqual(Int(BalanceEngine.bossSpawnSeconds), 90)
    }
}