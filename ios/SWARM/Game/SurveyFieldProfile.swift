// P4 — survey-first field behavior: de-emphasize survivor combat, passive bat monitoring.

import Foundation
import CoreGraphics

enum SurveyFieldProfile: Equatable {
    case acousticTransect
    case passiveUltrasonic

    static func from(deployMode: DeployMode) -> SurveyFieldProfile {
        deployMode == .sm5bat ? .passiveUltrasonic : .acousticTransect
    }

    var usesPassivePasses: Bool { self == .passiveUltrasonic }

    /// How strongly vocalizations drift toward the rig (0 = crossing pass only).
    var pursuitFactor: CGFloat {
        switch self {
        case .acousticTransect: return 0.28
        case .passiveUltrasonic: return 0
        }
    }

    var passDriftSpeedMult: CGFloat {
        switch self {
        case .acousticTransect: return 0.35
        case .passiveUltrasonic: return 1.0
        }
    }

    var moveSpeedMult: CGFloat {
        switch self {
        case .acousticTransect: return 1.0
        case .passiveUltrasonic: return 0.38
        }
    }

    var maxActiveSignatures: Int {
        switch self {
        case .acousticTransect: return 85
        case .passiveUltrasonic: return 48
        }
    }

    var spawnIntervalMult: CGFloat {
        switch self {
        case .acousticTransect: return 1.18
        case .passiveUltrasonic: return 1.42
        }
    }

    var spawnBatchReduction: Int {
        switch self {
        case .acousticTransect: return 0
        case .passiveUltrasonic: return 1
        }
    }

    var mimicInterferenceInterval: CGFloat {
        switch self {
        case .acousticTransect: return 1.35
        case .passiveUltrasonic: return 4.2
        }
    }

    var autoArchiveClips: Bool { true }
    var hideXpBar: Bool { true }

    /// Rank-up pacing — detections archive automatically (no clip chase).
    var surveyXpMult: CGFloat {
        switch self {
        case .acousticTransect: return 1.25
        case .passiveUltrasonic: return 1.35
        }
    }
    var joystickEnabled: Bool { self == .acousticTransect }

    var emergenceBanner: String? {
        switch self {
        case .passiveUltrasonic: return "Emergence window — passive ultrasonic monitor"
        case .acousticTransect: return nil
        }
    }

    var fieldOverlayHint: String {
        switch self {
        case .acousticTransect: return "Walk transect quietly — classifiers scan automatically"
        case .passiveUltrasonic: return "Passive monitor — ultrasonic passes log automatically"
        }
    }

    /// Drift angle for passive passes — perpendicular to spawn vector so calls cross the rig.
    static func passDriftAngle(spawnAngle: CGFloat) -> CGFloat {
        spawnAngle + .pi / 2
    }
}