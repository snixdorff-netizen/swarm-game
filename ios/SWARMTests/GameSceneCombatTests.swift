import SpriteKit
import XCTest
@testable import SWARM

@MainActor
final class GameSceneCombatTests: XCTestCase {

    private func makeScene() -> (GameScene, GameModel, SKView) {
        unsetenv("SWARM_AUTOSTART")
        unsetenv("SWARM_MORTAL_AUTOSTART")
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 430, height: 932))
        let model = GameModel()
        let scene = GameScene(size: CGSize(width: 430, height: 932))
        scene.model = model
        scene.testing_attach(to: view)
        scene.testingAutopilotMovement = true
        scene.startRun()
        return (scene, model, view)
    }

    // MARK: - Branch smoke (artificial placement — contact/shot paths only)

    func testMortalContactDamageViaUpdateEnemies() {
        let (scene, model, _) = makeScene()
        scene.testingPlayerInvulnerable = false
        let hp0 = scene.testingHp
        scene.testing_placeEnemyOnPlayer(kind: .basic, runTime: 15)
        for i in 1...120 {
            scene.testing_step(at: TimeInterval(i) / 60.0)
            if model.phase == .dead { break }
        }
        XCTAssertLessThan(scene.testingHp, hp0)
    }

    func testInvulnerableAutopilotTakesNoDamage() {
        let (scene, _, _) = makeScene()
        scene.testingPlayerInvulnerable = true
        let hp0 = scene.testingHp
        scene.testing_placeEnemyOnPlayer(kind: .basic, runTime: 20)
        scene.testing_placeEnemyShotOnPlayer(damage: 30)
        for i in 1...180 {
            scene.testing_step(at: TimeInterval(i) / 60.0)
        }
        XCTAssertEqual(scene.testingHp, hp0)
    }

    // MARK: - Headless integration (honest long mortal runs)

    func testHeadlessMortalBatchProducesDeathsAndVariance() throws {
        let summaries = HeadlessRunDriver.batch(count: 10, baseSeed: 6000, profile: .baseline, maxSeconds: 120, mode: .mortal)
        let metrics = summaries.map(\.asRunMetrics)
        XCTAssertTrue(summaries.allSatisfy { $0.casualAutopilot && !$0.playerInvulnerable })
        XCTAssertTrue(metrics.contains(where: \.died), "Casual mortal batch must include natural deaths")
        XCTAssertGreaterThan(RunSimulator.survivalVariance(metrics), 0)
        XCTAssertGreaterThanOrEqual(RunSimulator.medianSurvival(metrics), 30)
        XCTAssertTrue(metrics.contains(where: { $0.bossReached || $0.died }))
    }

    func testHeadlessMortalRunUsesRealCombatLoop() throws {
        let summary = HeadlessRunDriver.run(profile: .baseline, seed: 6001, maxSeconds: 120, mode: .mortal)
        XCTAssertTrue(summary.casualAutopilot)
        XCTAssertFalse(summary.playerInvulnerable)
        XCTAssertTrue(summary.kills > 0)
        XCTAssertGreaterThan(summary.level, 1)
        XCTAssertTrue(summary.died || summary.bossSpawned)
        XCTAssertGreaterThanOrEqual(summary.survivalSec, 30)

        let url = try SimulationMetricsExporter.export([summary.asRunMetrics], filename: "headless-spot-check.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testHeadlessMortalEvidenceExport() throws {
        let earlyDeath = HeadlessRunDriver.probeMortalDeath(profile: .baseline, baseSeed: 7000)
        let suite = "swarm-evidence-meta-\(ProcessInfo.processInfo.processIdentifier)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        let meta = MetaStore(defaults: ud)
        meta.awardRun(kills: 600, timeSec: 500)
        for up in MetaCatalog.all where meta.canBuy(up) { _ = meta.buy(up) }
        let bossDeath = HeadlessRunDriver.probeMortalBoss(profile: .leechTank, baseSeed: 8081, meta: meta)
        let immortal = HeadlessRunDriver.run(profile: .novaRush, seed: 8888, maxSeconds: 120, mode: .immortalQA)

        XCTAssertTrue(earlyDeath.died)
        XCTAssertTrue(earlyDeath.casualAutopilot)
        XCTAssertFalse(earlyDeath.playerInvulnerable)
        XCTAssertTrue(bossDeath.bossSpawned)
        XCTAssertTrue(bossDeath.died)
        XCTAssertGreaterThanOrEqual(bossDeath.survivalSec, 90)

        let url = try GameSceneRunEvidenceExporter.export([earlyDeath, bossDeath, immortal])
        let decoded = try JSONDecoder().decode([GameSceneRunSummary].self, from: Data(contentsOf: url))
        XCTAssertTrue(decoded.contains(where: { $0.mode == "mortal" && $0.died && $0.casualAutopilot && !$0.bossSpawned }))
        XCTAssertTrue(decoded.contains(where: { $0.mode == "mortal" && $0.bossSpawned && $0.died }))
        XCTAssertTrue(decoded.contains(where: { $0.mode == "immortalQA" && $0.playerInvulnerable }))
    }

    func testBossSpawnsAtNinetySecondsMortalCasual() {
        let summary = HeadlessRunDriver.run(profile: .leechTank, seed: 6010, maxSeconds: 95, mode: .mortal)
        XCTAssertTrue(summary.casualAutopilot)
        XCTAssertTrue(summary.bossSpawned || summary.died)
    }

    func testBossTeaseAtSeventyFiveSeconds() {
        let (scene, model, _) = makeScene()
        scene.testingPlayerInvulnerable = true
        scene.testing_fastForward(seconds: 76)
        XCTAssertEqual(model.runBanner, "BOSS IN 15 SECONDS")
    }

    func testMilestone30MortalCasual() {
        let summary = HeadlessRunDriver.run(profile: .baseline, seed: 6015, maxSeconds: 35, mode: .mortal)
        XCTAssertTrue(summary.milestone30 || summary.died)
        XCTAssertTrue(summary.casualAutopilot)
    }
}