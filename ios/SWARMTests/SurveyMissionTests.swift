import XCTest
@testable import SWARM

final class SurveyMissionTests: XCTestCase {
    private func voucher(
        id: String, speciesId: String, commonName: String, scientificName: String,
        confidence: CGFloat, timeSec: Int, vetStatus: VetStatus = .autoAccepted
    ) -> DetectionVoucher {
        DetectionVoucher(
            id: id, speciesId: speciesId, commonName: commonName, scientificName: scientificName,
            confidence: confidence, timeSec: timeSec, vetStatus: vetStatus,
            deploymentId: "DEP-TEST", siteLabel: "Canopy Transect",
            recorderProfile: "Song Meter SM5",
            clipFilename: VoucherClipNaming.filename(speciesId: speciesId, sequence: 1, deploymentId: "DEP-TEST")
        )
    }
    func testRandomMissionIsDeterministicWithSeed() {
        let a = SurveyMission.random(deployMode: .sm5, seed: 42)
        let b = SurveyMission.random(deployMode: .sm5, seed: 42)
        XCTAssertEqual(a, b)
    }

    func testSM5BATMissionsDifferFromSM5() {
        let sm5 = SurveyMission.random(deployMode: .sm5, seed: 7)
        let bat = SurveyMission.random(deployMode: .sm5bat, seed: 7)
        XCTAssertNotEqual(sm5.title, bat.title)
    }

    func testSurveyScoreEngineMissionPass() {
        let mission = SurveyMission(
            id: "t", title: "Test", hypothesis: "H",
            targetDetections: 5, targetRichness: 2, minMeanConfidence: 0.6, transectDurationSec: 480
        )
        let vouchers = [
            voucher(id: "v1", speciesId: "wood_thrush", commonName: "Wood Thrush",
                    scientificName: "Hylocichla mustelina", confidence: 0.72, timeSec: 60),
            voucher(id: "v2", speciesId: "ovenbird", commonName: "Ovenbird",
                    scientificName: "Seiurus aurocapilla", confidence: 0.68, timeSec: 90),
            voucher(id: "v3", speciesId: "wood_thrush", commonName: "Wood Thrush",
                    scientificName: "Hylocichla mustelina", confidence: 0.70, timeSec: 120),
            voucher(id: "v4", speciesId: "bullfrog", commonName: "American Bullfrog",
                    scientificName: "Lithobates catesbeianus", confidence: 0.75, timeSec: 150),
            voucher(id: "v5", speciesId: "barred_owl", commonName: "Barred Owl",
                    scientificName: "Strix varia", confidence: 0.71, timeSec: 180),
        ]
        let report = SurveyScoreEngine.compute(mission: mission, timeSec: 200, vouchers: vouchers, aborted: false)
        XCTAssertTrue(report.missionPassed)
        XCTAssertGreaterThan(report.surveyScore, 0)
        XCTAssertEqual(report.richness, 4)
        XCTAssertEqual(report.detections, 5)
    }

    func testSurveyScoreEngineAbortPenalty() {
        let mission = SurveyMission.random(deployMode: .sm5, seed: 1)
        let vouchers = [
            voucher(id: "v1", speciesId: "wood_thrush", commonName: "Wood Thrush",
                    scientificName: "Hylocichla mustelina", confidence: 0.8, timeSec: 10),
        ]
        let ok = SurveyScoreEngine.compute(mission: mission, timeSec: 60, vouchers: vouchers, aborted: false)
        let aborted = SurveyScoreEngine.compute(mission: mission, timeSec: 60, vouchers: vouchers, aborted: true)
        XCTAssertNotNil(aborted.abortReason)
        XCTAssertLessThan(aborted.surveyScore, ok.surveyScore)
        XCTAssertFalse(aborted.missionPassed)
    }

    func testMimicConfidenceRequiresListenBurst() {
        XCTAssertLessThan(SurveyScoreEngine.confidence(for: 3, listenBurstRecently: false), 0.5)
        XCTAssertGreaterThan(SurveyScoreEngine.confidence(for: 3, listenBurstRecently: true), 0.7)
    }

    func testTraineeModeRelaxesPassThreshold() {
        let mission = SurveyMission(
            id: "t", title: "Trainee", hypothesis: "H",
            targetDetections: 10, targetRichness: 3, minMeanConfidence: 0.70, transectDurationSec: 480
        )
        let vouchers = (0..<7).map { i in
            voucher(
                id: "v\(i)", speciesId: "sp\(i % 3)", commonName: "Sp \(i)", scientificName: "S. \(i)",
                confidence: 0.63, timeSec: 30 + i * 10
            )
        }
        let strict = SurveyScoreEngine.compute(mission: mission, timeSec: 200, vouchers: vouchers, aborted: false, traineeMode: false)
        let trainee = SurveyScoreEngine.compute(mission: mission, timeSec: 200, vouchers: vouchers, aborted: false, traineeMode: true)
        XCTAssertFalse(strict.missionPassed)
        XCTAssertTrue(trainee.missionPassed)
    }
}