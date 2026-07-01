import XCTest
@testable import SWARM

final class AnalystLoopTests: XCTestCase {
    private func voucher(
        speciesId: String, vetStatus: VetStatus, confidence: CGFloat = 0.8
    ) -> DetectionVoucher {
        DetectionVoucher(
            id: "v-\(speciesId)-\(vetStatus.rawValue)",
            speciesId: speciesId,
            commonName: speciesId,
            scientificName: "S. \(speciesId)",
            confidence: confidence,
            timeSec: 60,
            vetStatus: vetStatus,
            deploymentId: "DEP-TEST",
            siteLabel: "Canopy Transect",
            recorderProfile: "Song Meter SM5",
            clipFilename: "SWARM_\(speciesId)_TEST_001.wav"
        )
    }

    override func tearDown() {
        GameSettings.conservativeClassifier = false
        super.tearDown()
    }

    func testInitialVetStatusMimicWithoutListenNeedsReview() {
        let status = AnalystLoop.initialVetStatus(kind: 3, confidence: 0.41, listenRecent: false)
        XCTAssertEqual(status, .needsReview)
    }

    func testInitialVetStatusLowConfidenceNeedsReview() {
        let status = AnalystLoop.initialVetStatus(kind: 1, confidence: 0.5, listenRecent: false)
        XCTAssertEqual(status, .needsReview)
    }

    func testConservativeClassifierRaisesReviewRate() {
        GameSettings.conservativeClassifier = true
        let status = AnalystLoop.initialVetStatus(kind: 1, confidence: 0.68, listenRecent: true)
        XCTAssertEqual(status, .needsReview)
    }

    func testPresenceRollupPresentWhenValidatedExists() {
        let vouchers = [
            voucher(speciesId: "wood_thrush", vetStatus: .autoAccepted),
            voucher(speciesId: "wood_thrush", vetStatus: .needsReview),
            voucher(speciesId: "ovenbird", vetStatus: .needsReview),
        ]
        let rollup = PresenceRollupEngine.rollup(vouchers: vouchers)
        XCTAssertEqual(rollup.first(where: { $0.speciesId == "wood_thrush" })?.status, .present)
        XCTAssertEqual(rollup.first(where: { $0.speciesId == "ovenbird" })?.status, .tentative)
    }

    func testPresenceRollupInsufficientWhenAllRejected() {
        let vouchers = [
            voucher(speciesId: "mockingbird", vetStatus: .rejected),
            voucher(speciesId: "mockingbird", vetStatus: .rejected),
        ]
        let rollup = PresenceRollupEngine.rollup(vouchers: vouchers)
        XCTAssertEqual(rollup.first?.status, .insufficientEvidence)
    }

    func testScoringVouchersExcludeRejected() {
        let vouchers = [
            voucher(speciesId: "a", vetStatus: .autoAccepted),
            voucher(speciesId: "b", vetStatus: .rejected),
        ]
        XCTAssertEqual(PresenceRollupEngine.scoringVouchers(vouchers).count, 1)
        XCTAssertEqual(PresenceRollupEngine.validatedVouchers(vouchers).count, 1)
    }

    func testVetStatusColumnsMatchKaleidoscopeExport() {
        XCTAssertEqual(VetStatus.autoAccepted.autoIdColumn, "yes")
        XCTAssertEqual(VetStatus.confirmed.manualIdColumn, "yes")
        XCTAssertEqual(VetStatus.rejected.manualIdColumn, "no")
        XCTAssertEqual(VetStatus.needsReview.autoIdColumn, "")
    }
}