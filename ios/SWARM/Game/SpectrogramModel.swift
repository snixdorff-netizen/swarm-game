// Live spectrogram strip data for listen-burst UI (3-band field display).

import Foundation

struct SpectrogramBand: Identifiable, Equatable {
    let id: String
    let label: String
    let level: CGFloat
}

struct SpectrogramWaterfall: Equatable {
    let timeSteps: Int
    let freqBins: Int
    /// Row-major energy 0…1 (freq × time).
    let energy: [Float]

    static let defaultTimeSteps = 48
    static let defaultFreqBins = 32
}

struct SpectrogramSnapshot: Equatable {
    let bands: [SpectrogramBand]
    let dominantLabel: String?
    let deployMode: DeployMode
    let waterfall: SpectrogramWaterfall
}

enum SpectrogramBuilder {
    static let lowBand = SpectrogramBand(id: "low", label: "80–500 Hz", level: 0)
    static let midBand = SpectrogramBand(id: "mid", label: "2–12 kHz", level: 0)
    static let ultraBand = SpectrogramBand(id: "ultra", label: "20–120 kHz†", level: 0)

    /// Build band levels + mini waterfall from nearby project species.
    static func snapshot(nearby: [ProjectSpecies], deployMode: DeployMode, seed: UInt64 = 42) -> SpectrogramSnapshot {
        var low: CGFloat = 0.04
        var mid: CGFloat = 0.04
        var ultra: CGFloat = deployMode == .sm5bat ? 0.08 : 0.03
        var dominant: (ProjectSpecies, CGFloat)?

        for species in nearby {
            let legacy = ProjectSpeciesCatalog.surveySpecies(for: species)
            let profile = SpeciesCallProfiles.profile(for: legacy)
            let weight: CGFloat = species.callBand == .ultrasonic ? 1.0 : 0.72
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
        let label = dominant.map { $0.0.displayLine + " · " + $0.0.bandLabel }
        let waterfall = buildWaterfall(nearby: nearby, deployMode: deployMode, seed: seed)
        return SpectrogramSnapshot(bands: bands, dominantLabel: label, deployMode: deployMode, waterfall: waterfall)
    }

    static func buildWaterfall(nearby: [ProjectSpecies], deployMode: DeployMode, seed: UInt64) -> SpectrogramWaterfall {
        let tN = SpectrogramWaterfall.defaultTimeSteps
        let fN = SpectrogramWaterfall.defaultFreqBins
        var grid = [Float](repeating: 0.02, count: tN * fN)
        var rng = SeededRNG(seed: seed)

        for species in nearby {
            let legacy = ProjectSpeciesCatalog.surveySpecies(for: species)
            let profile = SpeciesCallProfiles.profile(for: legacy)
            let centerBin: Int = {
                switch profile.band {
                case .ultrasonic: return Int(Double(fN) * 0.82)
                case .acoustic:
                    return profile.audibleMaxHz < 900 ? Int(Double(fN) * 0.18) : Int(Double(fN) * 0.52)
                }
            }()
            let span = species.callBand == .ultrasonic ? 4 : 6
            for col in 0..<tN {
                let speciesSeed = species.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
                let pulse = sin(Double(col) * 0.55 + Double(speciesSeed % 7)) * 0.5 + 0.5
                let amp = Float(0.35 + pulse * 0.45) * Float.random(in: 0.7...1.0, using: &rng)
                for b in max(0, centerBin - span)...min(fN - 1, centerBin + span) {
                    let idx = b * tN + col
                    grid[idx] = min(1, grid[idx] + amp * (1 - Float(abs(b - centerBin)) / Float(span + 1)))
                }
            }
        }

        if deployMode == .sm5bat {
            for i in 0..<grid.count where (i / tN) > fN * 2 / 3 {
                grid[i] = min(1, grid[i] * 1.15)
            }
        }

        return SpectrogramWaterfall(timeSteps: tN, freqBins: fN, energy: grid)
    }
}

private extension Float {
    static func random(in range: ClosedRange<Float>, using rng: inout SeededRNG) -> Float {
        Float(rng.nextUnit()) * (range.upperBound - range.lowerBound) + range.lowerBound
    }
}