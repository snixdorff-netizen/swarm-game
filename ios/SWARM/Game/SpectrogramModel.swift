// Live spectrogram strip data for listen-burst UI (3-band field display).

import Foundation

struct SpectrogramBand: Identifiable, Equatable {
    let id: String
    let label: String
    let level: CGFloat
}

struct SpectrogramSnapshot: Equatable {
    let bands: [SpectrogramBand]
    let dominantLabel: String?
    let deployMode: DeployMode
}

enum SpectrogramBuilder {
    static let lowBand = SpectrogramBand(id: "low", label: "80–500 Hz", level: 0)
    static let midBand = SpectrogramBand(id: "mid", label: "2–12 kHz", level: 0)
    static let ultraBand = SpectrogramBand(id: "ultra", label: "20–120 kHz†", level: 0)

    /// Build band levels from nearby species vocalizations.
    static func snapshot(nearby: [SurveySpecies], deployMode: DeployMode) -> SpectrogramSnapshot {
        var low: CGFloat = 0.04
        var mid: CGFloat = 0.04
        var ultra: CGFloat = deployMode == .sm5bat ? 0.08 : 0.03
        var dominant: (SurveySpecies, CGFloat)?

        for species in nearby {
            let profile = SpeciesCallProfiles.profile(for: species)
            let weight: CGFloat = species == .endangered ? 1.0 : 0.72
            switch profile.band {
            case .acoustic:
                if profile.audibleMaxHz < 900 {
                    low = max(low, weight)
                } else {
                    mid = max(mid, weight)
                }
            case .ultrasonic:
                ultra = max(ultra, weight * deployMode.ultrasonicVisibilityBoost)
            }
            let peak = max(low, mid, ultra)
            if dominant == nil || peak > (dominant?.1 ?? 0) {
                dominant = (species, peak)
            }
        }

        if deployMode == .sm5 {
            mid = min(1, mid * 1.12)
        } else {
            ultra = min(1, ultra * 1.18)
        }

        let bands = [
            SpectrogramBand(id: "low", label: "80–500 Hz", level: min(1, low)),
            SpectrogramBand(id: "mid", label: "2–12 kHz", level: min(1, mid)),
            SpectrogramBand(id: "ultra", label: "20–120 kHz†", level: min(1, ultra)),
        ]
        let label = dominant.map { "\($0.0.displayName) · \($0.0.bandLabel)" }
        return SpectrogramSnapshot(bands: bands, dominantLabel: label, deployMode: deployMode)
    }
}