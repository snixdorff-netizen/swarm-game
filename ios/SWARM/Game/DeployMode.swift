// Song Meter SM5 (acoustic) vs SM5BAT (ultrasonic) deployment profiles.

import Foundation

enum DeployMode: String, CaseIterable, Codable, Equatable {
    case sm5
    case sm5bat

    var title: String {
        switch self {
        case .sm5: return "Song Meter SM5"
        case .sm5bat: return "Song Meter SM5BAT"
        }
    }

    var subtitle: String {
        switch self {
        case .sm5: return "Acoustic survey — birds & dawn chorus"
        case .sm5bat: return "Passive monitor — ultrasonic passes"
        }
    }

    var symbol: String {
        switch self {
        case .sm5: return "waveform"
        case .sm5bat: return "waveform.path.ecg.rectangle"
        }
    }

    /// Multiplier on acoustic detection radius.
    var acousticDetectMult: CGFloat {
        switch self {
        case .sm5: return 1.14
        case .sm5bat: return 1.02
        }
    }

    /// Fauna visibility boost for endangered / ultrasonic signatures.
    var ultrasonicVisibilityBoost: CGFloat {
        switch self {
        case .sm5: return 1.0
        case .sm5bat: return 1.45
        }
    }

    /// Hear radius multiplier during listen burst.
    var listenBurstMult: CGFloat {
        switch self {
        case .sm5: return 1.55
        case .sm5bat: return 1.72
        }
    }

    /// Scene palette — SM5BAT uses a night-transect look (P1#10).
    var sceneBackground: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .sm5: return (0.082, 0.161, 0.192)   // WA navy #152931
        case .sm5bat: return (0.102, 0.118, 0.114) // navy + olive night transect
        }
    }

    var sceneGrid: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .sm5: return (0.200, 0.239, 0.114)   // WA olive dark #333d1d
        case .sm5bat: return (0.161, 0.176, 0.231) // muted blue grid for ultrasonic
        }
    }

    var callIntervalScale: CGFloat {
        switch self {
        case .sm5: return 1.0
        case .sm5bat: return 0.72
        }
    }
}