// Presence/absence species inventory — Kaleidoscope-style catalog across deployments.

import Foundation

struct CatalogEntry: Identifiable, Equatable {
    let species: ProjectSpecies
    let count: Int
    var id: String { species.id }

    var discovered: Bool { count > 0 }
}

final class SpeciesCatalogStore: ObservableObject {
    @Published private(set) var counts: [String: Int]

    private let ud: UserDefaults
    private let key = "swarm_species_catalog_v2"
    private static let legacyKey = "swarm_species_catalog"

    init(defaults: UserDefaults = .standard) {
        ud = defaults
        if let raw = ud.dictionary(forKey: key) as? [String: Int] {
            counts = raw
        } else {
            counts = Self.migrateLegacyCounts(from: defaults)
        }
    }

    var entries: [CatalogEntry] {
        ProjectSpeciesCatalog.catalogOrder.map { species in
            CatalogEntry(species: species, count: counts[species.id] ?? 0)
        }
    }

    var discoveredCount: Int {
        entries.filter(\.discovered).count
    }

    func record(_ species: ProjectSpecies) {
        counts[species.id, default: 0] += 1
        persist()
    }

    func record(id: String) {
        guard ProjectSpeciesCatalog.with(id: id) != nil else { return }
        counts[id, default: 0] += 1
        persist()
    }

    func count(for species: ProjectSpecies) -> Int {
        counts[species.id] ?? 0
    }

    private static func migrateLegacyCounts(from defaults: UserDefaults) -> [String: Int] {
        guard let raw = defaults.dictionary(forKey: Self.legacyKey) as? [String: Int], !raw.isEmpty else { return [:] }
        var migrated: [String: Int] = [:]
        let mapping: [Int: String] = [
            0: "wood_thrush", 1: "blackburnian", 2: "bullfrog", 3: "mockingbird", 9: "little_brown_bat"
        ]
        for (k, v) in raw {
            if let kind = Int(k), let id = mapping[kind] { migrated[id, default: 0] += v }
        }
        return migrated
    }

    private func persist() {
        ud.set(counts, forKey: key)
    }
}