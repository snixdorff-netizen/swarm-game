import XCTest
@testable import SWARM

final class EngagementCopyTests: XCTestCase {
    func testNewBestHeadline() {
        let lines = EngagementCopy.deathLines(timeSec: 95, kills: 40, level: 8, isNewBest: true)
        XCTAssertEqual(lines.headline, "NEW SURVEY RECORD")
        XCTAssertTrue(lines.subline.contains("1:35"))
    }

    func testShortRunMotivatesGrants() {
        let lines = EngagementCopy.deathLines(timeSec: 35, kills: 10, level: 3, isNewBest: false)
        XCTAssertEqual(lines.headline, "BASELINE ESTABLISHED")
        XCTAssertTrue(lines.subline.lowercased().contains("grant"))
    }

    func testFirstRunStepsCoverLoop() {
        XCTAssertEqual(EngagementCopy.firstRunSteps.count, 5)
        XCTAssertTrue(EngagementCopy.firstRunSteps.joined().lowercased().contains("song meter"))
        XCTAssertTrue(EngagementCopy.firstRunSteps.joined().lowercased().contains("grant"))
    }
}