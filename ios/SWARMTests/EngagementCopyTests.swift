import XCTest
@testable import SWARM

final class EngagementCopyTests: XCTestCase {
    private func sampleReport(
        timeSec: Int = 95,
        detections: Int = 40,
        richness: Int = 8,
        meanConfidence: CGFloat = 0.75,
        surveyScore: Int = 1200,
        missionPassed: Bool = true,
        abortReason: String? = nil
    ) -> SurveyRunReport {
        SurveyRunReport(
            missionId: "m1",
            missionTitle: "Dawn Chorus Baseline",
            deploymentId: "DEP-TEST",
            siteLabel: "Canopy Transect",
            recorderProfile: "Song Meter SM5",
            transectMode: .fieldDay,
            timeSec: timeSec,
            detections: detections,
            richness: richness,
            meanConfidence: meanConfidence,
            falsePositives: 0,
            surveyScore: surveyScore,
            missionPassed: missionPassed,
            abortReason: abortReason,
            vouchers: []
        )
    }

    func testNewBestScoreHeadline() {
        let lines = EngagementCopy.deathLines(report: sampleReport(), isNewBestScore: true)
        XCTAssertEqual(lines.headline, "NEW BEST SURVEY SCORE")
        XCTAssertTrue(lines.subline.contains("1200"))
    }

    func testMissionPassedHeadline() {
        let lines = EngagementCopy.deathLines(report: sampleReport(), isNewBestScore: false)
        XCTAssertEqual(lines.headline, SurveyProtocolCopy.missionPassed)
        XCTAssertTrue(lines.subline.contains("Dawn Chorus"))
    }

    func testAbortHeadline() {
        let report = sampleReport(missionPassed: false, abortReason: "Noise budget exceeded — deployment aborted")
        let lines = EngagementCopy.deathLines(report: report, isNewBestScore: false)
        XCTAssertEqual(lines.headline, SurveyProtocolCopy.deploymentAborted)
        XCTAssertTrue(lines.subline.contains("Noise budget"))
    }

    func testShortRunEndsDeployment() {
        let lines = EngagementCopy.deathLines(report: sampleReport(timeSec: 35, missionPassed: false), isNewBestScore: false)
        XCTAssertEqual(lines.headline, "DEPLOYMENT ENDED")
    }

    func testFirstRunStepsCoverLoop() {
        XCTAssertEqual(EngagementCopy.firstRunSteps.count, 5)
        XCTAssertTrue(EngagementCopy.firstRunSteps.joined().lowercased().contains("song meter"))
        XCTAssertTrue(EngagementCopy.firstRunSteps.joined().lowercased().contains("grant"))
    }
}