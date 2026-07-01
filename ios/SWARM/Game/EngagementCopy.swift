// Player-facing motivation copy — casual mobile survivor tone.

import Foundation

enum EngagementCopy {
    static func deathLines(timeSec: Int, kills: Int, level: Int, isNewBest: Bool) -> (headline: String, subline: String) {
        if isNewBest {
            return ("NEW BEST!", "You survived \(formatTime(timeSec)) — the horde remembers.")
        }
        if timeSec >= 90 {
            return ("SO CLOSE", "You lasted \(timeStr(timeSec)) and hit the boss wave. One more run.")
        }
        if timeSec >= 60 {
            return ("STRONG RUN", "\(kills) kills · LV \(level). The swarm is learning — so are you.")
        }
        if timeSec >= 30 {
            return ("GETTING WARMED UP", "+\(MetaStore.coresForRun(kills: kills, timeSec: timeSec)) cores waiting. Spend them on Upgrades.")
        }
        if kills >= 20 {
            return ("BRAVE FIGHT", "Short run, \(kills) kills. Grab XP gems earlier next time.")
        }
        return ("YOU DIED", "Drag to move · green gems level you up · try a new build path.")
    }

    static let firstRunSteps: [String] = [
        "Drag anywhere to move",
        "Weapons fire automatically",
        "Collect green gems to level up",
        "Pick upgrades to shape your build",
        "Earn cores after each run → Upgrades menu",
    ]
}

private func formatTime(_ s: Int) -> String {
    String(format: "%d:%02d", s / 60, s % 60)
}