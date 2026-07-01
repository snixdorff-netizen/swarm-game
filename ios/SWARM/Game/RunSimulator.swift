// Automated multi-run session simulation for balance confidence.
// Mortal mode models HP, incoming damage, and early death using BalanceEngine combat math.

import Foundation

struct RunMetrics: Codable, Equatable {
    let profile: String
    let survivalSec: Int
    let kills: Int
    let level: Int
    let seed: UInt64
    let died: Bool
    let bossReached: Bool
    let mode: String
    let metaLevels: Int
}

enum SimulationMode: Equatable {
    /// Skilled kiter still takes damage (default balance runs).
    case mortal(kiting: CGFloat = BalanceEngine.skilledKiterEfficiency)
    /// Matches SWARM_AUTOSTART QA hook — no incoming damage.
    case immortalQA
}

enum RunSimulator {
    static let defaultMaxSeconds = 120

    static func simulate(
        profile: BuildProfile,
        seed: UInt64,
        maxSeconds: Int = defaultMaxSeconds,
        meta: MetaStore? = nil,
        mode: SimulationMode = .mortal()
    ) -> RunMetrics {
        var rng = SeededRNG(seed: seed)
        var state = BuildState()
        var metaLeech: CGFloat = 0
        if let meta {
            state.dmgMult = meta.damageMult
            state.maxHp = 100 + meta.bonusHp
            state.moveSpeed = 178 * meta.speedMult
            state.pickupRadius = 78 + meta.bonusMagnet
            state.xpMult = meta.xpMult
            metaLeech = meta.leechPerKill
        }
        if profile == .metaBoosted {
            state.dmgMult = max(state.dmgMult, 1.15)
            state.xpMult = max(state.xpMult, 1.08)
            state.maxHp += 16
        }

        let kiting: CGFloat
        switch mode {
        case .immortalQA: kiting = 0
        case .mortal(let k):
            var jitter = SeededRNG(seed: seed ^ 0xA5A5_5A5A_C3C3_3C3C)
            let scale = 0.86 + CGFloat(jitter.nextUnit()) * 0.28
            kiting = k * scale
        }

        var time: CGFloat = 0
        var hp = state.maxHp
        var kills = 0
        var level = 1
        var xp: CGFloat = 0
        var xpToNext = BalanceEngine.initialXpToNext()
        var enemyCount = 6
        var spawnTimer: CGFloat = 0
        var bossSpawned = false
        var bossReached = false
        var died = false
        let modeLabel: String = {
            switch mode {
            case .immortalQA: return "immortalQA"
            case .mortal: return "mortal"
            }
        }()
        let metaLevels = meta.map { store in
            MetaCatalog.all.reduce(0) { $0 + store.level(for: $1.id) }
        } ?? 0

        while time < CGFloat(maxSeconds) && hp > 0 {
            let dt: CGFloat = 1.0
            time += dt
            spawnTimer -= dt
            if spawnTimer <= 0 && enemyCount < BalanceEngine.maxEnemies {
                spawnTimer = BalanceEngine.spawnInterval(runTime: time)
                enemyCount = min(BalanceEngine.maxEnemies, enemyCount + BalanceEngine.spawnBatchSize(runTime: time))
            }
            if !bossSpawned && time >= BalanceEngine.bossSpawnSeconds {
                bossSpawned = true
                bossReached = true
                enemyCount = min(BalanceEngine.maxEnemies, enemyCount + 1)
            }

            if state.regen > 0 && hp < state.maxHp {
                hp = min(state.maxHp, hp + state.regen * dt)
            }

            let roll = CGFloat(rng.nextUnit())
            let tickKind = BalanceEngine.enemyKind(runTime: time, roll: roll)
            let tickStats = BalanceEngine.enemyStats(kind: tickKind, runTime: time)
            var incoming = BalanceEngine.incomingDamagePerSecond(
                enemyCount: enemyCount,
                runTime: time,
                kitingEfficiency: kiting,
                bossPresent: bossSpawned
            )
            incoming *= tickStats.damage / max(1, BalanceEngine.expectedEnemyMix(runTime: time).damage)
            if incoming > 0 {
                hp -= incoming * dt
            }

            let killRate = BalanceEngine.outgoingKillRate(enemyCount: enemyCount, runTime: time, build: state)
            let killsThisTick = Int(killRate.rounded(.down))
            if killsThisTick > 0 {
                kills += killsThisTick
                enemyCount = max(0, enemyCount - killsThisTick)
                let mix = BalanceEngine.expectedEnemyMix(runTime: time)
                xp += CGFloat(killsThisTick) * mix.xp * state.xpMult
                let heal = BalanceEngine.leechHealOnKill(leechLevel: state.leechLevel, metaLeech: metaLeech)
                if heal > 0 { hp = min(state.maxHp, hp + heal * CGFloat(killsThisTick)) }
                while xp >= xpToNext {
                    xp -= xpToNext
                    level += 1
                    xpToNext = BalanceEngine.xpThresholdAfterLevel(current: xpToNext)
                    state.apply(upgradeId: BuildState.preferredUpgrade(for: profile))
                }
            }

            _ = rng.nextUnit() // consume RNG per tick for seed-sensitive variance in future tuning
            if hp <= 0 {
                hp = 0
                died = true
                break
            }
        }

        if time >= CGFloat(maxSeconds) && hp > 0 { died = false }

        return RunMetrics(
            profile: profile.rawValue,
            survivalSec: max(0, Int(time.rounded(.down))),
            kills: kills,
            level: level,
            seed: seed,
            died: died,
            bossReached: bossReached,
            mode: modeLabel,
            metaLevels: metaLevels
        )
    }

