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
        XCTAssertEqual(BalanceEngine.spawnBatchSize(runTime: 20), 2)
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
        XCTAssertEqual(BalanceEngine.milestoneBanner(for: 30), "30s — BASELINE LOCKED")
        XCTAssertNil(BalanceEngine.milestoneBanner(for: 45))
    }

    func testBossTeaseAndKillStreakBanners() {
        XCTAssertEqual(BalanceEngine.bossTeaseBanner(), "RARE SPECIES IN 15s")
        XCTAssertEqual(BalanceEngine.killStreakBanner(for: 25), "25 IDs — STRONG INVENTORY")
        XCTAssertEqual(BalanceEngine.killStreakBanner(for: 50), "50 IDs — CATALOG SURGE")
        XCTAssertNil(BalanceEngine.killStreakBanner(for: 24))
    }

    func testNextGoalHintGuidesCasualPlayers() {
        XCTAssertEqual(BalanceEngine.nextGoalHint(timeSec: 10, kills: 0), "Goal: establish 0:30 baseline")
        XCTAssertEqual(BalanceEngine.nextGoalHint(timeSec: 45, kills: 5), "Goal: reach 1:00 inventory")
        XCTAssertEqual(BalanceEngine.nextGoalHint(timeSec: 80, kills: 10), "Goal: rare species at 1:30")
        XCTAssertEqual(BalanceEngine.nextGoalHint(timeSec: 95, kills: 30), "Goal: 50 confirmed IDs")
    }

    func testDetectionRadiusGrowsWithKit() {
        let base = BalanceEngine.detectionRadius(pickupRadius: 78, orbitLevel: 0, chainLevel: 0)
        let expanded = BalanceEngine.detectionRadius(pickupRadius: 114, orbitLevel: 2, chainLevel: 2)
        XCTAssertGreaterThan(expanded, base)
    }

    func testBossSpawnAtNinety() {
        XCTAssertEqual(Int(BalanceEngine.bossSpawnSeconds), 90)
    }

    func testIncomingDamageUsesShippedCooldowns() {
        let dps = BalanceEngine.incomingDamagePerSecond(enemyCount: 20, runTime: 50, kitingEfficiency: 0.38, bossPresent: false)
        let mix = BalanceEngine.expectedEnemyMix(runTime: 50)
        let hits = BalanceEngine.contactHitsPerSecond(enemyCount: 20, kitingEfficiency: 0.38)
        let expectedContact = hits * mix.damage
        XCTAssertGreaterThanOrEqual(dps, expectedContact * 0.95)
        XCTAssertLessThan(dps, expectedContact * 3, "Damage must not stack all enemies per tick")
    }

    func testLeechHealMatchesGameSceneFormula() {
        XCTAssertEqual(BalanceEngine.leechHealOnKill(leechLevel: 2, metaLeech: 1), 7)
    }
}