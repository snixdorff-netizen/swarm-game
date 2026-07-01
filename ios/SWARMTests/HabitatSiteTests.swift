import XCTest
@testable import SWARM

final class HabitatSiteTests: XCTestCase {
    func testWetlandPoolIncludesBullfrog() {
        XCTAssertTrue(HabitatSite.wetland.speciesPool.contains("bullfrog"))
    }

    func testPickSpeciesRespectsArchetype() {
        let frog = HabitatSite.pickSpecies(archetype: 2, roll: 0.1, habitat: .wetland)
        XCTAssertEqual(frog.archetype, 2)
    }

    func testMissionIncludesHabitatSubtitle() {
        let mission = SurveyMission.random(deployMode: .sm5, habitat: .coastal, seed: 99)
        XCTAssertTrue(mission.hypothesis.contains(HabitatSite.coastal.subtitle))
    }
}