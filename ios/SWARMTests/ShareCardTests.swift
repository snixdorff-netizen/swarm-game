import XCTest
@testable import SWARM

final class ShareCardTests: XCTestCase {

    @MainActor
    func testShareCardRendererProducesImage() {
        let payload = DeathSharePayload(timeSec: 90, kills: 42, level: 7, bestTime: 120)
        let image = ShareCardRenderer.image(for: payload)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
    }

    func testTimeStrFormatting() {
        XCTAssertEqual(timeStr(0), "0:00")
        XCTAssertEqual(timeStr(59), "0:59")
        XCTAssertEqual(timeStr(90), "1:30")
        XCTAssertEqual(timeStr(3600), "60:00")
    }
}