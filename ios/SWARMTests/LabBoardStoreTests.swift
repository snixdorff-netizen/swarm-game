import XCTest
@testable import SWARM

final class LabBoardStoreTests: XCTestCase {
    func testNoteLocalDetectionPrependsYou() {
        let suite = "swarm-lab-\(ProcessInfo.processInfo.processIdentifier)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        let board = LabBoardStore(defaults: ud)
        let thrush = ProjectSpeciesCatalog.with(id: "wood_thrush")!
        board.noteLocalDetection(species: thrush, habitat: .canopy, deployMode: .sm5)
        XCTAssertEqual(board.events.first?.mateName, "You")
        XCTAssertEqual(board.events.first?.speciesCommon, "Wood Thrush")
    }
}