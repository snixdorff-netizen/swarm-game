// P5 Analyst Loop — Kaleidoscope-style vetting + presence/absence rollup.

import Foundation

enum VetStatus: String, Codable, Equatable, CaseIterable {
    case autoAccepted
    case confirmed
    case needsReview
    case rejected

    var isValidated: Bool {
        switch self {
        case .autoAccepted, .confirmed: return true
        case .needsReview, .rejected: return false
        }
    }

    var label: String {
        switch self {
        case .autoAccepted: return SurveyProtocolCopy.autoIdAccepted
        case .confirmed: return SurveyProtocolCopy.manualIdConfirmed
        case .needsReview: return SurveyProtocolCopy.needsReview
        case .rejected: return SurveyProtocolCopy.manualIdRejected
        }
    }

    var autoIdColumn: String {
        switch self {
        case .autoAccepted: return "yes"
        default: return ""
        }
    }

    var manualIdColumn: String {
        switch self {
        case .confirmed: return "yes"
        case .rejected: return "no"
        default: return ""
        }
    }
}

struct VetSession: Equatable {
    let voucherId: String
    let commonName: String
    let scientificName: String
    let confidence: CGFloat
    let clipFilename: String
    let queueIndex: Int
    let queueTotal: Int

    var queueLabel: String { "Clip \(queueIndex) of \(queueTotal)" }

    init(voucher: DetectionVoucher, queueIndex: Int, queueTotal: Int) {
        voucherId = voucher.id
        commonName = voucher.commonName
        scientificName = voucher.scientificName
        confidence = voucher.confidence
        clipFilename = voucher.clipFilename
        self.queueIndex = queueIndex
        self.queueTotal = queueTotal
    }
}

enum VetQueueEngine {
    static func orderedPending(_ vouchers: [DetectionVoucher]) -> [DetectionVoucher] {
        vouchers.filter { $0.vetStatus == .needsReview }
    }

    static func backlogCount(_ vouchers: [DetectionVoucher]) -> Int {
        orderedPending(vouchers).count
    }

    static func session(for voucherId: String, in vouchers: [DetectionVoucher]) -> VetSession? {
        let pending = orderedPending(vouchers)
        guard let idx = pending.firstIndex(where: { $0.id == voucherId }) else { return nil }
        return VetSession(voucher: pending[idx], queueIndex: idx + 1, queueTotal: pending.count)
    }

    static func session(at index: Int, in vouchers: [DetectionVoucher]) -> VetSession? {
        let pending = orderedPending(vouchers)
        guard index >= 0, index < pending.count else { return nil }
        return VetSession(voucher: pending[index], queueIndex: index + 1, queueTotal: pending.count)
    }

    /// After a vet decision, return the next analyst session or nil when the queue is empty.
    /// `decidedIndex` is the voucher's position in the pending queue *before* the decision was applied.
    static func advanceAfterDecision(
        vouchers: [DetectionVoucher],
        decidedId: String,
        decision: VetStatus,
        decidedIndex: Int
    ) -> VetSession? {
        let pending = orderedPending(vouchers)
        guard !pending.isEmpty else { return nil }
        switch decision {
        case .confirmed, .rejected:
            let nextIdx = decidedIndex < pending.count ? decidedIndex : 0
            return session(at: nextIdx, in: vouchers)
        case .needsReview:
            if pending.count == 1 { return session(for: decidedId, in: vouchers) }
            return session(at: (decidedIndex + 1) % pending.count, in: vouchers)
        case .autoAccepted:
            return session(at: 0, in: vouchers)
        }
    }
}

enum PresenceStatus: String, Codable, Equatable {
    case present
    case tentative
    case insufficientEvidence

    var label: String {
        switch self {
        case .present: return SurveyProtocolCopy.presencePresent
        case .tentative: return SurveyProtocolCopy.presenceTentative
        case .insufficientEvidence: return SurveyProtocolCopy.presenceInsufficient
        }
    }
}

struct SpeciesPresenceRecord: Equatable, Codable, Identifiable {
    var id: String { speciesId }
    let speciesId: String
    let commonName: String
    let scientificName: String
    let status: PresenceStatus
    let validatedPasses: Int
    let tentativePasses: Int
    let rejectedPasses: Int
    let meanConfidence: CGFloat

    var summaryLine: String {
        switch status {
        case .present:
            return "\(commonName) — \(status.label) (\(validatedPasses) validated, \(Int(meanConfidence * 100))% mean)"
        case .tentative:
            return "\(commonName) — \(status.label) (\(tentativePasses) unvetted)"
        case .insufficientEvidence:
            return "\(commonName) — \(status.label)"
        }
    }
}

enum PresenceRollupEngine {
    static func rollup(vouchers: [DetectionVoucher]) -> [SpeciesPresenceRecord] {
        let grouped = Dictionary(grouping: vouchers, by: \.speciesId)
        return grouped.map { speciesId, group in
            let validated = group.filter { $0.vetStatus.isValidated }
            let tentative = group.filter { $0.vetStatus == .needsReview }
            let rejected = group.filter { $0.vetStatus == .rejected }
            let scoring = group.filter { $0.vetStatus != .rejected }
            let mean = scoring.isEmpty ? 0 : scoring.map(\.confidence).reduce(0, +) / CGFloat(scoring.count)
            let status: PresenceStatus = {
                if !validated.isEmpty { return .present }
                if !tentative.isEmpty { return .tentative }
                return .insufficientEvidence
            }()
            let sample = group[0]
            return SpeciesPresenceRecord(
                speciesId: speciesId,
                commonName: sample.commonName,
                scientificName: sample.scientificName,
                status: status,
                validatedPasses: validated.count,
                tentativePasses: tentative.count,
                rejectedPasses: rejected.count,
                meanConfidence: mean
            )
        }
        .sorted { lhs, rhs in
            if lhs.status != rhs.status {
                return lhs.status == .present || (lhs.status == .tentative && rhs.status == .insufficientEvidence)
            }
            return lhs.commonName < rhs.commonName
        }
    }

    static func validatedVouchers(_ vouchers: [DetectionVoucher]) -> [DetectionVoucher] {
        vouchers.filter(\.vetStatus.isValidated)
    }

    static func scoringVouchers(_ vouchers: [DetectionVoucher]) -> [DetectionVoucher] {
        vouchers.filter { $0.vetStatus != .rejected }
    }
}

enum AnalystLoop {
    static func initialVetStatus(kind: Int, confidence: CGFloat, listenRecent: Bool) -> VetStatus {
        if kind == 3 && !listenRecent { return .needsReview }
        if GameSettings.conservativeClassifier {
            if kind == 3 { return .needsReview }
            if confidence < 0.72 { return .needsReview }
        } else if confidence < 0.58 {
            return .needsReview
        }
        return .autoAccepted
    }
}