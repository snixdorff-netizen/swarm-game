// Captured outcome from a real GameScene-driven run (testing / evidence).

import Foundation

struct GameSceneRunSummary: Codable, Equatable {
    let survivalSec: Int
    let kills: Int
    let level: Int
    let died: Bool
    let bossSpawned: Bool
    let milestone30: Bool
    let milestone60: Bool
    let finalHp: Int
    let qaAutopilotImmune: Bool
}

enum GameSceneRunEvidenceExporter {
    static let goalScratch = "/var/folders/jc/vlt38jc172b76pd4lmy9ch340000gn/T/grok-goal-a3a70e15315e/implementer"

    static func export(_ runs: [GameSceneRunSummary], filename: String = "mortal-run-evidence.json") throws -> URL {
        let dir = URL(fileURLWithPath: goalScratch, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(filename)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try enc.encode(runs).write(to: url)
        return url
    }
}