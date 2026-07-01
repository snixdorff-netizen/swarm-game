// Procedural species vocalizations by acoustic band.
// Ultrasonic signatures (20–120 kHz) are down-converted to audible sweeps for mobile speakers.

import AVFoundation
import Foundation

enum CallBand: String, Equatable, Codable {
    case acoustic
    case ultrasonic
}

struct SpeciesCallProfile: Equatable {
    let species: SurveySpecies
    let band: CallBand
    let nominalKHzMin: Double
    let nominalKHzMax: Double
    let callInterval: CGFloat
    /// Playable synthesis range on device (Hz).
    let audibleMinHz: Double
    let audibleMaxHz: Double
}

enum SpeciesCallProfiles {
    static func profile(for species: SurveySpecies) -> SpeciesCallProfile {
        switch species {
        case .passerine:
            return SpeciesCallProfile(species: species, band: .acoustic, nominalKHzMin: 2, nominalKHzMax: 8,
                                      callInterval: 2.4, audibleMinHz: 2_800, audibleMaxHz: 5_200)
        case .swift:
            return SpeciesCallProfile(species: species, band: .acoustic, nominalKHzMin: 4, nominalKHzMax: 12,
                                      callInterval: 1.5, audibleMinHz: 4_200, audibleMaxHz: 7_800)
        case .resonant:
            return SpeciesCallProfile(species: species, band: .acoustic, nominalKHzMin: 0.08, nominalKHzMax: 0.5,
                                      callInterval: 3.2, audibleMinHz: 140, audibleMaxHz: 280)
        case .mimic:
            return SpeciesCallProfile(species: species, band: .acoustic, nominalKHzMin: 1.5, nominalKHzMax: 9,
                                      callInterval: 2.0, audibleMinHz: 1_900, audibleMaxHz: 5_600)
        case .endangered:
            return SpeciesCallProfile(species: species, band: .ultrasonic, nominalKHzMin: 20, nominalKHzMax: 120,
                                      callInterval: 0.85, audibleMinHz: 9_500, audibleMaxHz: 14_500)
        }
    }
}

