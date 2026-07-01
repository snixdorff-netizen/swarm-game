import XCTest
@testable import SWARM

final class ShareCardTests: XCTestCase {

    @MainActor
    func testShareCardRendererProducesImage() {
        let scale: CGFloat = 2.0
        let payload = DeathSharePayload(
            surveyScore: 840, detections: 42, richness: 7,
            missionTitle: "Dawn Chorus Baseline", missionPassed: true,
            timeSec: 90, bestSurveyScore: 1200
        )
        let image = ShareCardRenderer.image(for: payload, scale: scale)
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width ?? 0, 400, accuracy: 1)
        XCTAssertEqual(image?.size.height ?? 0, 520, accuracy: 1)
        XCTAssertEqual(image?.scale ?? 0, scale, accuracy: 0.1)
    }

    func testTimeStrFormatting() {
        XCTAssertEqual(timeStr(0), "0:00")
        XCTAssertEqual(timeStr(59), "0:59")
        XCTAssertEqual(timeStr(90), "1:30")
        XCTAssertEqual(timeStr(3600), "60:00")
    }
}