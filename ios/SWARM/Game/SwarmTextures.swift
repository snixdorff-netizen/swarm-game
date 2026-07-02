// Generated art assets for SWARM Acoustic Field (bioacoustics-themed sprites).

import SpriteKit
import SwiftUI

enum SwarmTextures {
    static let songMeter = "SongMeterPlayer"
    static let vocalization = "VocalizationPulse"
    static let recordingClip = "RecordingClipGem"
    static let fieldBackground = "FieldBackground"

    static func sk(_ name: String) -> SKTexture {
        SKTexture(imageNamed: name)
    }

    static var songMeterTexture: SKTexture { sk(songMeter) }
    static var vocalizationTexture: SKTexture { sk(vocalization) }
    static var recordingClipTexture: SKTexture { sk(recordingClip) }
    static var fieldBackgroundTexture: SKTexture { sk(fieldBackground) }
}