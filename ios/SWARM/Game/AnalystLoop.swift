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

    init(voucher: DetectionVoucher) {
        voucherId = voucher.id
        commonName = voucher.commonName
        scientificName = voucher.scientificName
        confidence = voucher.confidence
        clipFilename = voucher.clipFilename
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