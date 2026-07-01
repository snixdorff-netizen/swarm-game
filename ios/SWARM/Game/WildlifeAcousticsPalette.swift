// Brand colors sourced from wildlifeacoustics.com (site CSS design tokens, 2026).
// Fan-project palette — not an official brand asset.

import SpriteKit
import SwiftUI

enum WildlifeAcousticsPalette {
    static let navy = "#152931"
    static let blue = "#2183fc"
    static let blueLight = "#e1eeff"
    static let olive = "#546235"
    static let oliveDark = "#333d1d"
    static let green = "#4e5b31"
    static let brown = "#4b3d2a"
    static let gold = "#bc955c"
    static let cream = "#ecd2ab"
    static let pearl = "#e0e2dd"
    static let red = "#e1251b"
    static let redHover = "#aa1f2e"
    static let gray = "#58595b"

    static func swiftUI(_ hex: String, opacity: Double = 1) -> Color {
        let (r, g, b) = rgb(hex)
        return Color(red: r, green: g, blue: b, opacity: opacity)
    }

    static func sk(_ hex: String, alpha: CGFloat = 1) -> SKColor {
        let (r, g, b) = rgb(hex)
        return SKColor(red: r, green: g, blue: b, alpha: alpha)
    }

    private static func rgb(_ hex: String) -> (CGFloat, CGFloat, CGFloat) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: h).scanHexInt64(&value)
        let r, g, b: CGFloat
        switch h.count {
        case 6:
            r = CGFloat((value & 0xFF0000) >> 16) / 255
            g = CGFloat((value & 0x00FF00) >> 8) / 255
            b = CGFloat(value & 0x0000FF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        return (r, g, b)
    }
}