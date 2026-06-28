import SwiftUI

// Design tokens — approximation of RN `src/theme.ts` (dark app background, light cards).
// 가정: exact RN hex values not ported 1:1; close palette for parity.
enum Theme {
    static let bg = Color(hex: 0x0F172A)
    static let bgCard = Color(hex: 0x1E293B)
    static let bgElev = Color(hex: 0x334155)
    static let border = Color(hex: 0x334155)
    static let text = Color.white
    static let textMuted = Color(hex: 0x94A3B8)
    static let accent = Color(hex: 0x5B8DEF)

    // Per-part colors (mirror RN home PARTS).
    static let partColors: [Int: Color] = [
        1: Color(hex: 0x5B8DEF), 2: Color(hex: 0x7C6CF0), 3: Color(hex: 0x2BB3A3),
        4: Color(hex: 0xE0A13C), 5: Color(hex: 0xE06C9F), 6: Color(hex: 0x6AA84F),
        7: Color(hex: 0xC0763E),
    ]
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
    /// Parse a "#rrggbb" string (from Analysis segments). Falls back to gray.
    init(css: String) {
        let s = css.hasPrefix("#") ? String(css.dropFirst()) : css
        if let v = UInt32(s, radix: 16), s.count == 6 { self.init(hex: v) }
        else { self = .gray }
    }
}

/// TOEIC part catalog (RN home PARTS). LC = 1–4, RC = 5–7.
struct PartInfo: Identifiable {
    let p: Int
    let title: String
    let desc: String
    let icon: String
    var id: Int { p }
    var color: Color { Theme.partColors[p] ?? Theme.accent }
}

let TOEIC_PARTS: [PartInfo] = [
    .init(p: 1, title: "Part 1", desc: "사진묘사", icon: "📷"),
    .init(p: 2, title: "Part 2", desc: "질의응답", icon: "💬"),
    .init(p: 3, title: "Part 3", desc: "대화", icon: "🗣️"),
    .init(p: 4, title: "Part 4", desc: "담화", icon: "📢"),
    .init(p: 5, title: "Part 5", desc: "문장완성", icon: "✍️"),
    .init(p: 6, title: "Part 6", desc: "지문완성", icon: "📄"),
    .init(p: 7, title: "Part 7", desc: "독해", icon: "📚"),
]
