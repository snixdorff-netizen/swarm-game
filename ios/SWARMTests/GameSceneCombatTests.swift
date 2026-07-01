import SpriteKit
import XCTest
@testable import SWARM

@MainActor
final class GameSceneCombatTests: XCTestCase {

    private func makeScene(autostart: Bool = false) -> (GameScene, GameModel, SKView) {
        unsetenv("SWARM_AUTOSTART")
        if autostart { setenv("SWARM_AUTOSTART", "1", 1) }
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 430, height: 932))
        let model = GameModel()
        let scene = GameScene(size: CGSize(width: 430, height: 932))
        scene.model = model
        scene.testing_attach(to: view)
        scene.startRun()
        return (scene, model, view)
    }

    func testMortalContactDamageViaUpdateEnemies() {
        let (scene, model, _) = makeScene()
        scene.qaAutopilotImmune = false
        let hp0 = scene.testingHp
        scene.testing_placeEnemyOnPlayer(kind: .basic, runTime: 15)
        for i in 1...120 {
            scene.testing_step(at: TimeInterval(i) / 60.0)
            if model.phase == .dead { break }
        }
        XCTAssertLessThan(scene.testingHp, hp0, "Contact path in updateEnemies must reduce hp when !autoDrive")
    }

    func testMortalEnemyShotDamageViaUpdateEnemyShots() {
        let (scene, model, _) = makeScene()
        scene.qaAutopilotImmune = false
        let hp0 = scene.testingHp
        scene.testing_placeEnemyShotOnPlayer(damage: 40)
        for i in 1...30 {
            scene.testing_step(at: TimeInterval(i) / 60.0)
            if model.phase == .dead { break }
        }
        XCTAssertLessThan(scene.testingHp, hp0, "Enemy shot path must damage mortal player")
    }

    func testMortalRunEndsInDiePhase() {
        let (scene, model, _) = makeScene()
        scene.qaAutopilotImmune = false
        scene.testing_placeEnemyOnPlayer(kind: .tank, runTime: 40)
        for i in 1...600 {
            scene.testing_step(at: TimeInterval(i) / 60.0)
            if model.phase == .dead { break }
        }
        XCTAssertEqual(model.phase, .dead, "hp<=0 must invoke die() and set phase .dead")
        XCTAssertGreaterThan(scene.testingRunTime, 0)
    }

    func testAutopilotImmuneTakesNoDamage() {
        let (scene, _, _) = makeScene()
        scene.qaAutopilotImmune = true
        let hp0 = scene.testingHp
        scene.testing_placeEnemyOnPlayer(kind: .basic, runTime: 20)
        scene.testing_placeEnemyShotOnPlayer(damage: 30)
        for i in 1...180 {
            scene.testing_step(at: TimeInterval(i) / 60.0)
        }
        XCTAssertEqual(scene.testingHp, hp0, "autoDrive must skip hp-= in updateEnemies/shots")
    }

    func testBossSpawnsAtNinetySecondsOnRealScene() {
        let (scene, model, _) = makeScene()
        scene.qaAutopilotImmune = true
        scene.testing_fastForward(seconds: 92)
        XCTAssertTrue(scene.testingBossSpawned, "maybeBoss/spawnBoss must fire at ~90s")
        XCTAssertEqual(model.phase, .playing)
    }

    func testBossTeaseAtSeventyFiveSeconds() {
        let (scene, model, _) = makeScene()
        scene.qaAutopilotImmune = true
        scene.testing_fastForward(seconds: 76)
        XCTAssertEqual(model.runBanner, "BOSS IN 15 SECONDS")
    }

    func testMilestone30OnRealScene() {
        let (scene, model, _) = makeScene()
        scene.qaAutopilotImmune = true
        scene.testing_fastForward(seconds: 31)
        let summary = scene.testing_captureSummary()
        XCTAssertTrue(summary.milestone30)
        XCTAssertGreaterThanOrEqual(summary.survivalSec, 30)
        XCTAssertEqual(model.phase, .playing)
    }

    func testMilestone60AndExportMortalEvidence() throws {
        let (scene, model, _) = makeScene()
        scene.qaAutopilotImmune = true
        scene.testing_fastForward(seconds: 62)
        let immortalSummary = scene.testing_captureSummary()
        XCTAssertTrue(immortalSummary.milestone60)

        let (mortalScene, mortalModel, _) = makeScene()
        mortalScene.qaAutopilotImmune = false
        mortalScene.testing_suppressOffense()
        mortalScene.testing_placeEnemyOnPlayer(kind: .tank, runTime: 50)
        for i in 1...800 {
            mortalScene.testing_step(at: TimeInterval(i) / 60.0)
            if mortalModel.phase == .dead { break }
        }
        let mortalSummary = mortalScene.testing_captureSummary()
        XCTAssertTrue(mortalSummary.died)
        XCTAssertFalse(mortalSummary.qaAutopilotImmune)

        let url = try GameSceneRunEvidenceExporter.export([immortalSummary, mortalSummary])
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let decoded = try JSONDecoder().decode([GameSceneRunSummary].self, from: Data(contentsOf: url))
        XCTAssertTrue(decoded.contains(where: { $0.died && !$0.qaAutopilotImmune }))
        XCTAssertTrue(decoded.contains(where: { $0.milestone60 && $0.qaAutopilotImmune }))
    }
}