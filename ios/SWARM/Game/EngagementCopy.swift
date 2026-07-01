// Player-facing motivation copy — Wildlife Acoustics–style field survey tone.

import Foundation

enum EngagementCopy {
    static func deathLines(timeSec: Int, kills: Int, level: Int, isNewBest: Bool) -> (headline: String, subline: String) {
        if isNewBest {
            return ("NEW SURVEY RECORD", "Longest deployment \(formatTime(timeSec)) — catalog updated.")
        }
        if timeSec >= 90 {
            return ("ENDANGERED SIGNAL LOGGED", "You reached \(timeStr(timeSec)) and triggered the rare ultrasonic event. Deploy again.")
        }
        if timeSec >= 60 {
            return ("STRONG INVENTORY", "\(kills) confirmed IDs · Rank \(level). Habitat activity rising.")
        }
        if timeSec >= 30 {
            return ("BASELINE ESTABLISHED", "+\(MetaStore.coresForRun(kills: kills, timeSec: timeSec)) survey grants ready. Visit Field Lab.")
        }
        if kills >= 20 {
            return ("SHORT DEPLOYMENT", "\(kills) IDs logged. Sweep wider — collect more recording clips.")
        }
        return ("SURVEY ENDED", "Move quietly · gather green recording clips · tune your classifier kit.")
    }

    static let firstRunSteps = AcousticFieldCopy.firstRunSteps
}

private func formatTime(_ s: Int) -> String {
    String(format: "%d:%02d", s / 60, s % 60)
}