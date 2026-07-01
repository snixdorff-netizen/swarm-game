import XCTest
@testable import SWARM

final class CitizenScienceExporterTests: XCTestCase {
    func testCatalogCSVIncludesPipelineHeader() {
        let suite = "swarm-csv-\(ProcessInfo.processInfo.processIdentifier)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        let catalog = SpeciesCatalogStore(defaults: ud)
        catalog.record(ProjectSpeciesCatalog.with(id: "wood_thrush")!, deployMode: .sm5)
        let csv = CitizenScienceExporter.catalogCSV(catalog: catalog, habitat: .canopy)
        XCTAssertTrue(csv.contains("pipeline_version"))
        XCTAssertTrue(csv.contains("wood_thrush"))
        XCTAssertTrue(csv.contains("present"))
    }

    func testMetadataJSONIncludesHabitat() {
        let catalog = SpeciesCatalogStore(defaults: UserDefaults(suiteName: "meta-\(ProcessInfo.processInfo.processIdentifier)")!)
        let json = CitizenScienceExporter.metadataJSON(habitat: .wetland, deployMode: .sm5bat, catalog: catalog)
        XCTAssertTrue(json.contains("wetland"))
        XCTAssertTrue(json.contains("sm5bat"))
    }
}