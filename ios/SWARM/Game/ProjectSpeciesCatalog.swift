// Project species list — regional survey targets with scientific names.

import Foundation

struct ProjectSpecies: Identifiable, Equatable, Codable {
    let id: String
    let commonName: String
    let scientificName: String
    let bandLabel: String
    let callBand: CallBand
    /// Maps to EnemyKind raw value for combat stats.
    let archetype: Int

    var displayLine: String { "\(commonName) (\(scientificName))" }
}

enum ProjectSpeciesCatalog {
    static let all: [ProjectSpecies] = [
        ProjectSpecies(id: "wood_thrush", commonName: "Wood Thrush", scientificName: "Hylocichla mustelina",
                       bandLabel: "2–5 kHz flute song", callBand: .acoustic, archetype: 0),
        ProjectSpecies(id: "ovenbird", commonName: "Ovenbird", scientificName: "Seiurus aurocapilla",
                       bandLabel: "3–7 kHz teacher call", callBand: .acoustic, archetype: 0),
        ProjectSpecies(id: "scarlet_tanager", commonName: "Scarlet Tanager", scientificName: "Piranga olivacea",
                       bandLabel: "2–8 kHz burry phrases", callBand: .acoustic, archetype: 0),
        ProjectSpecies(id: "blackburnian", commonName: "Blackburnian Warbler", scientificName: "Setophaga fusca",
                       bandLabel: "4–10 kHz thin trill", callBand: .acoustic, archetype: 1),
        ProjectSpecies(id: "cedar_waxwing", commonName: "Cedar Waxwing", scientificName: "Bombycilla cedrorum",
                       bandLabel: "5–12 kHz high buzz", callBand: .acoustic, archetype: 1),
        ProjectSpecies(id: "bullfrog", commonName: "American Bullfrog", scientificName: "Lithobates catesbeianus",
                       bandLabel: "80–300 Hz jug-o-rum", callBand: .acoustic, archetype: 2),
        ProjectSpecies(id: "barred_owl", commonName: "Barred Owl", scientificName: "Strix varia",
                       bandLabel: "120–500 Hz who-cooks", callBand: .acoustic, archetype: 2),
        ProjectSpecies(id: "mockingbird", commonName: "Northern Mockingbird", scientificName: "Mimus polyglottos",
                       bandLabel: "Variable mimic", callBand: .acoustic, archetype: 3),
        ProjectSpecies(id: "redwing", commonName: "Red-winged Blackbird", scientificName: "Agelaius phoeniceus",
                       bandLabel: "1–4 kHz conk-a-ree", callBand: .acoustic, archetype: 3),
        ProjectSpecies(id: "little_brown_bat", commonName: "Little Brown Bat", scientificName: "Myotis lucifugus",
                       bandLabel: "25–60 kHz†", callBand: .ultrasonic, archetype: 9),
        ProjectSpecies(id: "hoary_bat", commonName: "Hoary Bat", scientificName: "Lasiurus cinereus",
                       bandLabel: "20–45 kHz†", callBand: .ultrasonic, archetype: 9),
        ProjectSpecies(id: "big_brown_bat", commonName: "Big Brown Bat", scientificName: "Eptesicus fuscus",
                       bandLabel: "30–80 kHz†", callBand: .ultrasonic, archetype: 9),
    ]

    static var catalogOrder: [ProjectSpecies] { all }

    static func with(id: String) -> ProjectSpecies? {
        all.first { $0.id == id }
    }

    static func pick(archetype: Int, roll: CGFloat) -> ProjectSpecies {
        let pool = all.filter { $0.archetype == archetype }
        guard !pool.isEmpty else { return all[0] }
        let idx = min(pool.count - 1, Int(roll * CGFloat(pool.count)))
        return pool[idx]
    }

    /// Legacy bridge for species call synthesis.
    static func surveySpecies(for project: ProjectSpecies) -> SurveySpecies {
        switch project.archetype {
        case 1: return .swift
        case 2: return .resonant
        case 3: return .mimic
        case 9: return .endangered
        default: return .passerine
        }
    }
}