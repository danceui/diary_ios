import SwiftUI

enum PaletteStyle: String, CaseIterable, Identifiable {
    case monochrome = "Black & White"
    case maillard   = "Maillard"
    case vibrant    = "Vibrant"
    case pastel     = "Pastel"
    case highlighter = "Highlighter"
    var id: String { rawValue }
}

struct Palette {
    static let colors: [PaletteStyle: [Color]] = [
        .monochrome: [
            .black, .gray.opacity(0.9), .gray.opacity(0.7),
            .gray.opacity(0.5), .gray.opacity(0.3), .white
        ],
        .maillard: [            // warm, roasted browns
            Color(hex: 0x3B2F2F), // dark cocoa
            Color(hex: 0x5C4033), // mocha
            Color(hex: 0x7B4F35), // toasted
            Color(hex: 0xA97155), // caramel
            Color(hex: 0xC8875E), // toffee
            Color(hex: 0xE0AD87)  // latte foam
        ],
        .vibrant: [
            Color(hex: 0xFF3B30), Color(hex: 0xFF9500), Color(hex: 0xFFCC00),
            Color(hex: 0x34C759), Color(hex: 0x007AFF), Color(hex: 0x5856D6)
        ],
        .pastel: [
            Color(hex: 0xFFC1CC), Color(hex: 0xFFE5B4), Color(hex: 0xFFF6A3),
            Color(hex: 0xC9F0C5), Color(hex: 0xC9E9FF), Color(hex: 0xD9CCFF)
        ],
        .highlighter: [ // looks nice with opacity < 1
            Color(hex: 0xFFF352), Color(hex: 0x9BFF61), Color(hex: 0x6DFFFB),
            Color(hex: 0xA6A1FF), Color(hex: 0xFF9DF3), Color(hex: 0xFFB26B)
        ],
    ]
}

struct StyleDetailsKey: Hashable {
    let tool: Tool
    let index: Int
}
extension Color {
    /// Hex like 0xRRGGBB
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8)  & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    func withOpacity(_ value: Double) -> Color {
        self.opacity(value)
    }

    // simple equivalence check on RGBA rendered description
    func matches(_ other: Color) -> Bool {
        String(describing: self) == String(describing: other)
    }
}