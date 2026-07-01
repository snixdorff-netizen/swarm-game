import XCTest
@testable import SWARM

final class SurveyFieldProfileTests: XCTestCase {
    func testSM5UsesAcousticTransectProfile() {
        let profile = SurveyFieldProfile.from(deployMode: .sm5)
        XCTAssertEqual(profile, .acousticTransect)
        XCTAssertTrue(profile.joystickEnabled)
        XCTAssertFalse(profile.usesPassivePasses)
        XCTAssertGreaterThan(profile.pursuitFactor, 0)
    }

    func testSM5BATUsesPassiveUltrasonicProfile() {
        let profile = SurveyFieldProfile.from(deployMode: .sm5bat)
        XCTAssertEqual(profile, .passiveUltrasonic)
        XCTAssertFalse(profile.joystickEnabled)
        XCTAssertTrue(profile.usesPassivePasses)
        XCTAssertEqual(profile.pursuitFactor, 0)
        XCTAssertNotNil(profile.emergenceBanner)
    }

    func testPassiveBatHasLowerSpawnPressureThanAcoustic() {
        let acousticBatch = BalanceEngine.spawnBatchSize(runTime: 60, deployMode: .sm5)
        let batBatch = BalanceEngine.spawnBatchSize(runTime: 60, deployMode: .sm5bat)
        XCTAssertGreaterThan(acousticBatch, batBatch)

        let acousticInterval = BalanceEngine.spawnInterval(runTime: 40, deployMode: .sm5)
        let batInterval = BalanceEngine.spawnInterval(runTime: 40, deployMode: .sm5bat)
        XCTAssertGreaterThan(batInterval, acousticInterval)
    }

    func testMaxActiveSignaturesLowerInPassiveMode() {
        XCTAssertGreaterThan(
            BalanceEngine.maxActiveSignatures(deployMode: .sm5),
            BalanceEngine.maxActiveSignatures(deployMode: .sm5bat)
        )
    }

    func testPassiveBatGoalHintsDifferFromAcoustic() {
        let acoustic = BalanceEngine.nextGoalHint(timeSec: 20, kills: 2, deployMode: .sm5)
        let bat = BalanceEngine.nextGoalHint(timeSec: 20, kills: 2, deployMode: .sm5bat)
        XCTAssertNotEqual(acoustic, bat)
        XCTAssertTrue(bat.lowercased().contains("passive") || bat.lowercased().contains("emergence"))
    }

    func testPassDriftAngleIsPerpendicular() {
        let ang: CGFloat = 0
        let drift = SurveyFieldProfile.passDriftAngle(spawnAngle: ang)
        XCTAssertEqual(drift, .pi / 2, accuracy: 0.001)
    }
}