final class SpeciesCallSynth {
    static let shared = SpeciesCallSynth()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var running = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    private func ensureRunning() {
        guard !running else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            running = true
        } catch { /* silent fallback */ }
    }

    func play(species: SurveySpecies, pan: Float, volume: Float = 0.42) {
        guard GameSettings.soundEnabled else { return }
        ensureRunning()
        let profile = SpeciesCallProfiles.profile(for: species)
        let gain = GameSettings.listenGain
        let samples = synthesize(profile: profile, pan: pan, volume: volume * gain)
        guard !samples.isEmpty else { return }
        let frames = AVAudioFrameCount(samples.count / 2)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buf.frameLength = frames
        guard let left = buf.floatChannelData?[0], let right = buf.floatChannelData?[1] else { return }
        for i in 0..<Int(frames) {
            left[i] = samples[i * 2]
            right[i] = samples[i * 2 + 1]
        }
        player.scheduleBuffer(buf, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    func playConfirm(species: SurveySpecies) {
        play(species: species, pan: 0, volume: 0.22)
    }

    // MARK: - Synthesis

    private func synthesize(profile: SpeciesCallProfile, pan: Float, volume: Float) -> [Float] {
        let sr = format.sampleRate
        let clampedPan = max(-1, min(1, pan))
        let leftGain = 0.5 + clampedPan * 0.5
        let rightGain = 0.5 - clampedPan * 0.5

        switch profile.species {
        case .passerine:
            return renderChirps(sr: sr, freqs: [3_200, 4_100, 3_600], chirpLen: 0.055, gap: 0.07,
                                vol: volume * 0.9, left: leftGain, right: rightGain)
        case .swift:
            return renderTrill(sr: sr, low: profile.audibleMinHz, high: profile.audibleMaxHz,
                               pulses: 14, pulseLen: 0.018, vol: volume * 0.85, left: leftGain, right: rightGain)
        case .resonant:
            return renderDrone(sr: sr, freq: 190, duration: 0.42, vibratoHz: 3.2,
                             vol: volume * 1.0, left: leftGain, right: rightGain)
        case .mimic:
            return renderMimic(sr: sr, freqs: [2_200, 5_100, 2_800, 4_600], vol: volume * 0.8,
                               left: leftGain, right: rightGain)
        case .endangered:
            return renderUltrasonicDownconvert(sr: sr, sweepHigh: profile.audibleMaxHz,
                                               sweepLow: profile.audibleMinHz, vol: volume * 0.95,
                                               left: leftGain, right: rightGain)
        }
    }

    private func renderChirps(sr: Double, freqs: [Double], chirpLen: Double, gap: Double,
                              vol: Float, left: Float, right: Float) -> [Float] {
        var out: [Float] = []
        for (i, f) in freqs.enumerated() {
            if i > 0 { out.append(contentsOf: silence(sr: sr, duration: gap, left: left, right: right)) }
            out.append(contentsOf: tone(sr: sr, freq: f, duration: chirpLen, vol: vol, attack: 0.004, decay: 0.75,
                                        left: left, right: right))
        }
        return out
    }

    private func renderTrill(sr: Double, low: Double, high: Double, pulses: Int, pulseLen: Double,
                             vol: Float, left: Float, right: Float) -> [Float] {
        var out: [Float] = []
        for i in 0..<pulses {
            let t = Double(i) / Double(max(1, pulses - 1))
            let f = low + (high - low) * t
            out.append(contentsOf: tone(sr: sr, freq: f, duration: pulseLen, vol: vol, attack: 0.002, decay: 0.6,
                                        left: left, right: right))
        }
        return out
    }

    private func renderDrone(sr: Double, freq: Double, duration: Double, vibratoHz: Double,
                             vol: Float, left: Float, right: Float) -> [Float] {
        let frames = Int(sr * duration)
        var out = [Float](repeating: 0, count: frames * 2)
        for i in 0..<frames {
            let t = Double(i) / sr
            let env = Float(min(1, t / 0.06)) * Float(pow(1 - Double(i) / Double(frames), 1.4))
            let vibrato = 1 + 0.08 * sin(2 * .pi * vibratoHz * t)
            let sample = sin(Float(2 * .pi * freq * vibrato * t)) * vol * env
            out[i * 2] = sample * left
            out[i * 2 + 1] = sample * right
        }
        return out
    }

    private func renderMimic(sr: Double, freqs: [Double], vol: Float, left: Float, right: Float) -> [Float] {
        var out: [Float] = []
        for f in freqs {
            out.append(contentsOf: tone(sr: sr, freq: f, duration: 0.07, vol: vol, attack: 0.006, decay: 0.7,
                                        left: left, right: right))
            out.append(contentsOf: silence(sr: sr, duration: 0.04, left: left, right: right))
        }
        return out
    }

    /// SM5BAT-class ultrasonic: frequency sweep + noise burst (heterodyned for playback).
    private func renderUltrasonicDownconvert(sr: Double, sweepHigh: Double, sweepLow: Double,
                                             vol: Float, left: Float, right: Float) -> [Float] {
        let sweepDur = 0.09
        let noiseDur = 0.05
        let sweepFrames = Int(sr * sweepDur)
        var out = [Float](repeating: 0, count: sweepFrames * 2)
        for i in 0..<sweepFrames {
            let t = Double(i) / Double(max(1, sweepFrames))
            let f = sweepHigh + (sweepLow - sweepHigh) * t
            let env = Float(pow(1 - t, 0.35))
            let sample = sin(Float(2 * .pi * f * Double(i) / sr)) * vol * env
            out[i * 2] = sample * left
            out[i * 2 + 1] = sample * right
        }
        let noiseFrames = Int(sr * noiseDur)
        for i in 0..<noiseFrames {
            let env = Float(1 - Double(i) / Double(noiseFrames))
            let n = Float.random(in: -1...1) * vol * 0.55 * env
            out.append(n * left)
            out.append(n * right)
        }
        return out
    }

    private func tone(sr: Double, freq: Double, duration: Double, vol: Float, attack: Double, decay: Double,
                      left: Float, right: Float) -> [Float] {
        let frames = Int(sr * duration)
        var out = [Float](repeating: 0, count: frames * 2)
        let attackFrames = Int(sr * attack)
        for i in 0..<frames {
            let env: Float
            if i < attackFrames {
                env = Float(i) / Float(max(1, attackFrames))
            } else {
                let d = Float(i - attackFrames) / Float(max(1, frames - attackFrames))
                env = pow(1 - d, Float(decay * 3))
            }
            let sample = sin(Float(2 * .pi * freq * Double(i) / sr)) * vol * env
            out[i * 2] = sample * left
            out[i * 2 + 1] = sample * right
        }
        return out
    }

    private func silence(sr: Double, duration: Double, left: Float, right: Float) -> [Float] {
        let frames = Int(sr * duration)
        return [Float](repeating: 0, count: frames * 2)
    }
}