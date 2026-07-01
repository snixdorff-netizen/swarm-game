// Per-deployment mission brief and survey scoring (protocol-first).

import Foundation

struct SurveyMission: Equatable, Codable {
    let id: String
    let title: String
    let hypothesis: String
    let targetDetections: Int
    let targetRichness: Int
    let minMeanConfidence: CGFloat
    let transectDurationSec: Int

    static func random(deployMode: DeployMode, seed: UInt64 = UInt64.random(in: 0...9999)) -> SurveyMission {
        var rng = SeededRNG(seed: seed)
        let templates: [(String, String, Int, Int, CGFloat, Int)] = {
            switch deployMode {
            case .sm5:
                return [
                    ("Dawn Chorus Baseline", "Document passerine vocal activity post-restoration.", 18, 4, 0.62, 540),
                    ("Canopy Point Count", "Establish presence of forest songbirds along transect.", 22, 5, 0.58, 600),
                    ("Wetland Dawn Survey", "Log low-frequency amphibian and owl vocalizations.", 16, 3, 0.60, 480),
                ]
            case .sm5bat:
                return [
                    ("Bat Emergence Survey", "Confirm ultrasonic passes at corridor crossing.", 14, 3, 0.65, 540),
                    ("SM5BAT Overnight Slice", "Inventory high-frequency contact calls along transect.", 12, 2, 0.68, 480),
                    ("Endangered Acoustic Watch", "Target rare ultrasonic signature with high confidence.", 10, 2, 0.72, 720),
                ]
            }
        }()
        let t = templates[Int(rng.nextUnit() * Double(templates.count)) % templates.count]
        return SurveyMission(
            id: "mission-\(seed)",
            title: t.0,
            hypothesis: t.1,
            targetDetections: t.2,
            targetRichness: t.3,
            minMeanConfidence: t.4,
            transectDurationSec: t.5
        )
    }
}

struct DetectionVoucher: Identifiable, Equatable, Codable {
    let id: String
    let speciesId: String
    let commonName: String
    let scientificName: String
    let confidence: CGFloat
    let timeSec: Int
    let validated: Bool
}

struct SurveyRunReport: Equatable, Codable {
    let missionId: String
    let missionTitle: String
    let timeSec: Int
    let detections: Int
    let richness: Int
    let meanConfidence: CGFloat
    let falsePositives: Int
    let surveyScore: Int
    let missionPassed: Bool
    let abortReason: String?
    let vouchers: [DetectionVoucher]

    var scoreBreakdown: String {
        "Richness \(richness) · Detections \(detections) · Confidence \(Int(meanConfidence * 100))%"
    }
}

enum SurveyScoreEngine {
    static func confidence(for archetype: Int, listenBurstRecently: Bool) -> CGFloat {
        switch archetype {
        case 3: return listenBurstRecently ? 0.74 : 0.41
        case 9: return listenBurstRecently ? 0.88 : 0.62
        case 2: return 0.70
        case 1: return 0.66
        default: return 0.64
        }
    }

    static func compute(
        mission: SurveyMission,
        timeSec: Int,
        vouchers: [DetectionVoucher],
        aborted: Bool
    ) -> SurveyRunReport {
        let richness = Set(vouchers.map(\.speciesId)).count
        let meanConf = vouchers.isEmpty ? 0 : vouchers.map(\.confidence).reduce(0, +) / CGFloat(vouchers.count)
        let falsePos = vouchers.filter { !$0.validated }.count
        var score = richness * 120 + vouchers.count * 8 + Int(meanConf * 80) - falsePos * 25 + min(timeSec, mission.transectDurationSec) / 6
        if aborted { score = max(0, score - 40) }

        let passed = !aborted
            && vouchers.count >= mission.targetDetections
            && richness >= mission.targetRichness
            && meanConf >= mission.minMeanConfidence
            && timeSec >= min(120, mission.transectDurationSec / 3)

        return SurveyRunReport(
            missionId: mission.id,
            missionTitle: mission.title,
            timeSec: timeSec,
            detections: vouchers.count,
            richness: richness,
            meanConfidence: meanConf,
            falsePositives: falsePos,
            surveyScore: score,
            missionPassed: passed,
            abortReason: aborted ? "Noise budget exceeded — deployment aborted" : nil,
            vouchers: vouchers
        )
    }
}