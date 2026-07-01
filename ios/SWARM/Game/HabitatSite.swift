// Season / habitat briefing — species pools per survey site (P2#15).

import Foundation

enum HabitatSite: String, CaseIterable, Codable, Equatable {
    case canopy
    case wetland
    case coastal

    var title: String {
        switch self {
        case .canopy: return "Canopy Transect"
        case .wetland: return "Wetland Edge"
        case .coastal: return "Coastal Marsh"
        }
    }

    var subtitle: String {
        switch self {
        case .canopy: return "Forest songbirds · dawn chorus"
        case .wetland: return "Amphibian + owl low-band"
        case .coastal: return "Marsh passerines + waterbirds"
        }
    }

    var symbol: String {
        switch self {
        case .canopy: return "tree.fill"
        case .wetland: return "drop.fill"
        case .coastal: return "water.waves"
        }
    }

    /// Project species IDs favored at this site.
    var speciesPool: [String] {
        switch self {
        case .canopy:
            return ["wood_thrush", "ovenbird", "scarlet_tanager", "blackburnian", "barred_owl", "mockingbird"]
        case .wetland:
            return ["bullfrog", "barred_owl", "redwing", "wood_thrush", "mockingbird", "cedar_waxwing"]
        case .coastal:
            return ["redwing", "cedar_waxwing", "mockingbird", "scarlet_tanager", "ovenbird", "bullfrog"]
        }
    }

    static func pickSpecies(archetype: Int, roll: CGFloat, habitat: HabitatSite) -> ProjectSpecies {
        let poolIds = habitat.speciesPool
        let pool = poolIds.compactMap { ProjectSpeciesCatalog.with(id: $0) }
            + ProjectSpeciesCatalog.all.filter { $0.archetype == archetype }
        let archetypeMatches = pool.filter { $0.archetype == archetype }
        let candidates = archetypeMatches.isEmpty ? pool : archetypeMatches
        guard !candidates.isEmpty else { return ProjectSpeciesCatalog.all[0] }
        let idx = min(candidates.count - 1, Int(roll * CGFloat(candidates.count)))
        return candidates[idx]
    }
}