    /// Representative batch for engagement verification: all profiles + meta + boss path.
    static func representativeBatch() -> [RunMetrics] {
        var runs: [RunMetrics] = []
        for (profileIndex, profile) in BuildProfile.allCases.enumerated() {
            for i in 0..<2 {
                let seed = UInt64(5000 + i * 31 + profileIndex)
                runs.append(simulate(profile: profile, seed: seed, mode: .mortal()))
            }
        }
        let suite = "swarm-sim-meta-\(ProcessInfo.processInfo.processIdentifier)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        let meta = MetaStore(defaults: ud)
        meta.awardRun(kills: 600, timeSec: 500)
        for up in MetaCatalog.all where meta.canBuy(up) { _ = meta.buy(up) }
        runs.append(simulate(profile: .baseline, seed: 8080, meta: meta, mode: .mortal()))
        runs.append(simulate(profile: .leechTank, seed: 8081, meta: meta, mode: .mortal()))
        runs.append(simulate(profile: .novaRush, seed: 9090, maxSeconds: 120, mode: .immortalQA))
        runs.append(simulate(profile: .chainArc, seed: 9091, maxSeconds: 120, mode: .immortalQA))
        return runs
    }

    static func batchSimulate(
        count: Int,
        baseSeed: UInt64 = 42,
        profile: BuildProfile = .baseline,
        mode: SimulationMode = .mortal()
    ) -> [RunMetrics] {
        (0..<count).map { i in
            simulate(profile: profile, seed: baseSeed &+ UInt64(i), mode: mode)
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

    static func survivalVariance(_ runs: [RunMetrics]) -> Int {
        guard let minS = runs.map(\.survivalSec).min(), let maxS = runs.map(\.survivalSec).max() else { return 0 }
        return maxS - minS
    }

    static func runsDivergeOnSurvival(_ a: [RunMetrics], _ b: [RunMetrics]) -> Bool {
        let ma = medianSurvival(a), mb = medianSurvival(b)
        return abs(ma - mb) >= 4
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

    @discardableResult
    static func exportRepresentativeBatch(filename: String = "sim-metrics.json") throws -> URL {
        try export(RunSimulator.representativeBatch(), filename: filename)
    }

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