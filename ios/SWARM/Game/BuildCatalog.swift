// In-run upgrade definitions and pure state application.

import Foundation

struct BuildState: Equatable {
    var boltDmg: CGFloat = 12
    var boltInterval: CGFloat = 0.72
    var boltCount: Int = 1
    var boltPierce: Int = 0
    var orbitLevel: Int = 0
    var orbitDmg: CGFloat = 10
    var novaLevel: Int = 0
    var novaDmg: CGFloat = 16
    var novaRadius: CGFloat = 110
    var novaInterval: CGFloat = 1.6
    var chainLevel: Int = 0
    var chainDmg: CGFloat = 14
    var chainInterval: CGFloat = 1.4
    var leechLevel: Int = 0
    var maxHp: CGFloat = 100
    var moveSpeed: CGFloat = 178
    var pickupRadius: CGFloat = 78
    var regen: CGFloat = 0
    var dmgMult: CGFloat = 1
    var xpMult: CGFloat = 1

    /// Estimated single-target DPS for simulation (bolts + passive weapons).
    func estimatedDPS(enemyCount: Int) -> CGFloat {
        let boltDPS = (boltDmg * dmgMult * CGFloat(boltCount)) / max(0.18, boltInterval)
        let novaDPS = novaLevel > 0 ? (novaDmg * dmgMult * CGFloat(novaLevel)) / max(0.6, novaInterval) * 0.65 : 0
        let chainDPS = chainLevel > 0 ? (chainDmg * dmgMult * CGFloat(2 + chainLevel)) / max(0.5, chainInterval) * 0.5 : 0
        let orbitDPS = orbitLevel > 0 ? orbitDmg * dmgMult * CGFloat(orbitLevel + 1) * 0.35 : 0
        let horde = max(1, CGFloat(min(enemyCount, 40)))
        return (boltDPS + novaDPS + chainDPS + orbitDPS) * min(1.4, 0.75 + horde * 0.02)
    }

    mutating func apply(upgradeId: String) {
        switch upgradeId {
        case "bolt_dmg": boltDmg += 7
        case "bolt_rate": boltInterval = max(0.18, boltInterval * 0.82)
        case "bolt_count": boltCount += 1
        case "bolt_pierce": boltPierce += 1
        case "orbit":
            if orbitLevel == 0 { orbitLevel = 1 } else { orbitLevel += 1 }
        case "orbit_dmg": orbitDmg += 8
        case "nova":
            if novaLevel == 0 { novaLevel = 1 } else { novaLevel += 1 }
            novaInterval = max(0.6, novaInterval * 0.85)
        case "nova_radius": novaRadius += 34
        case "chain":
            if chainLevel == 0 { chainLevel = 1 } else { chainLevel += 1 }
            chainInterval = max(0.5, chainInterval * 0.88)
        case "chain_dmg": chainDmg += 9
        case "leech":
            if leechLevel == 0 { leechLevel = 1 } else { leechLevel += 1 }
        case "max_hp": maxHp += 25
        case "move": moveSpeed += 22
        case "pickup": pickupRadius += 36
        case "regen": regen += 1.4
        default: break
        }
    }

    static func preferredUpgrade(for profile: BuildProfile) -> String {
        switch profile {
        case .baseline: return "bolt_dmg"
        case .novaRush: return "nova"
        case .chainArc: return "chain"
        case .leechTank: return "leech"
        case .metaBoosted: return "bolt_dmg"
        }
    }
}

enum BuildProfile: String, CaseIterable {
    case baseline, novaRush, chainArc, leechTank, metaBoosted
}