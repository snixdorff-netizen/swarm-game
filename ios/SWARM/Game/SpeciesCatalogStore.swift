// Presence/absence species inventory — Kaleidoscope-style catalog across deployments.

import Foundation

struct CatalogEntry: Identifiable, Equatable {
    let species: SurveySpecies
    let count: Int
    var id: Int { species.rawValue }

    var discovered: Bool { count > 0 }
}

final class SpeciesCatalogStore: ObservableObject {
    @Published private(set) var counts: [Int: Int]

    private let ud: UserDefaults
    private let key = "swarm_species_catalog"

    init(defaults: UserDefaults = .standard) {
        ud = defaults
        if let raw = ud.dictionary(forKey: key) as? [String: Int] {
            counts = Dictionary(uniqueKeysWithValues: raw.compactMap { k, v in
                guard let id = Int(k) else { return nil }
                return (id, v)
            })
        } else {
            counts = [:]
        }
    }

    var entries: [CatalogEntry] {
        SurveySpecies.catalogOrder.map { species in
            CatalogEntry(species: species, count: counts[species.rawValue] ?? 0)
        }
    }

    var discoveredCount: Int {
        entries.filter(\.discovered).count
    }

    func record(_ species: SurveySpecies) {
        let id = species.rawValue
        counts[id, default: 0] += 1
        persist()
    }

    func count(for species: SurveySpecies) -> Int {
        counts[species.rawValue] ?? 0
    }

    private func persist() {
        let raw = Dictionary(uniqueKeysWithValues: counts.map { (String($0.key), $0.value) })
        ud.set(raw, forKey: key)
    }
}

extension SurveySpecies {
    static let catalogOrder: [SurveySpecies] = [.passerine, .swift, .resonant, .mimic, .endangered]
}