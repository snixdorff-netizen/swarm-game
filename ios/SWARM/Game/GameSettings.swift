// User preferences persisted in UserDefaults.

import Foundation

enum GameSettings {
    private static let ud = UserDefaults.standard
    private static let soundKey = "swarm_sound_on"
    private static let hapticsKey = "swarm_haptics_on"

    static var soundEnabled: Bool {
        get {
            if ud.object(forKey: soundKey) == nil { return true }
            return ud.bool(forKey: soundKey)
        }
        set { ud.set(newValue, forKey: soundKey) }
    }

    static var hapticsEnabled: Bool {
        get {
            if ud.object(forKey: hapticsKey) == nil { return true }
            return ud.bool(forKey: hapticsKey)
        }
        set { ud.set(newValue, forKey: hapticsKey) }
    }
}