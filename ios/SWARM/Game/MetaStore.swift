// Meta-progression: cores earned per run, permanent upgrades between runs.

import Foundation

struct MetaUpgrade: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let maxLevel: Int
    let cost: (Int) -> Int   // cost for next level
}

enum MetaCatalog {
    static let all: [MetaUpgrade] = [
        MetaUpgrade(id: "meta_dmg", title: "Overclock", subtitle: "+4% weapon damage", symbol: "bolt.fill", maxLevel: 10,
                    cost: { lv in 8 + lv * 6 }),
        MetaUpgrade(id: "meta_hp", title: "Reinforced Hull", subtitle: "+8 max HP", symbol: "heart.fill", maxLevel: 10,
                    cost: { lv in 6 + lv * 5 }),
        MetaUpgrade(id: "meta_speed", title: "Thrusters", subtitle: "+3% move speed", symbol: "figure.run", maxLevel: 8,
                    cost: { lv in 7 + lv * 5 }),
        MetaUpgrade(id: "meta_magnet", title: "Gravity Well", subtitle: "+6 pickup range", symbol: "scope", maxLevel: 8,
                    cost: { lv in 5 + lv * 4 }),
    ]
}

final class MetaStore: ObservableObject {
    @Published private(set) var cores: Int
    @Published private(set) var bestTime: Int
    @Published private(set) var levels: [String: Int]

    private let ud: UserDefaults
    private let coresKey = "swarm_cores"
    private let bestKey = "swarm_best"
    private let levelsKey = "swarm_meta_levels"

    init(defaults: UserDefaults = .standard) {
        ud = defaults
        cores = ud.integer(forKey: coresKey)
        bestTime = ud.integer(forKey: bestKey)
        levels = (ud.dictionary(forKey: levelsKey) as? [String: Int]) ?? [:]
    }

    func level(for id: String) -> Int { levels[id] ?? 0 }

    func canBuy(_ upgrade: MetaUpgrade) -> Bool {
        let lv = level(for: upgrade.id)
        return lv < upgrade.maxLevel && cores >= upgrade.cost(lv)
    }

    @discardableResult
    func buy(_ upgrade: MetaUpgrade) -> Bool {
        let lv = level(for: upgrade.id)
        guard lv < upgrade.maxLevel else { return false }
        let c = upgrade.cost(lv)
        guard cores >= c else { return false }
        cores -= c
        levels[upgrade.id] = lv + 1
        persist()
        return true
    }

    static func coresForRun(kills: Int, timeSec: Int) -> Int {
        kills + max(1, timeSec / 12)
    }

    @discardableResult
    func awardRun(kills: Int, timeSec: Int) -> Bool {
        let earned = Self.coresForRun(kills: kills, timeSec: timeSec)
        cores += earned
        let newBest = timeSec > bestTime
        if newBest { bestTime = timeSec }
        persist()
        return newBest
    }

    var damageMult: CGFloat { 1 + CGFloat(level(for: "meta_dmg")) * 0.04 }
    var bonusHp: CGFloat { CGFloat(level(for: "meta_hp")) * 8 }
    var speedMult: CGFloat { 1 + CGFloat(level(for: "meta_speed")) * 0.03 }
    var bonusMagnet: CGFloat { CGFloat(level(for: "meta_magnet")) * 6 }

    private func persist() {
        ud.set(cores, forKey: coresKey)
        ud.set(bestTime, forKey: bestKey)
        ud.set(levels, forKey: levelsKey)
    }
}