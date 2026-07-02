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

    func testVetQueuePreservesEncounterOrder() {
        let vouchers = [
            voucher(speciesId: "a", vetStatus: .needsReview),
            voucher(speciesId: "b", vetStatus: .autoAccepted),
            voucher(speciesId: "c", vetStatus: .needsReview),
        ]
        let pending = VetQueueEngine.orderedPending(vouchers)
        XCTAssertEqual(pending.map(\.speciesId), ["a", "c"])
        XCTAssertEqual(VetQueueEngine.backlogCount(vouchers), 2)
    }

    func testVetQueueSessionShowsPosition() {
        let vouchers = [
            DetectionVoucher(
                id: "v1", speciesId: "wood_thrush", commonName: "Wood Thrush",
                scientificName: "H. mustelina", confidence: 0.6, timeSec: 10, vetStatus: .needsReview,
                deploymentId: "DEP", siteLabel: "Site", recorderProfile: "SM5",
                clipFilename: "a.wav"
            ),
            DetectionVoucher(
                id: "v2", speciesId: "ovenbird", commonName: "Ovenbird",
                scientificName: "S. aurocapilla", confidence: 0.55, timeSec: 20, vetStatus: .needsReview,
                deploymentId: "DEP", siteLabel: "Site", recorderProfile: "SM5",
                clipFilename: "b.wav"
            ),
        ]
        let session = VetQueueEngine.session(at: 1, in: vouchers)
        XCTAssertEqual(session?.queueLabel, "Clip 2 of 2")
        XCTAssertEqual(session?.voucherId, "v2")
    }

    func testAdvanceAfterConfirmShowsNextPending() {
        var vouchers = [
            DetectionVoucher(
                id: "v1", speciesId: "a", commonName: "A", scientificName: "S. a",
                confidence: 0.6, timeSec: 10, vetStatus: .needsReview,
                deploymentId: "DEP", siteLabel: "Site", recorderProfile: "SM5", clipFilename: "a.wav"
            ),
            DetectionVoucher(
                id: "v2", speciesId: "b", commonName: "B", scientificName: "S. b",
                confidence: 0.55, timeSec: 20, vetStatus: .needsReview,
                deploymentId: "DEP", siteLabel: "Site", recorderProfile: "SM5", clipFilename: "b.wav"
            ),
            DetectionVoucher(
                id: "v3", speciesId: "c", commonName: "C", scientificName: "S. c",
                confidence: 0.5, timeSec: 30, vetStatus: .needsReview,
                deploymentId: "DEP", siteLabel: "Site", recorderProfile: "SM5", clipFilename: "c.wav"
            ),
        ]
        vouchers[0] = vouchers[0].withVetStatus(.confirmed)
        let next = VetQueueEngine.advanceAfterDecision(
            vouchers: vouchers, decidedId: "v1", decision: .confirmed, decidedIndex: 0
        )
        XCTAssertEqual(next?.voucherId, "v2")
        XCTAssertEqual(next?.queueLabel, "Clip 1 of 2")
        vouchers[1] = vouchers[1].withVetStatus(.rejected)
        let afterReject = VetQueueEngine.advanceAfterDecision(
            vouchers: vouchers, decidedId: "v2", decision: .rejected, decidedIndex: 0
        )
        XCTAssertEqual(afterReject?.voucherId, "v3")
    }

    func testDeferThenResolveAdvancesFromNonHeadPosition() {
        let vouchers = [
            DetectionVoucher(
                id: "v1", speciesId: "a", commonName: "A", scientificName: "S. a",
                confidence: 0.6, timeSec: 10, vetStatus: .needsReview,
                deploymentId: "DEP", siteLabel: "Site", recorderProfile: "SM5", clipFilename: "a.wav"
            ),
            DetectionVoucher(
                id: "v2", speciesId: "b", commonName: "B", scientificName: "S. b",
                confidence: 0.55, timeSec: 20, vetStatus: .needsReview,
                deploymentId: "DEP", siteLabel: "Site", recorderProfile: "SM5", clipFilename: "b.wav"
            ),
            DetectionVoucher(
                id: "v3", speciesId: "c", commonName: "C", scientificName: "S. c",
                confidence: 0.5, timeSec: 30, vetStatus: .needsReview,
                deploymentId: "DEP", siteLabel: "Site", recorderProfile: "SM5", clipFilename: "c.wav"
            ),
        ]
        let deferred = VetQueueEngine.advanceAfterDecision(
            vouchers: vouchers, decidedId: "v1", decision: .needsReview, decidedIndex: 0
        )
        XCTAssertEqual(deferred?.voucherId, "v2")
        var resolved = vouchers
        resolved[1] = resolved[1].withVetStatus(.confirmed)
        let afterConfirm = VetQueueEngine.advanceAfterDecision(
            vouchers: resolved, decidedId: "v2", decision: .confirmed, decidedIndex: 1
        )
        XCTAssertEqual(afterConfirm?.voucherId, "v3")
        XCTAssertNotEqual(afterConfirm?.voucherId, "v1")
    }

    func testEmptyQueueDismissesSession() {
        let vouchers = [voucher(speciesId: "a", vetStatus: .confirmed)]
        XCTAssertNil(VetQueueEngine.session(at: 0, in: vouchers))
        XCTAssertEqual(VetQueueEngine.backlogCount(vouchers), 0)
        XCTAssertNil(VetQueueEngine.advanceAfterDecision(
            vouchers: vouchers, decidedId: "v-a-confirmed", decision: .confirmed, decidedIndex: 0
        ))
    }

    func testRichnessCountsValidatedPresenceOnly() {
        let vouchers = [
            voucher(speciesId: "wood_thrush", vetStatus: .needsReview),
            voucher(speciesId: "ovenbird", vetStatus: .autoAccepted),
        ]
        let present = PresenceRollupEngine.rollup(vouchers: vouchers).filter { $0.status == .present }.count
        XCTAssertEqual(present, 1)
    }
}