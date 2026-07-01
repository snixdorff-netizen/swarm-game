// Drives shipped GameScene.update for batch metrics and integration tests.
// Mortal runs: autopilot kiting ON, invulnerability OFF — real spawns, weapons, hurtCooldown, die().

import SpriteKit

enum HeadlessRunMode: String, Equatable {
    case mortal
    case immortalQA
}

@MainActor
enum HeadlessRunDriver {
    static let defaultMaxSeconds = 120

    static func run(
        profile: BuildProfile,
        seed: UInt64,
        maxSeconds: Int = 120,
        meta: MetaStore? = nil,
        mode: HeadlessRunMode = .mortal
    ) -> GameSceneRunSummary {
        unsetenv("SWARM_AUTOSTART")
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 430, height: 932))
        let store = meta ?? MetaStore(defaults: isolatedDefaults(seed: seed))
        let model = GameModel(meta: store)
        let scene = GameScene(size: CGSize(width: 430, height: 932))
        scene.model = model
        scene.testing_attach(to: view)
        scene.testingRunProfile = profile
        scene.testing_setSpawnSeed(seed)
        scene.testingAutopilotMovement = true
        scene.testingPlayerInvulnerable = (mode == .immortalQA)
        scene.testingCasualAutopilot = (mode == .mortal)
        scene.startRun()
        scene.testing_applyRunProfile(profile)
        scene.testing_fastForward(seconds: CGFloat(maxSeconds), profile: profile)
        return scene.testing_captureSummary(profile: profile, seed: seed, mode: mode)
    }

    static func batch(
        count: Int,
        baseSeed: UInt64 = 42,
        profile: BuildProfile = .baseline,
        maxSeconds: Int = defaultMaxSeconds,
        mode: HeadlessRunMode = .mortal
    ) -> [GameSceneRunSummary] {
        (0..<count).map { i in
            run(profile: profile, seed: baseSeed &+ UInt64(i), maxSeconds: maxSeconds, mode: mode)
        }
    }

    /// Scan seeded mortal runs until a natural death on the shipped loop (for batch evidence).
    static func probeMortalDeath(
        profile: BuildProfile = .baseline,
        baseSeed: UInt64 = 6000,
        scan: Int = 16,
        maxSeconds: Int = 120
    ) -> GameSceneRunSummary {
        for offset in 0..<scan {
            let summary = run(profile: profile, seed: baseSeed &+ UInt64(offset), maxSeconds: maxSeconds, mode: .mortal)
            if summary.died { return summary }
        }
        return run(profile: profile, seed: baseSeed, maxSeconds: maxSeconds, mode: .mortal)
    }

    /// Scan seeded mortal runs until boss spawn (≥90s survival or death after boss).
    static func probeMortalBoss(
        profile: BuildProfile = .leechTank,
        baseSeed: UInt64 = 8081,
        scan: Int = 24,
        maxSeconds: Int = 120,
        meta: MetaStore? = nil
    ) -> GameSceneRunSummary {
        for offset in 0..<scan {
            let summary = run(profile: profile, seed: baseSeed &+ UInt64(offset), maxSeconds: maxSeconds, meta: meta, mode: .mortal)
            if summary.bossSpawned { return summary }
        }
        return run(profile: profile, seed: baseSeed, maxSeconds: maxSeconds, meta: meta, mode: .mortal)
    }

    private static func isolatedDefaults(seed: UInt64) -> UserDefaults {
        let suite = "swarm-headless-\(seed)-\(ProcessInfo.processInfo.processIdentifier)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        return ud
    }
}

extension GameSceneRunSummary {
    var asRunMetrics: RunMetrics {
        RunMetrics(
            profile: profile,
            survivalSec: survivalSec,
            kills: kills,
            level: level,
            seed: seed,
            died: died,
            bossReached: bossSpawned,
            mode: mode,
            metaLevels: metaLevels
        )
    }
}