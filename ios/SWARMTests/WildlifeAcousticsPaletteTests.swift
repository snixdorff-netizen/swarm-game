import XCTest
@testable import SWARM

final class WildlifeAcousticsPaletteTests: XCTestCase {
    func testBrandHexTokensMatchWebsiteCSS() {
        XCTAssertEqual(WildlifeAcousticsPalette.navy, "#152931")
        XCTAssertEqual(WildlifeAcousticsPalette.blue, "#2183fc")
        XCTAssertEqual(WildlifeAcousticsPalette.olive, "#546235")
        XCTAssertEqual(WildlifeAcousticsPalette.gold, "#bc955c")
        XCTAssertEqual(WildlifeAcousticsPalette.cream, "#ecd2ab")
        XCTAssertEqual(WildlifeAcousticsPalette.red, "#e1251b")
    }
}