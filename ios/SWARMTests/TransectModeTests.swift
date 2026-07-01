import XCTest
@testable import SWARM

final class TransectModeTests: XCTestCase {
    func testCoffeeBreakCapsDurationAtEightMinutes() {
        let mission = SurveyMission.random(deployMode: .sm5, transectMode: .coffeeBreak, seed: 99)
        XCTAssertLessThanOrEqual(mission.transectDurationSec, 480)
        XCTAssertLessThan(mission.targetDetections, 18)
    }

    func testFieldDayPreservesFullTargets() {
        let coffee = SurveyMission.random(deployMode: .sm5bat, transectMode: .coffeeBreak, seed: 7)
        let field = SurveyMission.random(deployMode: .sm5bat, transectMode: .fieldDay, seed: 7)
        XCTAssertEqual(field.title, coffee.title)
        XCTAssertGreaterThan(field.targetDetections, coffee.targetDetections)
        XCTAssertGreaterThanOrEqual(field.transectDurationSec, coffee.transectDurationSec)
    }

    func testTransectModePersistsInGameSettings() {
        let suite = "swarm-transect-test-\(UUID().uuidString)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        GameSettings.configure(defaults: ud)
        defer { GameSettings.configure() }

        GameSettings.transectMode = .coffeeBreak
        XCTAssertEqual(GameSettings.transectMode, .coffeeBreak)

        let model = GameModel()
        model.setTransectMode(.coffeeBreak)
        XCTAssertEqual(model.transectMode, .coffeeBreak)
    }

    func testDeploymentContextIsDeterministicFromSeed() {
        let a = DeploymentContext.fresh(deployMode: .sm5, habitat: .wetland, transectMode: .fieldDay, seed: 4242)
        let b = DeploymentContext.fresh(deployMode: .sm5, habitat: .wetland, transectMode: .fieldDay, seed: 4242)
        XCTAssertEqual(a, b)
        XCTAssertTrue(a.deploymentId.hasPrefix("DEP-"))
        XCTAssertEqual(a.siteLabel, HabitatSite.wetland.title)
        XCTAssertEqual(a.recorderProfile, DeployMode.sm5.title)
    }
}