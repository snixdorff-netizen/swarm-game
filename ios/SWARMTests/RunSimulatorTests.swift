import XCTest
@testable import SWARM

final class RunSimulatorTests: XCTestCase {
    // MARK: - Legacy scalar approx (BalanceEngine math only)

    func testLegacyMortalRunsDieWithVariedOutcomes() {
        let runs = RunSimulator.batchSimulate(count: 12, baseSeed: 9001, profile: .baseline, mode: .mortal())
        XCTAssertTrue(runs.contains(where: \.died))
        XCTAssertGreaterThan(RunSimulator.survivalVariance(runs), 0)
    }

    func testZeroOutgoingDPSDiesEarly() {
        var crippled = BuildState()
        crippled.boltDmg = 0
        crippled.boltInterval = 99
        XCTAssertEqual(BalanceEngine.outgoingKillRate(enemyCount: 40, runTime: 60, build: crippled), 0, accuracy: 0.001)
        let incoming = BalanceEngine.incomingDamagePerSecond(
            enemyCount: 50, runTime: 60, kitingEfficiency: 0.5, bossPresent: false
        )
        var hp: CGFloat = 100
        var seconds = 0
        while hp > 0 && seconds < 120 {
            hp -= incoming
            seconds += 1
        }
        XCTAssertLessThan(seconds, 30)
    }

    func testIncomingDamageScalesWithHorde() {
        let few = BalanceEngine.incomingDamagePerSecond(enemyCount: 5, runTime: 40, kitingEfficiency: 0.34, bossPresent: false)
        let many = BalanceEngine.incomingDamagePerSecond(enemyCount: 60, runTime: 40, kitingEfficiency: 0.34, bossPresent: false)
        XCTAssertGreaterThan(many, few)
        let none = BalanceEngine.incomingDamagePerSecond(enemyCount: 60, runTime: 40, kitingEfficiency: 0, bossPresent: true)
        XCTAssertEqual(none, 0)
    }

    func testBuildStateDPSIncreasesWithUpgrades() {
        var state = BuildState()
        let base = state.estimatedDPS(enemyCount: 20)
        state.apply(upgradeId: "bolt_dmg")
        state.apply(upgradeId: "bolt_rate")
        XCTAssertGreaterThan(state.estimatedDPS(enemyCount: 20), base)
        XCTAssertGreaterThan(
            BalanceEngine.outgoingKillRate(enemyCount: 30, runTime: 45, build: state),
            BalanceEngine.outgoingKillRate(enemyCount: 30, runTime: 45, build: BuildState())
        )
    }

    // MARK: - Headless batch (shipped GameScene)

    @MainActor
    func testHeadlessBatchMedianSurvivalAtLeastThirtySeconds() {
        let runs = HeadlessRunDriver.batch(count: 6, baseSeed: 9001, profile: .baseline, mode: .mortal)
            .map(\.asRunMetrics)
        let median = RunSimulator.medianSurvival(runs)
        XCTAssertGreaterThanOrEqual(median, 30)
        XCTAssertTrue(runs.allSatisfy { $0.survivalSec > 0 })
        XCTAssertTrue(runs.contains(where: { $0.kills > 0 }))
    }

    @MainActor
    func testHeadlessBuildProfilesDivergeOnRealLoop() {
        let bolt = HeadlessRunDriver.batch(count: 4, baseSeed: 200, profile: .baseline, maxSeconds: 45, mode: .mortal).map(\.asRunMetrics)
        let leech = HeadlessRunDriver.batch(count: 4, baseSeed: 200, profile: .leechTank, maxSeconds: 45, mode: .mortal).map(\.asRunMetrics)
        let nova = HeadlessRunDriver.batch(count: 4, baseSeed: 200, profile: .novaRush, maxSeconds: 45, mode: .mortal).map(\.asRunMetrics)
        XCTAssertNotEqual(RunSimulator.medianKills(bolt), RunSimulator.medianKills(leech))
        XCTAssertNotEqual(RunSimulator.medianKills(bolt), RunSimulator.medianKills(nova))
    }

