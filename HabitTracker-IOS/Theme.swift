import SwiftUI

enum Theme {
    static let background = Color(hex: "#FAFAF7")!
    static let surface = Color(hex: "#FFFFFF")!
    static let textPrimary = Color(hex: "#0A0A0A")!
    static let textSecondary = Color(hex: "#8A8580")!
    static let divider = Color(hex: "#EAE7E1")!
    static let accent = Color(hex: "#0A0A0A")!
}

extension Font {
    static func display() -> Font {
        .system(size: 40, weight: .medium, design: .serif)
    }
    static func title() -> Font {
        .system(size: 22, weight: .medium, design: .serif)
    }
    static func body_() -> Font {
        .system(size: 16, weight: .regular)
    }
    static func small() -> Font {
        .system(size: 13, weight: .regular)
    }
}

extension Color {
    init?(hex: String) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("#") { str.removeFirst() }
        guard str.count == 6, let value = UInt64(str, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
