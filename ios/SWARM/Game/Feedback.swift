// Procedural SFX + Core Haptics — no audio assets required.

import AVFoundation
import CoreHaptics
import UIKit

final class SfxPlayer {
    static let shared = SfxPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var running = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
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

    func play(freq: Double, duration: Double, volume: Float = 0.35, attack: Double = 0.008, decay: Double = 0.92) {
        guard GameSettings.soundEnabled else { return }
        ensureRunning()
        let sr = format.sampleRate
        let frames = AVAudioFrameCount(sr * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buf.frameLength = frames
        guard let data = buf.floatChannelData?[0] else { return }
        let attackFrames = Int(sr * attack)
        let total = Int(frames)
        for i in 0..<total {
            let t = Double(i) / sr
            let env: Float
            if i < attackFrames {
                env = Float(i) / Float(max(1, attackFrames))
            } else {
                let d = Float(i - attackFrames) / Float(max(1, total - attackFrames))
                env = pow(1 - d, Float(decay * 4))
            }
            data[i] = sin(Float(2 * .pi * freq * t)) * volume * env
        }
        player.scheduleBuffer(buf, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    func hit() { play(freq: 220, duration: 0.06, volume: 0.22) }
    func kill() { play(freq: 440, duration: 0.08, volume: 0.28, decay: 0.7) }
    func pickup() { play(freq: 660, duration: 0.05, volume: 0.2) }
    func levelUp() { play(freq: 523, duration: 0.12, volume: 0.32); DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { self.play(freq: 784, duration: 0.14, volume: 0.3) } }
    func hurt() { play(freq: 110, duration: 0.14, volume: 0.38) }
    func death() { play(freq: 180, duration: 0.35, volume: 0.4, decay: 1.2) }
    func boss() { play(freq: 90, duration: 0.5, volume: 0.45); DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.play(freq: 70, duration: 0.6, volume: 0.42) } }
    func nova() { play(freq: 300, duration: 0.1, volume: 0.25) }
    func chain() { play(freq: 880, duration: 0.04, volume: 0.2) }
}

final class Haptics {
    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notify = UINotificationFeedbackGenerator()

    private init() {
        light.prepare(); medium.prepare(); heavy.prepare(); notify.prepare()
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            engine = try? CHHapticEngine()
            try? engine?.start()
        }
    }

    private func tap(_ block: () -> Void) { guard GameSettings.hapticsEnabled else { return }; block() }

    func hit() { tap { light.impactOccurred(intensity: 0.5) } }
    func kill() { tap { medium.impactOccurred(intensity: 0.65) } }
    func hurt() { tap { heavy.impactOccurred(intensity: 0.9) } }
    func levelUp() { tap { notify.notificationOccurred(.success) } }
    func death() { tap { notify.notificationOccurred(.error) } }
    func boss() { tap { heavy.impactOccurred(intensity: 1) } }
}