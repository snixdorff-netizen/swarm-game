import XCTest
@testable import SWARM

final class EngagementCopyTests: XCTestCase {
    func testNewBestHeadline() {
        let lines = EngagementCopy.deathLines(timeSec: 95, kills: 40, level: 8, isNewBest: true)
        XCTAssertEqual(lines.headline, "NEW BEST!")
        XCTAssertTrue(lines.subline.contains("1:35"))
    }

    func testShortRunMotivatesCores() {
        let lines = EngagementCopy.deathLines(timeSec: 35, kills: 10, level: 3, isNewBest: false)
        XCTAssertEqual(lines.headline, "GETTING WARMED UP")
        XCTAssertTrue(lines.subline.contains("cores"))
    }

    func testFirstRunStepsCoverLoop() {
        XCTAssertEqual(EngagementCopy.firstRunSteps.count, 5)
        XCTAssertTrue(EngagementCopy.firstRunSteps.joined().lowercased().contains("cores"))
    }
}