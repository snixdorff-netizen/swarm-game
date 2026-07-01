import XCTest
@testable import SWARM

final class SurveyReportExporterTests: XCTestCase {
    private func sampleReport() -> SurveyRunReport {
        SurveyRunReport(
            missionId: "m1",
            missionTitle: "Dawn Chorus Baseline",
            deploymentId: "DEP-00001039",
            siteLabel: "Canopy Transect",
            recorderProfile: "Song Meter SM5",
            transectMode: .fieldDay,
            timeSec: 540,
            detections: 3,
            richness: 2,
            meanConfidence: 0.71,
            falsePositives: 1,
            surveyScore: 880,
            missionPassed: false,
            abortReason: nil,
            vouchers: [
                DetectionVoucher(
                    id: "v1", speciesId: "wood_thrush", commonName: "Wood Thrush",
                    scientificName: "Hylocichla mustelina", confidence: 0.82, timeSec: 120, validated: true,
                    deploymentId: "DEP-00001039", siteLabel: "Canopy Transect",
                    recorderProfile: "Song Meter SM5",
                    clipFilename: "SWARM_wood_thrush_00001039_001.wav"
                ),
            ]
        )
    }

    func testTextReportIncludesMissionAndVouchers() {
        let text = SurveyReportExporter.textReport(sampleReport(), deployMode: .sm5)
        XCTAssertTrue(text.contains("Dawn Chorus Baseline"))
        XCTAssertTrue(text.contains("Wood Thrush"))
        XCTAssertTrue(text.contains("Survey score: 880"))
        XCTAssertTrue(text.contains("SM5"))
    }

    func testCSVRowsIncludeHeaderAndVoucherLine() {
        let csv = SurveyReportExporter.csvRows(sampleReport(), deployMode: .sm5bat)
        XCTAssertTrue(csv.contains("deployment_id,mission_id"))
        XCTAssertTrue(csv.contains("species_id,common_name"))
        XCTAssertTrue(csv.contains("wood_thrush"))
        XCTAssertTrue(csv.contains("DEP-00001039"))
        XCTAssertTrue(csv.contains("SWARM_wood_thrush"))
    }
}