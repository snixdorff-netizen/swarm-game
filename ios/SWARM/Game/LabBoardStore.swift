// Async lab board — mock co-op detections from field mates (P2#11).

import Foundation

struct LabBoardEvent: Identifiable, Equatable, Codable {
    let id: String
    let mateName: String
    let siteLabel: String
    let speciesCommon: String
    let speciesScientific: String
    let recorder: String
    let timestamp: Date
}

final class LabBoardStore: ObservableObject {
    @Published private(set) var events: [LabBoardEvent]

    private let ud: UserDefaults
    private let key = "swarm_lab_board_v1"

    private static let mates = ["Dr. Chen", "Maya (grad)", "Site B crew", "K. Okonkwo", "Field tech Ana"]
    private static let sites = ["Site A — Canopy", "Site B — Wetland", "Site C — Coastal", "Corridor crossing"]

    init(defaults: UserDefaults = .standard) {
        ud = defaults
        if let data = ud.data(forKey: key),
           let decoded = try? JSONDecoder().decode([LabBoardEvent].self, from: data) {
            events = decoded
        } else {
            events = Self.seedEvents()
        }
    }

    func noteLocalDetection(species: ProjectSpecies, habitat: HabitatSite, deployMode: DeployMode) {
        let event = LabBoardEvent(
            id: "local-\(UUID().uuidString)",
            mateName: "You",
            siteLabel: habitat.title,
            speciesCommon: species.commonName,
            speciesScientific: species.scientificName,
            recorder: deployMode.title,
            timestamp: Date()
        )
        events.insert(event, at: 0)
        trim()
        persist()
        maybeInjectMateEcho(around: species, habitat: habitat)
    }

    private func maybeInjectMateEcho(around species: ProjectSpecies, habitat: HabitatSite) {
        guard events.filter({ $0.mateName != "You" }).count < 12 else { return }
        let seed = UInt64(bitPattern: Int64(species.id.hashValue))
            ^ UInt64(bitPattern: Int64(habitat.rawValue.hashValue))
            ^ UInt64(Date().timeIntervalSince1970)
        var rng = SeededRNG(seed: seed)
        guard rng.nextUnit() < 0.35 else { return }
        let mate = Self.mates[Int(rng.nextUnit() * Double(Self.mates.count)) % Self.mates.count]
        let site = Self.sites[Int(rng.nextUnit() * Double(Self.sites.count)) % Self.sites.count]
        let echo = LabBoardEvent(
            id: "mate-\(UUID().uuidString)",
            mateName: mate,
            siteLabel: site,
            speciesCommon: species.commonName,
            speciesScientific: species.scientificName,
            recorder: rng.nextUnit() < 0.5 ? DeployMode.sm5.title : DeployMode.sm5bat.title,
            timestamp: Date().addingTimeInterval(-Double.random(in: 120...3600))
        )
        events.insert(echo, at: min(2, events.count))
        trim()
        persist()
    }

    private func trim() {
        if events.count > 24 { events = Array(events.prefix(24)) }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(events) {
            ud.set(data, forKey: key)
        }
    }

    private static func seedEvents() -> [LabBoardEvent] {
        let now = Date()
        return [
            LabBoardEvent(id: "seed-1", mateName: "Dr. Chen", siteLabel: "Site B — Wetland",
                          speciesCommon: "American Bullfrog", speciesScientific: "Lithobates catesbeianus",
                          recorder: DeployMode.sm5.title, timestamp: now.addingTimeInterval(-7200)),
            LabBoardEvent(id: "seed-2", mateName: "Maya (grad)", siteLabel: "Site A — Canopy",
                          speciesCommon: "Wood Thrush", speciesScientific: "Hylocichla mustelina",
                          recorder: DeployMode.sm5.title, timestamp: now.addingTimeInterval(-5100)),
        ]
    }
}