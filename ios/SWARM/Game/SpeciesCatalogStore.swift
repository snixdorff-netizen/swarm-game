// Presence/absence species inventory — study notebook across deployments (P1).

import Foundation

struct SpeciesNotebookRecord: Codable, Equatable {
    var count: Int = 0
    var firstSeen: Date?
    var lastSeen: Date?
    var sm5Count: Int = 0
    var sm5batCount: Int = 0
    var deploymentCount: Int = 0
}

struct CatalogEntry: Identifiable, Equatable {
    let species: ProjectSpecies
    let record: SpeciesNotebookRecord
    var id: String { species.id }
    var count: Int { record.count }
    var discovered: Bool { record.count > 0 }
}

final class SpeciesCatalogStore: ObservableObject {
    @Published private(set) var records: [String: SpeciesNotebookRecord]

    private let ud: UserDefaults
    private let key = "swarm_species_notebook_v3"
    private let legacyV2Key = "swarm_species_catalog_v2"
    private static let legacyKey = "swarm_species_catalog"

    init(defaults: UserDefaults = .standard) {
        ud = defaults
        if let data = ud.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: SpeciesNotebookRecord].self, from: data) {
            records = decoded
        } else {
            records = Self.migrateLegacyCounts(from: defaults)
        }
    }

    var entries: [CatalogEntry] {
        ProjectSpeciesCatalog.catalogOrder.map { species in
            CatalogEntry(species: species, record: records[species.id] ?? SpeciesNotebookRecord())
        }
    }

    var discoveredCount: Int {
        entries.filter(\.discovered).count
    }

    func record(_ species: ProjectSpecies, deployMode: DeployMode, at date: Date = Date()) {
        var entry = records[species.id] ?? SpeciesNotebookRecord()
        entry.count += 1
        if entry.firstSeen == nil { entry.firstSeen = date }
        entry.lastSeen = date
        switch deployMode {
        case .sm5: entry.sm5Count += 1
        case .sm5bat: entry.sm5batCount += 1
        }
        records[species.id] = entry
        persist()
    }

    func record(id: String, deployMode: DeployMode, at date: Date = Date()) {
        guard let species = ProjectSpeciesCatalog.with(id: id) else { return }
        record(species, deployMode: deployMode, at: date)
    }

    func markDeploymentRecorded(speciesIds: Set<String>, deployMode: DeployMode, at date: Date = Date()) {
        guard !speciesIds.isEmpty else { return }
        for id in speciesIds {
            var entry = records[id] ?? SpeciesNotebookRecord()
            entry.deploymentCount += 1
            if entry.firstSeen == nil { entry.firstSeen = date }
            entry.lastSeen = date
            records[id] = entry
        }
        persist()
    }

    func count(for species: ProjectSpecies) -> Int {
        records[species.id]?.count ?? 0
    }

    func record(for species: ProjectSpecies) -> SpeciesNotebookRecord {
        records[species.id] ?? SpeciesNotebookRecord()
    }

    private static func migrateLegacyCounts(from defaults: UserDefaults) -> [String: SpeciesNotebookRecord] {
        if let data = defaults.data(forKey: "swarm_species_notebook_v3"),
           let decoded = try? JSONDecoder().decode([String: SpeciesNotebookRecord].self, from: data) {
            return decoded
        }
        if let raw = defaults.dictionary(forKey: "swarm_species_catalog_v2") as? [String: Int], !raw.isEmpty {
            var migrated: [String: SpeciesNotebookRecord] = [:]
            for (id, count) in raw where count > 0 {
                migrated[id] = SpeciesNotebookRecord(count: count, deploymentCount: 1)
            }
            return migrated
        }
        guard let raw = defaults.dictionary(forKey: legacyKey) as? [String: Int], !raw.isEmpty else { return [:] }
        var migrated: [String: SpeciesNotebookRecord] = [:]
        let mapping: [Int: String] = [
            0: "wood_thrush", 1: "blackburnian", 2: "bullfrog", 3: "mockingbird", 9: "little_brown_bat"
        ]
        for (k, v) in raw {
            if let kind = Int(k), let id = mapping[kind], v > 0 {
                migrated[id] = SpeciesNotebookRecord(count: v, deploymentCount: 1)
            }
        }
        return migrated
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) {
            ud.set(data, forKey: key)
        }
    }
}