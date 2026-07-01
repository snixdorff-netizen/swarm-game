// User preferences persisted in UserDefaults.

import Foundation

enum GameSettings {
    static let soundKey = "swarm_sound_on"
    static let hapticsKey = "swarm_haptics_on"

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
}