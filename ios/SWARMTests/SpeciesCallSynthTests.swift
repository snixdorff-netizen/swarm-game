import XCTest
@testable import SWARM

final class SpeciesCallSynthTests: XCTestCase {
    func testAcousticSpeciesUseAcousticBand() {
        for species in [SurveySpecies.passerine, .swift, .resonant, .mimic] {
            let profile = SpeciesCallProfiles.profile(for: species)
            XCTAssertEqual(profile.band, .acoustic)
            XCTAssertGreaterThan(profile.nominalKHzMax, profile.nominalKHzMin)
            XCTAssertGreaterThan(profile.audibleMaxHz, profile.audibleMinHz)
        }
    }

    func testEndangeredUsesUltrasonicBand() {
        let profile = SpeciesCallProfiles.profile(for: .endangered)
        XCTAssertEqual(profile.band, .ultrasonic)
        XCTAssertGreaterThanOrEqual(profile.nominalKHzMin, 20)
        XCTAssertGreaterThanOrEqual(profile.nominalKHzMax, 80)
        XCTAssertGreaterThan(profile.audibleMinHz, 8_000, "Ultrasonic down-convert sits above acoustic band")
    }

    func testHearRadiusBeyondDetection() {
        let detect = BalanceEngine.detectionRadius(pickupRadius: 78, orbitLevel: 1, chainLevel: 1)
        XCTAssertGreaterThan(BalanceEngine.hearRadius(detectionRadius: detect), detect)
    }

    func testCallIntervalsArePositive() {
        for kind in [0, 1, 2, 3, 9] {
            let profile = SpeciesCallProfiles.profile(for: SurveySpecies.from(enemyKind: kind))
            XCTAssertGreaterThan(profile.callInterval, 0.5)
        }
    }
}