    @MainActor
    func testMetaLeechOutlastsBaselineOnHeadlessLoop() {
        let suite = "swarm-headless-meta-test-\(ProcessInfo.processInfo.processIdentifier)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        let meta = MetaStore(defaults: ud)
        meta.awardRun(kills: 600, timeSec: 500)
        for up in MetaCatalog.all where meta.canBuy(up) { _ = meta.buy(up) }
        let base = HeadlessRunDriver.run(profile: .baseline, seed: 8080, maxSeconds: 70, meta: meta, mode: .mortal).asRunMetrics
        let leech = HeadlessRunDriver.run(profile: .leechTank, seed: 8081, maxSeconds: 70, meta: meta, mode: .mortal).asRunMetrics
        XCTAssertGreaterThanOrEqual(leech.survivalSec, base.survivalSec)
        XCTAssertGreaterThan(leech.kills, 0)
    }

    @MainActor
    func testImmortalQAReachesBossOnHeadlessLoop() {
        let immortal = HeadlessRunDriver.run(profile: .baseline, seed: 55, maxSeconds: 120, mode: .immortalQA)
        let mortal = HeadlessRunDriver.run(profile: .baseline, seed: 55, maxSeconds: 120, mode: .mortal)
        XCTAssertFalse(immortal.died)
        XCTAssertEqual(immortal.survivalSec, HeadlessRunDriver.defaultMaxSeconds)
        XCTAssertTrue(immortal.bossSpawned)
        XCTAssertEqual(immortal.mode, "immortalQA")
        XCTAssertTrue(immortal.playerInvulnerable)
        XCTAssertFalse(mortal.playerInvulnerable)
        XCTAssertGreaterThan(immortal.kills, 0)
        XCTAssertGreaterThan(mortal.kills, 0)
    }

    @MainActor
    func testExportRepresentativeBatchToScratch() throws {
        let url = try SimulationMetricsExporter.exportRepresentativeBatch()
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let decoded = try JSONDecoder().decode([RunMetrics].self, from: Data(contentsOf: url))
        XCTAssertGreaterThanOrEqual(decoded.count, 12)
        let profiles = Set(decoded.map(\.profile))
        XCTAssertTrue(profiles.contains(BuildProfile.baseline.rawValue))
        XCTAssertTrue(profiles.contains(BuildProfile.novaRush.rawValue))
        XCTAssertTrue(profiles.contains(BuildProfile.leechTank.rawValue))
        XCTAssertTrue(profiles.contains(BuildProfile.chainArc.rawValue))
        XCTAssertTrue(profiles.contains(BuildProfile.metaBoosted.rawValue))
        XCTAssertTrue(decoded.contains(where: { $0.bossReached }))
        XCTAssertTrue(decoded.contains(where: { $0.metaLevels > 0 }))
        XCTAssertTrue(decoded.contains(where: { $0.mode == "immortalQA" && $0.survivalSec >= 60 }))
        XCTAssertTrue(decoded.contains(where: { $0.mode == "mortal" && $0.survivalSec >= 30 && $0.kills > 0 }))
        let mortal = decoded.filter { $0.mode == "mortal" }
        XCTAssertGreaterThan(Set(mortal.map(\.kills)).count, 1, "Mortal headless runs must spread kill counts")
        let leechMeta = decoded.filter { $0.seed == 8081 && $0.mode == "mortal" }
        let baseMeta = decoded.filter { $0.seed == 8080 && $0.mode == "mortal" }
        XCTAssertEqual(leechMeta.count, 1)
        XCTAssertEqual(baseMeta.count, 1)
        XCTAssertGreaterThanOrEqual(leechMeta[0].survivalSec, baseMeta[0].survivalSec)
    }
}