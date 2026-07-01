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
    static let bossTeaseSeconds: Int = 75
    static let maxEnemies = 130
    static let milestoneSeconds: [Int] = [30, 60]
    static let killStreakThresholds: [Int] = [25, 50, 100]

    static func spawnInterval(runTime: CGFloat) -> CGFloat {
        max(0.14, 0.58 - runTime * 0.004)
    }

    static func spawnBatchSize(runTime: CGFloat) -> Int {
        if runTime < 30 { return 2 }
        return 2 + Int(runTime / 20)
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
        let dmgScale = 1 + runTime * 0.003
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
        case 30: return "30s — BASELINE LOCKED"
        case 60: return "1:00 — VOCAL ACTIVITY RISING"
        default: return nil
        }
    }

    static func bossTeaseBanner() -> String { "RARE SPECIES IN 15s" }

    static func killStreakBanner(for kills: Int) -> String? {
        switch kills {
        case 25: return "25 IDs — STRONG INVENTORY"
        case 50: return "50 IDs — CATALOG SURGE"
        case 100: return "100 IDs — FULL SPECTRUM"
        default: return nil
        }
    }

    /// Song Meter + classifier modules extend acoustic detection range (fauna visibility).
    static func detectionRadius(
        pickupRadius: CGFloat,
        orbitLevel: Int,
        chainLevel: Int,
        deployMode: DeployMode = .sm5,
        listenBurstActive: Bool = false
    ) -> CGFloat {
        var r = 110 + pickupRadius * 0.55 + CGFloat(orbitLevel) * 28 + CGFloat(chainLevel) * 16
        r *= deployMode.acousticDetectMult
        if listenBurstActive { r *= deployMode.listenBurstMult }
        return r
    }

    /// Fauna vocalizations audible beyond visual detection (bioacoustic hear radius).
    static func hearRadius(detectionRadius: CGFloat) -> CGFloat {
        detectionRadius * 1.42
    }

    /// Casual-friendly hint for the in-run HUD (what to chase next).
    static func nextGoalHint(timeSec: Int, kills: Int) -> String {
        if timeSec < 30 { return "Goal: establish 0:30 baseline" }
        if timeSec < bossTeaseSeconds { return "Goal: reach 1:00 inventory" }
        if timeSec < Int(bossSpawnSeconds) { return "Goal: rare species at 1:30" }
        if kills < 25 { return "Goal: 25 confirmed IDs" }
        if kills < 50 { return "Goal: 50 confirmed IDs" }
        return "Goal: log endangered ultrasonic"
    }

    // MARK: - Combat pressure (mirrors GameScene contact + shooter cadence)

    static let contactHurtCooldown: CGFloat = 0.62
    static let shotHurtCooldown: CGFloat = 0.48
    static let playerContactPadding: CGFloat = 13
    /// Autopilot kiter in SWARM_AUTOSTART avoids most hits; mortal sim uses this proc scale.
    static let skilledKiterEfficiency: CGFloat = 0.30
    /// Headless mortal batch: imperfect one-thumb kiting for casual mobile target users.
    static let casualAutopilotEfficiency: CGFloat = 0.52
    static let casualAutopilotFleeRadius: CGFloat = 178

    /// Weighted mean enemy mix at `runTime` using the same roll thresholds as spawnOne.
    static func expectedEnemyMix(runTime: CGFloat) -> EnemyStatBlock {
        let t = runTime
        var wBasic: CGFloat = 1, wFast: CGFloat = 0, wShooter: CGFloat = 0, wTank: CGFloat = 0
        if t > 28 { wFast = 0.42; wBasic = 1 - wFast }
        if t > 45 { wShooter = 0.28; wBasic = max(0, wBasic - wShooter) }
        if t > 60 { wTank = 0.16; wBasic = max(0, wBasic - wTank) }
        let total = wBasic + wFast + wShooter + wTank
        func blend(_ k: EnemyKind, _ w: CGFloat) -> EnemyStatBlock {
            let s = enemyStats(kind: k, runTime: t)
            return EnemyStatBlock(hp: s.hp * w / total, speed: s.speed * w / total,
                                radius: s.radius * w / total, damage: s.damage * w / total, xp: s.xp * w / total)
        }
        let b = blend(.basic, wBasic), f = blend(.fast, wFast), sh = blend(.shooter, wShooter), tk = blend(.tank, wTank)
        return EnemyStatBlock(
            hp: b.hp + f.hp + sh.hp + tk.hp,
            speed: b.speed + f.speed + sh.speed + tk.speed,
            radius: b.radius + f.radius + sh.radius + tk.radius,
            damage: b.damage + f.damage + sh.damage + tk.damage,
            xp: b.xp + f.xp + sh.xp + tk.xp
        )
    }

    /// Swarm pressure 0…1 — GameScene applies one contact hit per global hurtCooldown window.
    static func swarmPressure(enemyCount: Int) -> CGFloat {
        min(1, CGFloat(enemyCount) / 42)
    }

    /// Expected contact hits per second (single-target hits, not stacked enemy damage).
    static func contactHitsPerSecond(enemyCount: Int, kitingEfficiency: CGFloat) -> CGFloat {
        guard enemyCount > 0, kitingEfficiency > 0 else { return 0 }
        return swarmPressure(enemyCount: enemyCount) * kitingEfficiency / contactHurtCooldown
    }

    /// Damage dealt to player in one second — mirrors global hurtCooldown + shooter cadence.
    static func incomingDamagePerSecond(
        enemyCount: Int,
        runTime: CGFloat,
        kitingEfficiency: CGFloat,
        bossPresent: Bool
    ) -> CGFloat {
        guard enemyCount > 0, kitingEfficiency > 0 else { return 0 }
        let mix = expectedEnemyMix(runTime: runTime)
        let contactDPS = contactHitsPerSecond(enemyCount: enemyCount, kitingEfficiency: kitingEfficiency) * mix.damage

        let shooterHits = (runTime > 45 ? min(0.35, CGFloat(enemyCount) * 0.0055) : 0) * kitingEfficiency / shotHurtCooldown
        let shotDPS = shooterHits * mix.damage * 0.75

        var bossDPS: CGFloat = 0
        if bossPresent {
            let boss = enemyStats(kind: .boss, runTime: runTime)
            bossDPS = kitingEfficiency / 0.9 * boss.damage * 0.35
        }
        return contactDPS + shotDPS + bossDPS
    }

    /// DPS output vs horde — uses BuildState.estimatedDPS on expected mix HP.
    static func outgoingKillRate(enemyCount: Int, runTime: CGFloat, build: BuildState) -> CGFloat {
        guard enemyCount > 0 else { return 0 }
        let mix = expectedEnemyMix(runTime: runTime)
        let dps = build.estimatedDPS(enemyCount: enemyCount)
        return min(CGFloat(enemyCount), dps / max(4, mix.hp))
    }

    static func leechHealOnKill(leechLevel: Int, metaLeech: CGFloat) -> CGFloat {
        CGFloat(leechLevel) * 3 + metaLeech
    }
}