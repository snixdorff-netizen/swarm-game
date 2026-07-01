// Citizen science / analysis-pipeline CSV export (P2#13).

import Foundation

enum CitizenScienceExporter {
    static let pipelineVersion = "swarm-csv/1.0"

    static func catalogCSV(catalog: SpeciesCatalogStore, habitat: HabitatSite) -> String {
        let iso = ISO8601DateFormatter()
        var rows = [
            "# SWARM citizen science export — compatible with analysis pipeline ingest",
            "# pipeline_version,\(pipelineVersion)",
            "# habitat_site,\(habitat.rawValue)",
            "# exported_at,\(iso.string(from: Date()))",
            "species_id,common_name,scientific_name,detection_count,deployment_count,sm5_count,sm5bat_count,first_seen,last_seen,presence",
        ]
        for entry in catalog.entries {
            let rec = entry.record
            let first = rec.firstSeen.map { iso.string(from: $0) } ?? ""
            let last = rec.lastSeen.map { iso.string(from: $0) } ?? ""
            rows.append([
                csv(entry.species.id),
                csv(entry.species.commonName),
                csv(entry.species.scientificName),
                "\(rec.count)",
                "\(rec.deploymentCount)",
                "\(rec.sm5Count)",
                "\(rec.sm5batCount)",
                csv(first),
                csv(last),
                entry.discovered ? "present" : "absent",
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    static func metadataJSON(habitat: HabitatSite, deployMode: DeployMode, catalog: SpeciesCatalogStore) -> String {
        let payload: [String: Any] = [
            "pipeline_version": pipelineVersion,
            "habitat_site": habitat.rawValue,
            "recorder_profile": deployMode.rawValue,
            "species_richness": catalog.discoveredCount,
            "exported_at": ISO8601DateFormatter().string(from: Date()),
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    private static func csv(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}