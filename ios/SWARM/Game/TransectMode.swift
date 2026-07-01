// Transect length profile — coffee-break slice vs full field-day protocol (P3).

import Foundation

enum TransectMode: String, CaseIterable, Codable, Equatable {
    case coffeeBreak
    case fieldDay

    var title: String {
        switch self {
        case .coffeeBreak: return "Coffee Break"
        case .fieldDay: return "Field Day"
        }
    }

    var subtitle: String {
        switch self {
        case .coffeeBreak: return "8-min transect — quick survey slice"
        case .fieldDay: return "Full deployment — 8–12 min protocol"
        }
    }

    var symbol: String {
        switch self {
        case .coffeeBreak: return "cup.and.saucer.fill"
        case .fieldDay: return "sun.horizon.fill"
        }
    }

    /// Hard cap on transect duration for this profile.
    var durationCapSec: Int {
        switch self {
        case .coffeeBreak: return 480
        case .fieldDay: return 720
        }
    }
}

struct DeploymentContext: Equatable, Codable {
    let deploymentId: String
    let siteLabel: String
    let recorderProfile: String
    let transectMode: TransectMode
    let habitat: HabitatSite
    let deployMode: DeployMode

    static func fresh(
        deployMode: DeployMode,
        habitat: HabitatSite,
        transectMode: TransectMode,
        seed: UInt64
    ) -> DeploymentContext {
        DeploymentContext(
            deploymentId: String(format: "DEP-%08X", seed),
            siteLabel: habitat.title,
            recorderProfile: deployMode.title,
            transectMode: transectMode,
            habitat: habitat,
            deployMode: deployMode
        )
    }
}

enum VoucherClipNaming {
    static func filename(speciesId: String, sequence: Int, deploymentId: String) -> String {
        let dep = deploymentId.replacingOccurrences(of: "DEP-", with: "")
        return "SWARM_\(speciesId)_\(dep)_\(String(format: "%03d", sequence)).wav"
    }
}