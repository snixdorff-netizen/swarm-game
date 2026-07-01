// User preferences persisted in UserDefaults.

import Foundation

enum GameSettings {
    static let soundKey = "swarm_sound_on"
    static let hapticsKey = "swarm_haptics_on"
    static let listenGainKey = "swarm_listen_gain"
    static let colorblindKey = "swarm_colorblind_spec"
    static let traineeKey = "swarm_trainee_mode"
    static let captionsKey = "swarm_captions_on"
    static let mentorshipKey = "swarm_mentorship_done"
    static let habitatKey = "swarm_habitat_site"
    static let transectKey = "swarm_transect_mode"

    private static var storage: UserDefaults = .standard

    static func configure(defaults: UserDefaults = .standard) {
        storage = defaults
    }

    static var soundEnabled: Bool {
        get {
            if storage.object(forKey: soundKey) == nil { return true }
            return storage.bool(forKey: soundKey)
        }
        set { storage.set(newValue, forKey: soundKey) }
    }

    static var hapticsEnabled: Bool {
        get {
            if storage.object(forKey: hapticsKey) == nil { return true }
            return storage.bool(forKey: hapticsKey)
        }
        set { storage.set(newValue, forKey: hapticsKey) }
    }

    /// Headphone / field listen gain multiplier (0.6–1.4).
    static var listenGain: Float {
        get {
            let v = storage.float(forKey: listenGainKey)
            return v == 0 ? 1.0 : min(1.4, max(0.6, v))
        }
        set { storage.set(min(1.4, max(0.6, newValue)), forKey: listenGainKey) }
    }

    static var colorblindSpectrogram: Bool {
        get { storage.bool(forKey: colorblindKey) }
        set { storage.set(newValue, forKey: colorblindKey) }
    }

    static var traineeMode: Bool {
        get { storage.bool(forKey: traineeKey) }
        set { storage.set(newValue, forKey: traineeKey) }
    }

    static var captionsEnabled: Bool {
        get { storage.bool(forKey: captionsKey) }
        set { storage.set(newValue, forKey: captionsKey) }
    }

    static var mentorshipCompleted: Bool {
        get { storage.bool(forKey: mentorshipKey) }
        set { storage.set(newValue, forKey: mentorshipKey) }
    }

    static var habitatSite: HabitatSite {
        get {
            guard let raw = storage.string(forKey: habitatKey),
                  let site = HabitatSite(rawValue: raw) else { return .canopy }
            return site
        }
        set { storage.set(newValue.rawValue, forKey: habitatKey) }
    }

    static var transectMode: TransectMode {
        get {
            guard let raw = storage.string(forKey: transectKey),
                  let mode = TransectMode(rawValue: raw) else { return .fieldDay }
            return mode
        }
        set { storage.set(newValue.rawValue, forKey: transectKey) }
    }
}