// Field bioacoustics survey content — inspired by professional acoustic monitoring workflows
// (Song Meter deployments, ultrasonic bat surveys, Kaleidoscope-style classification).

import Foundation
import CoreGraphics

enum SurveySpecies: Int {
    case passerine = 0   // basic acoustic signature
    case swift = 1       // fast caller
    case resonant = 2    // low-frequency (tank)
    case mimic = 3       // false-positive echo
    case endangered = 9  // rare ultrasonic / SM5BAT-class event

    var displayName: String {
        switch self {
        case .passerine: return "Passerine Call"
        case .swift: return "Swift Trill"
        case .resonant: return "Resonant Drone"
        case .mimic: return "Echo Mimic"
        case .endangered: return "Endangered Ultrasonic"
        }
    }

    var bandLabel: String {
        switch self {
        case .passerine: return "2–8 kHz acoustic"
        case .swift: return "4–12 kHz acoustic"
        case .resonant: return "80–500 Hz acoustic"
        case .mimic: return "Variable band"
        case .endangered: return "Ultrasonic 20–120 kHz"
        }
    }

    static func from(enemyKind: Int) -> SurveySpecies {
        SurveySpecies(rawValue: enemyKind) ?? .passerine
    }
}

enum AcousticFieldCopy {
    static let tagline = "We listen."
    static let subtitle = "Bioacoustic field survey"
    static let deployButton = "Deploy Survey"
    static let fieldLabButton = "Field Lab"
    static let grantsLabel = "grants"
    static let shareTagline = "Bioacoustic field survey — SWARM Acoustic"

    static let firstRunSteps: [String] = [
        "Drag to reposition your Song Meter rig (SM5BAT = passive monitor)",
        "Listen for band-specific calls — tap Listen for spectrogram burst",
        "Vet tentative IDs — Confirm / Reject / Needs review after Listen",
        "Confirmed IDs archive automatically — rank up your survey rig",
        "Earn survey grants → Field Lab between deployments",
    ]
}

enum AcousticFieldCatalog {
    /// In-run field kit cards (stable upgrade IDs; Wildlife Acoustics–inspired naming).
    static func kitCard(id: String, orbitLevel: Int, novaLevel: Int, chainLevel: Int, leechLevel: Int, boltPierce: Int, regen: CGFloat) -> UpgradeCard? {
        switch id {
        case "bolt_dmg":
            return UpgradeCard(id: id, title: "Narrow-Beam Mic", subtitle: "+7 classifier gain", symbol: "mic.fill", levelText: "")
        case "bolt_rate":
            return UpgradeCard(id: id, title: "Fast Sampling", subtitle: "Scan vocalizations faster", symbol: "timer", levelText: "")
        case "bolt_count":
            return UpgradeCard(id: id, title: "Multi-Channel Array", subtitle: "+1 beam per sweep", symbol: "square.grid.3x3.fill", levelText: "")
        case "bolt_pierce":
            guard boltPierce < 4 else { return nil }
            return UpgradeCard(id: id, title: "Band-Pass Filter", subtitle: "Pierce +1 masking layer", symbol: "slider.horizontal.3", levelText: "")
        case "orbit":
            return UpgradeCard(id: id, title: orbitLevel == 0 ? "Perimeter Song Meters" : "More Song Meters",
                               subtitle: orbitLevel == 0 ? "Deploy edge recorders" : "+1 perimeter node",
                               symbol: "dot.radiowaves.left.and.right", levelText: orbitLevel == 0 ? "NEW" : "Lv \(orbitLevel + 1)")
        case "orbit_dmg":
            guard orbitLevel > 0 else { return nil }
            return UpgradeCard(id: id, title: "High-Gain Mics", subtitle: "+recorder sensitivity", symbol: "waveform.circle.fill", levelText: "")
        case "nova":
            return UpgradeCard(id: id, title: novaLevel == 0 ? "Harmonic Sweep" : "Faster Sweep",
                               subtitle: novaLevel == 0 ? "Kaleidoscope-style band scan" : "Sweep more often",
                               symbol: "waveform.path.ecg", levelText: novaLevel == 0 ? "NEW" : "Lv \(novaLevel + 1)")
        case "nova_radius":
            guard novaLevel > 0 else { return nil }
            return UpgradeCard(id: id, title: "Wideband Array", subtitle: "+sweep radius", symbol: "circle.circle", levelText: "")
        case "chain":
            return UpgradeCard(id: id, title: chainLevel == 0 ? "Call Relay Network" : "Faster Relay",
                               subtitle: chainLevel == 0 ? "Chain IDs across callers" : "Relay more often",
                               symbol: "point.3.connected.trianglepath.dotted", levelText: chainLevel == 0 ? "NEW" : "Lv \(chainLevel + 1)")
        case "chain_dmg":
            guard chainLevel > 0 else { return nil }
            return UpgradeCard(id: id, title: "Stronger Classifier", subtitle: "+relay confidence", symbol: "bolt.horizontal.fill", levelText: "")
        case "leech":
            return UpgradeCard(id: id, title: leechLevel == 0 ? "Passive Monitor" : "Stronger Monitor",
                               subtitle: leechLevel == 0 ? "Recover clarity on confirm" : "+clarity per ID",
                               symbol: "antenna.radiowaves.left.and.right", levelText: leechLevel == 0 ? "NEW" : "Lv \(leechLevel + 1)")
        case "max_hp":
            return UpgradeCard(id: id, title: "Field Stamina", subtitle: "+25 signal clarity", symbol: "waveform.badge.magnifyingglass", levelText: "")
        case "move":
            return UpgradeCard(id: id, title: "Quiet Approach", subtitle: "+deploy speed, less disturbance", symbol: "figure.walk", levelText: "")
        case "pickup":
            return UpgradeCard(id: id, title: "Clip Magnet", subtitle: "+recording clip range", symbol: "archivebox.fill", levelText: "")
        case "regen":
            guard regen < 6 else { return nil }
            return UpgradeCard(id: id, title: "Noise Floor Recovery", subtitle: "Clarity recovers over time", symbol: "leaf.fill", levelText: "")
        default:
            return nil
        }
    }

    static let kitPoolIds: [String] = [
        "bolt_dmg", "bolt_rate", "bolt_count", "bolt_pierce", "orbit", "orbit_dmg",
        "nova", "nova_radius", "chain", "chain_dmg", "leech", "max_hp", "move", "pickup", "regen"
    ]
}