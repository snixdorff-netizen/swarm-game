// Automated multi-run session simulation for balance confidence.

import Foundation

struct RunMetrics: Codable, Equatable {
    let profile: String
    let survivalSec: Int
    let kills: Int
    let level: Int
    let seed: UInt64
}

enum RunSimulator {
    static let defaultMaxSeconds = 120

    /// Autopilot session: immortal kiter (matches SWARM_AUTOSTART), deterministic RNG.
    static func simulate(
        profile: BuildProfile,
        seed: UInt64,
        maxSeconds: Int = defaultMaxSeconds,
        meta: MetaStore? = nil
    ) -> RunMetrics {
        var rng = SeededRNG(seed: seed)
        var state = BuildState()
        if let meta {
            state.dmgMult = meta.damageMult
            state.maxHp = 100 + meta.bonusHp
            state.moveSpeed = 178 * meta.speedMult
            state.pickupRadius = 78 + meta.bonusMagnet
            state.xpMult = meta.xpMult
        }
        if profile == .metaBoosted {
            state.dmgMult = max(state.dmgMult, 1.15)
            state.xpMult = max(state.xpMult, 1.08)
        }

        var time: CGFloat = 0
        var kills = 0
        var level = 1
        var xp: CGFloat = 0
        var xpToNext = BalanceEngine.initialXpToNext()
        var enemyCount = 6
        var spawnTimer: CGFloat = 0
        var bossSpawned = false

        while time < CGFloat(maxSeconds) {
            let dt: CGFloat = 1.0
            time += dt
            spawnTimer -= dt
            if spawnTimer <= 0 && enemyCount < BalanceEngine.maxEnemies {
                spawnTimer = BalanceEngine.spawnInterval(runTime: time)
                let batch = BalanceEngine.spawnBatchSize(runTime: time)
                enemyCount = min(BalanceEngine.maxEnemies, enemyCount + batch)
            }
            if !bossSpawned && time >= BalanceEngine.bossSpawnSeconds {
                bossSpawned = true
                enemyCount = min(BalanceEngine.maxEnemies, enemyCount + 1)
            }

            let avgRoll = CGFloat(rng.nextUnit())
            let kind = BalanceEngine.enemyKind(runTime: time, roll: avgRoll)
            let stats = BalanceEngine.enemyStats(kind: kind, runTime: time)
            let dps = state.estimatedDPS(enemyCount: enemyCount)
            let killRate = min(CGFloat(enemyCount), dps / max(4, stats.hp))
            let killsThisTick = Int(killRate.rounded(.down))
            if killsThisTick > 0 {
                kills += killsThisTick
                enemyCount = max(0, enemyCount - killsThisTick)
                let xpGain = CGFloat(killsThisTick) * stats.xp * state.xpMult
                xp += xpGain
                while xp >= xpToNext {
                    xp -= xpToNext
                    level += 1
                    xpToNext = BalanceEngine.xpThresholdAfterLevel(current: xpToNext)
                    let pick = BuildState.preferredUpgrade(for: profile)
                    state.apply(upgradeId: pick)
                }
            }
        }

        return RunMetrics(
            profile: profile.rawValue,
            survivalSec: Int(time.rounded(.down)),
            kills: kills,
            level: level,
            seed: seed
        )
    }

    static func batchSimulate(
        count: Int,
        baseSeed: UInt64 = 42,
        profile: BuildProfile = .baseline
    ) -> [RunMetrics] {
        (0..<count).map { i in
            simulate(profile: profile, seed: baseSeed &+ UInt64(i))
        }
    }

    static func medianSurvival(_ runs: [RunMetrics]) -> Double {
        guard !runs.isEmpty else { return 0 }
        let sorted = runs.map { Double($0.survivalSec) }.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }

    static func runsDiverge(_ a: [RunMetrics], _ b: [RunMetrics], atSecond: Int = 60) -> Bool {
        guard let ka = a.first(where: { $0.survivalSec >= atSecond }),
              let kb = b.first(where: { $0.survivalSec >= atSecond }) else { return false }
        return ka.kills != kb.kills || ka.level != kb.level
    }
}

/// Minimal deterministic RNG for simulation (SplitMix64).
struct SeededRNG {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func nextUnit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}

enum SimulationMetricsExporter {
    static let goalScratch = "/var/folders/jc/vlt38jc172b76pd4lmy9ch340000gn/T/grok-goal-a3a70e15315e/implementer"

    static func export(_ runs: [RunMetrics], filename: String = "sim-metrics.json") throws -> URL {
        let dir = URL(fileURLWithPath: goalScratch, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(filename)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try enc.encode(runs).write(to: url)
        return url
    }
}