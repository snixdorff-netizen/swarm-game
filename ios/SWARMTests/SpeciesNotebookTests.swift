import XCTest
@testable import SWARM

final class SpeciesNotebookTests: XCTestCase {
    func testNotebookTracksDeployModeCounts() {
        let suite = "swarm-notebook-\(ProcessInfo.processInfo.processIdentifier)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        let store = SpeciesCatalogStore(defaults: ud)
        let thrush = ProjectSpeciesCatalog.with(id: "wood_thrush")!
        let bat = ProjectSpeciesCatalog.with(id: "little_brown_bat")!

        store.record(thrush, deployMode: .sm5)
        store.record(bat, deployMode: .sm5bat)
        store.markDeploymentRecorded(speciesIds: [thrush.id, bat.id], deployMode: .sm5bat)

        XCTAssertEqual(store.record(for: thrush).sm5Count, 1)
        XCTAssertEqual(store.record(for: bat).sm5batCount, 1)
        XCTAssertEqual(store.record(for: thrush).deploymentCount, 1)
        XCTAssertEqual(store.record(for: bat).deploymentCount, 1)
        XCTAssertNotNil(store.record(for: thrush).firstSeen)
    }
}