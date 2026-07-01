import XCTest
@testable import SWARM

final class RunSimulatorTests: XCTestCase {
    // MARK: - BalanceEngine math (not batch evidence)

    func testIncomingDamageScalesWithHorde() {
        let few = BalanceEngine.incomingDamagePerSecond(enemyCount: 5, runTime: 40, kitingEfficiency: 0.34, bossPresent: false)
        let many = BalanceEngine.incomingDamagePerSecond(enemyCount: 60, runTime: 40, kitingEfficiency: 0.34, bossPresent: false)
        XCTAssertGreaterThan(many, few)
    }

    func testBuildStateDPSIncreasesWithUpgrades() {
        var state = BuildState()
        let base = state.estimatedDPS(enemyCount: 20)
        state.apply(upgradeId: "bolt_dmg")
        state.apply(upgradeId: "bolt_rate")
        XCTAssertGreaterThan(state.estimatedDPS(enemyCount: 20), base)
    }

    // MARK: - Headless batch (shipped GameScene — sole evidence path)

    @MainActor
    func testHeadlessBatchMedianSurvivalAtLeastThirtySeconds() {
        let runs = HeadlessRunDriver.batch(count: 8, baseSeed: 9001, profile: .baseline, maxSeconds: 120, mode: .mortal)
            .map(\.asRunMetrics)
        XCTAssertTrue(runs.contains(where: \.died))
        let median = RunSimulator.medianSurvival(runs)
        XCTAssertGreaterThanOrEqual(median, 30)
        XCTAssertGreaterThan(RunSimulator.survivalVariance(runs), 0)
    }

    @MainActor
    func testHeadlessBuildProfilesDivergeOnRealLoop() {
        let bolt = HeadlessRunDriver.batch(count: 6, baseSeed: 200, profile: .baseline, maxSeconds: 120, mode: .mortal).map(\.asRunMetrics)
        let leech = HeadlessRunDriver.batch(count: 6, baseSeed: 200, profile: .leechTank, maxSeconds: 120, mode: .mortal).map(\.asRunMetrics)
        let survivalGap = abs(RunSimulator.medianSurvival(leech) - RunSimulator.medianSurvival(bolt))
        let killGap = abs(RunSimulator.medianKills(leech) - RunSimulator.medianKills(bolt))
        XCTAssertTrue(survivalGap >= 3 || killGap >= 4, "Leech tank should diverge from baseline on survival or kills")
        XCTAssertGreaterThanOrEqual(RunSimulator.medianSurvival(leech), RunSimulator.medianSurvival(bolt) - 2)
    }

    @MainActor
    func testImmortalQAReachesBossOnHeadlessLoop() {
        let immortal = HeadlessRunDriver.run(profile: .baseline, seed: 55, maxSeconds: 120, mode: .immortalQA)
        let mortal = HeadlessRunDriver.run(profile: .baseline, seed: 55, maxSeconds: 120, mode: .mortal)
        XCTAssertFalse(immortal.died)
        XCTAssertTrue(immortal.bossSpawned)
        XCTAssertTrue(immortal.playerInvulnerable)
        XCTAssertFalse(mortal.playerInvulnerable)
        XCTAssertTrue(mortal.casualAutopilot)
    }

    @MainActor
    func testProbeMortalDeathOnShippedLoop() {
        let death = HeadlessRunDriver.probeMortalDeath(profile: .baseline, baseSeed: 6000)
        XCTAssertTrue(death.died)
        XCTAssertTrue(death.casualAutopilot)
        XCTAssertFalse(death.playerInvulnerable)
        XCTAssertGreaterThanOrEqual(death.survivalSec, 30)
    }

    @MainActor
    func testExportRepresentativeBatchToScratch() throws {
        let url = try SimulationMetricsExporter.exportRepresentativeBatch()
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let decoded = try JSONDecoder().decode([RunMetrics].self, from: Data(contentsOf: url))
        XCTAssertGreaterThanOrEqual(decoded.count, 12)
        let mortal = decoded.filter { $0.mode == "mortal" }
        XCTAssertTrue(mortal.contains(where: \.died), "Representative mortal batch must include deaths")
        XCTAssertTrue(mortal.contains(where: { $0.bossReached || $0.survivalSec >= 90 }))
        XCTAssertGreaterThan(RunSimulator.survivalVariance(mortal), 4)
        XCTAssertGreaterThanOrEqual(RunSimulator.medianSurvival(mortal), 30)
        XCTAssertGreaterThan(Set(mortal.map(\.survivalSec)).count, 2)
        let leechPlain = mortal.filter { $0.profile == BuildProfile.leechTank.rawValue && $0.metaLevels == 0 }
        let basePlain = mortal.filter { $0.profile == BuildProfile.baseline.rawValue && $0.metaLevels == 0 }
        XCTAssertGreaterThan(RunSimulator.medianSurvival(leechPlain), RunSimulator.medianSurvival(basePlain))
        XCTAssertTrue(decoded.contains(where: { $0.mode == "immortalQA" && $0.bossReached }))
    }
}