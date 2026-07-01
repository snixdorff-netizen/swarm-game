import SpriteKit
import XCTest
@testable import SWARM

@MainActor
final class GameSceneCombatTests: XCTestCase {

    private func makeScene() -> (GameScene, GameModel, SKView) {
        unsetenv("SWARM_AUTOSTART")
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 430, height: 932))
        let model = GameModel()
        let scene = GameScene(size: CGSize(width: 430, height: 932))
        scene.model = model
        scene.testing_attach(to: view)
        scene.testingAutopilotMovement = true
        scene.startRun()
        return (scene, model, view)
    }

    // MARK: - Branch smoke (contact / shot paths)

    func testMortalContactDamageViaUpdateEnemies() {
        let (scene, model, _) = makeScene()
        scene.testingPlayerInvulnerable = false
        let hp0 = scene.testingHp
        scene.testing_placeEnemyOnPlayer(kind: .basic, runTime: 15)
        for i in 1...120 {
            scene.testing_step(at: TimeInterval(i) / 60.0)
            if model.phase == .dead { break }
        }
        XCTAssertLessThan(scene.testingHp, hp0, "Contact path must reduce hp when player is vulnerable")
    }

    func testMortalEnemyShotDamageViaUpdateEnemyShots() {
        let (scene, model, _) = makeScene()
        scene.testingPlayerInvulnerable = false
        let hp0 = scene.testingHp
        scene.testing_placeEnemyShotOnPlayer(damage: 40)
        for i in 1...30 {
            scene.testing_step(at: TimeInterval(i) / 60.0)
            if model.phase == .dead { break }
        }
        XCTAssertLessThan(scene.testingHp, hp0, "Enemy shot path must damage vulnerable player")
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
        XCTAssertEqual(scene.testingHp, hp0, "playerInvulnerable must skip hp-= in updateEnemies/shots")
    }

    func testAutopilotMovementWithoutInvulnerabilityIsMortal() {
        let (scene, _, _) = makeScene()
        scene.testingPlayerInvulnerable = false
        XCTAssertTrue(scene.testingAutopilotMovement)
        scene.testing_fastForward(seconds: 20, profile: .baseline)
        let summary = scene.testing_captureSummary(profile: .baseline, mode: .mortal)
        XCTAssertFalse(summary.playerInvulnerable)
        XCTAssertTrue(summary.autopilotMovement)
    }

    // MARK: - Headless integration (honest survival proof)

    func testHeadlessMortalRunUsesRealCombatLoop() throws {
        let summary = HeadlessRunDriver.run(profile: .baseline, seed: 4242, maxSeconds: 90, mode: .mortal)
        XCTAssertFalse(summary.playerInvulnerable)
        XCTAssertTrue(summary.autopilotMovement)
        XCTAssertTrue(summary.kills > 0, "Real weapons must score kills")
        XCTAssertGreaterThan(summary.level, 1, "XP gems and level-up must fire")
        XCTAssertTrue(summary.died || summary.bossSpawned, "90s mortal run must die or reach boss")
        XCTAssertGreaterThanOrEqual(summary.survivalSec, 30, "Mortal baseline must pass 30s on shipped loop")

        let url = try SimulationMetricsExporter.export([summary.asRunMetrics])
        let decoded = try JSONDecoder().decode([RunMetrics].self, from: Data(contentsOf: url))
        XCTAssertTrue(decoded.contains(where: { $0.mode == "mortal" && $0.survivalSec >= 30 }))
    }

    func testHeadlessMortalEvidenceExport() throws {
        let mortal = HeadlessRunDriver.run(profile: .baseline, seed: 4242, maxSeconds: 90, mode: .mortal)
        let immortal = HeadlessRunDriver.run(profile: .novaRush, seed: 8888, maxSeconds: 120, mode: .immortalQA)

        XCTAssertFalse(mortal.playerInvulnerable)
        XCTAssertTrue(immortal.playerInvulnerable)
        XCTAssertGreaterThan(mortal.kills, 0)
        XCTAssertGreaterThan(mortal.level, 1)
        XCTAssertTrue(mortal.survivalSec >= 30 || mortal.bossSpawned)

        let url = try GameSceneRunEvidenceExporter.export([mortal, immortal])
        let decoded = try JSONDecoder().decode([GameSceneRunSummary].self, from: Data(contentsOf: url))
        XCTAssertTrue(decoded.contains(where: { $0.mode == "mortal" && !$0.playerInvulnerable && $0.kills > 0 }))
        XCTAssertTrue(decoded.contains(where: { $0.mode == "immortalQA" && $0.playerInvulnerable && $0.bossSpawned }))
    }

    func testBossSpawnsAtNinetySecondsOnRealScene() {
        let summary = HeadlessRunDriver.run(profile: .baseline, seed: 1001, maxSeconds: 92, mode: .immortalQA)
        XCTAssertTrue(summary.bossSpawned)
        XCTAssertGreaterThanOrEqual(summary.survivalSec, 90)
    }

    func testBossTeaseAtSeventyFiveSeconds() {
        let (scene, model, _) = makeScene()
        scene.testingPlayerInvulnerable = true
        scene.testing_fastForward(seconds: 76)
        XCTAssertEqual(model.runBanner, "BOSS IN 15 SECONDS")
    }

    func testMilestone30OnRealScene() {
        let summary = HeadlessRunDriver.run(profile: .baseline, seed: 2002, maxSeconds: 31, mode: .immortalQA)
        XCTAssertTrue(summary.milestone30)
        XCTAssertGreaterThanOrEqual(summary.survivalSec, 30)
    }
}