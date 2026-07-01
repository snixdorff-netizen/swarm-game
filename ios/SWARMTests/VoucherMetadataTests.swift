import XCTest
@testable import SWARM

final class VoucherMetadataTests: XCTestCase {
    private func sampleVoucher(sequence: Int = 1) -> DetectionVoucher {
        DetectionVoucher(
            id: "v1",
            speciesId: "wood_thrush",
            commonName: "Wood Thrush",
            scientificName: "Hylocichla mustelina",
            confidence: 0.82,
            timeSec: 120,
            validated: true,
            deploymentId: "DEP-00001039",
            siteLabel: "Canopy Transect",
            recorderProfile: "Song Meter SM5",
            clipFilename: VoucherClipNaming.filename(
                speciesId: "wood_thrush", sequence: sequence, deploymentId: "DEP-00001039"
            )
        )
    }

    func testClipFilenameFormat() {
        let name = VoucherClipNaming.filename(
            speciesId: "ovenbird", sequence: 7, deploymentId: "DEP-ABCDEF01"
        )
        XCTAssertEqual(name, "SWARM_ovenbird_ABCDEF01_007.wav")
    }

    func testTextReportIncludesDeploymentAndClipMetadata() {
        let report = SurveyRunReport(
            missionId: "m1",
            missionTitle: "Dawn Chorus Baseline",
            deploymentId: "DEP-00001039",
            siteLabel: "Canopy Transect",
            recorderProfile: "Song Meter SM5",
            transectMode: .coffeeBreak,
            timeSec: 480,
            detections: 1,
            richness: 1,
            meanConfidence: 0.82,
            falsePositives: 0,
            surveyScore: 500,
            missionPassed: true,
            abortReason: nil,
            vouchers: [sampleVoucher()]
        )
        let text = SurveyReportExporter.textReport(report, deployMode: .sm5)
        XCTAssertTrue(text.contains("DEP-00001039"))
        XCTAssertTrue(text.contains("Coffee Break"))
        XCTAssertTrue(text.contains("SWARM_wood_thrush"))
        XCTAssertTrue(text.contains(".wav"))
    }

    func testCSVRowsIncludeVoucherMetadataColumns() {
        let report = SurveyRunReport(
            missionId: "m1",
            missionTitle: "Test",
            deploymentId: "DEP-00001039",
            siteLabel: "Wetland Edge",
            recorderProfile: "Song Meter SM5BAT",
            transectMode: .fieldDay,
            timeSec: 600,
            detections: 1,
            richness: 1,
            meanConfidence: 0.7,
            falsePositives: 0,
            surveyScore: 400,
            missionPassed: false,
            abortReason: nil,
            vouchers: [sampleVoucher()]
        )
        let csv = SurveyReportExporter.csvRows(report, deployMode: .sm5bat)
        XCTAssertTrue(csv.contains("deployment_id,site_label,recorder_profile,clip_filename"))
        XCTAssertTrue(csv.contains("Wetland Edge"))
        XCTAssertTrue(csv.contains("SWARM_wood_thrush"))
    }
}