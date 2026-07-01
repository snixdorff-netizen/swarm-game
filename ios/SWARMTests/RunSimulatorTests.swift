import XCTest
@testable import SWARM

final class RunSimulatorTests: XCTestCase {
    func testMortalRunsDieWithVariedOutcomes() {
        let runs = RunSimulator.batchSimulate(count: 12, baseSeed: 9001, profile: .baseline, mode: .mortal())
        XCTAssertTrue(runs.contains(where: \.died), "Mortal sim must produce death outcomes")
        XCTAssertTrue(runs.contains(where: { $0.survivalSec >= 30 }), "Some runs should pass 30s milestone")
        XCTAssertGreaterThan(RunSimulator.survivalVariance(runs), 0, "Survival must vary across seeds")
        XCTAssertTrue(runs.contains(where: { $0.survivalSec < RunSimulator.defaultMaxSeconds }),
                      "Mortal runs must not all hit the time cap")
    }

    func testBatchMedianSurvivalAtLeastThirtySeconds() {
        let runs = RunSimulator.batchSimulate(count: 12, baseSeed: 9001, profile: .baseline, mode: .mortal())
        let median = RunSimulator.medianSurvival(runs)
        XCTAssertGreaterThanOrEqual(median, 30, "Mortal baseline median survival should be ≥30s")
        XCTAssertTrue(runs.allSatisfy { $0.survivalSec > 0 })
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
        XCTAssertLessThan(seconds, 30, "No outgoing DPS + horde pressure should kill within 30s")
    }

    func testImmortalQAMatchesAutostartNoDamage() {
        let mortal = RunSimulator.simulate(profile: .baseline, seed: 55, mode: .mortal())
        let immortal = RunSimulator.simulate(profile: .baseline, seed: 55, mode: .immortalQA)
        XCTAssertTrue(mortal.died || mortal.survivalSec < immortal.survivalSec)
        XCTAssertFalse(immortal.died)
        XCTAssertEqual(immortal.survivalSec, RunSimulator.defaultMaxSeconds)
        XCTAssertTrue(immortal.bossReached)
        XCTAssertEqual(immortal.mode, "immortalQA")
        XCTAssertGreaterThan(immortal.kills, mortal.kills)
    }

    func testBuildProfilesDivergeOnSurvival() {
        let bolt = RunSimulator.batchSimulate(count: 6, baseSeed: 200, profile: .baseline, mode: .mortal())
        let leech = RunSimulator.batchSimulate(count: 6, baseSeed: 200, profile: .leechTank, mode: .mortal())
        XCTAssertTrue(RunSimulator.runsDivergeOnSurvival(bolt, leech),
                      "Leech tank should survive longer than bolt baseline")
        XCTAssertGreaterThan(RunSimulator.medianSurvival(leech), RunSimulator.medianSurvival(bolt))
    }

    func testIncomingDamageScalesWithHorde() {
        let few = BalanceEngine.incomingDamagePerSecond(enemyCount: 5, runTime: 40, kitingEfficiency: 0.34, bossPresent: false)
        let many = BalanceEngine.incomingDamagePerSecond(enemyCount: 60, runTime: 40, kitingEfficiency: 0.34, bossPresent: false)
        XCTAssertGreaterThan(many, few)
        let none = BalanceEngine.incomingDamagePerSecond(enemyCount: 60, runTime: 40, kitingEfficiency: 0, bossPresent: true)
        XCTAssertEqual(none, 0)
    }

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
        XCTAssertTrue(decoded.contains(where: { $0.mode == "mortal" && $0.died }))
        let mortal = decoded.filter { $0.mode == "mortal" }
        XCTAssertGreaterThan(Set(mortal.map(\.survivalSec)).count, 1, "Mortal profiles must spread survival")
        let leechMedian = RunSimulator.medianSurvival(decoded.filter { $0.profile == BuildProfile.leechTank.rawValue && $0.mode == "mortal" })
        let baseMedian = RunSimulator.medianSurvival(decoded.filter { $0.profile == BuildProfile.baseline.rawValue && $0.mode == "mortal" })
        XCTAssertGreaterThan(leechMedian, baseMedian)
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
}