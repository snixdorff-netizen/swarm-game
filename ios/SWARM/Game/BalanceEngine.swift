// Pure balance/progression math — testable without SpriteKit.

import Foundation

enum EnemyKind: Int {
    case basic = 0, fast = 1, tank = 2, shooter = 3, boss = 9
}

struct EnemyStatBlock {
    let hp: CGFloat
    let speed: CGFloat
    let radius: CGFloat
    let damage: CGFloat
    let xp: CGFloat
}

enum BalanceEngine {
    static let bossSpawnSeconds: CGFloat = 90
    static let maxEnemies = 130
    static let milestoneSeconds: [Int] = [30, 60]

    static func spawnInterval(runTime: CGFloat) -> CGFloat {
        max(0.12, 0.5 - runTime * 0.005)
    }

    static func spawnBatchSize(runTime: CGFloat) -> Int {
        2 + Int(runTime / 18)
    }

    /// Deterministic enemy kind from run time and roll in 0...1.
    static func enemyKind(runTime: CGFloat, roll: CGFloat) -> EnemyKind {
        if runTime > 60 && roll < 0.16 { return .tank }
        if runTime > 45 && roll < 0.28 { return .shooter }
        if runTime > 28 && roll < 0.42 { return .fast }
        return .basic
    }

    static func difficultyScale(runTime: CGFloat) -> CGFloat {
        1 + runTime * 0.012
    }

    static func enemyStats(kind: EnemyKind, runTime: CGFloat) -> EnemyStatBlock {
        let scale = difficultyScale(runTime: runTime)
        let dmgScale = 1 + runTime * 0.004
        switch kind {
        case .basic:
            return EnemyStatBlock(hp: 18 * scale, speed: 52, radius: 12, damage: 8 * dmgScale, xp: 1)
        case .fast:
            return EnemyStatBlock(hp: 12 * scale, speed: 96, radius: 9, damage: 7 * dmgScale, xp: 1)
        case .tank:
            return EnemyStatBlock(hp: 70 * scale, speed: 34, radius: 19, damage: 16 * dmgScale, xp: 3)
        case .shooter:
            return EnemyStatBlock(hp: 22 * scale, speed: 38, radius: 11, damage: 5 * dmgScale, xp: 2)
        case .boss:
            return EnemyStatBlock(hp: 420 * scale, speed: 28, radius: 30, damage: 28 * dmgScale, xp: 18)
        }
    }

    static func xpThresholdAfterLevel(current: CGFloat) -> CGFloat {
        ceil(current * 1.28 + 3)
    }

    static func initialXpToNext() -> CGFloat { 6 }

    static func milestoneBanner(for seconds: Int) -> String? {
        switch seconds {
        case 30: return "30 SECONDS — KEEP GOING"
        case 60: return "1 MINUTE — HORDE RISING"
        default: return nil
        }
    }
}