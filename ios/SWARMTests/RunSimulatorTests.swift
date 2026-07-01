import XCTest
@testable import SWARM

final class RunSimulatorTests: XCTestCase {
    func testBatchMedianSurvivalAtLeastThirtySeconds() {
        let runs = RunSimulator.batchSimulate(count: 8, baseSeed: 9001, profile: .baseline)
        let median = RunSimulator.medianSurvival(runs)
        XCTAssertGreaterThanOrEqual(median, 30, "Autopilot baseline median survival should be ≥30s")
        XCTAssertTrue(runs.allSatisfy { $0.survivalSec > 0 })
    }

    func testBuildProfilesDiverge() {
        let bolt = RunSimulator.batchSimulate(count: 3, baseSeed: 100, profile: .baseline)
        let nova = RunSimulator.batchSimulate(count: 3, baseSeed: 100, profile: .novaRush)
        let leech = RunSimulator.batchSimulate(count: 3, baseSeed: 100, profile: .leechTank)
        XCTAssertTrue(RunSimulator.runsDiverge(bolt, nova), "Nova rush should differ from bolt baseline")
        XCTAssertTrue(RunSimulator.runsDiverge(bolt, leech), "Leech tank should differ from bolt baseline")
    }

    func testMetaBoostedOutperformsBaselineKills() {
        let base = RunSimulator.simulate(profile: .baseline, seed: 77)
        let boosted = RunSimulator.simulate(profile: .metaBoosted, seed: 77)
        XCTAssertGreaterThan(boosted.kills, base.kills)
    }

    func testExportMetricsToScratch() throws {
        let runs = RunSimulator.batchSimulate(count: 5, baseSeed: 42)
        let url = try SimulationMetricsExporter.export(runs)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([RunMetrics].self, from: data)
        XCTAssertEqual(decoded.count, 5)
        XCTAssertEqual(decoded.first?.profile, BuildProfile.baseline.rawValue)
    }

    func testBuildStateDPSIncreasesWithUpgrades() {
        var state = BuildState()
        let base = state.estimatedDPS(enemyCount: 20)
        state.apply(upgradeId: "bolt_dmg")
        state.apply(upgradeId: "bolt_rate")
        XCTAssertGreaterThan(state.estimatedDPS(enemyCount: 20), base)
    }
}