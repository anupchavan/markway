import SwiftUI

enum MarkwayTheme {
    static let bluePaper = Color(hex: 0xEFF3ED)
    static let blue50 = Color(hex: 0xE1ECEB)
    static let blue100 = Color(hex: 0xC6DDE8)
    static let blue200 = Color(hex: 0x92BFDB)
    static let blue500 = Color(hex: 0x3171B2)
    static let blue600 = Color(hex: 0x205EA6)
    static let blue700 = Color(hex: 0x1A4F8C)
    static let blue850 = Color(hex: 0x133051)
    static let blue900 = Color(hex: 0x12253B)
    static let blue950 = Color(hex: 0x101A24)
    static let blueBlack = Color(hex: 0x10151A)

    static func windowBackground(_ scheme: ColorScheme) -> LinearGradient {
        let colors = scheme == .dark
            ? [blueBlack, blue950, blue900]
            : [bluePaper, Color.white, blue50]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func sidebarBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? blueBlack.opacity(0.58) : Color.white.opacity(0.46)
    }

    static func selectedTabBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? blue850.opacity(0.68) : blue100.opacity(0.7)
    }

    static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? blue200 : blue600
    }

    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? blue950.opacity(0.58) : Color.white.opacity(0.72)
    }
}

extension Color {
    init(hex: Int) {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double(hex & 0xff) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

struct GlassPanel: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background(MarkwayTheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
            .shadow(color: shadowColor, radius: 24, y: 18)
    }

    private var borderColor: Color {
        scheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.62)
    }

    private var shadowColor: Color {
        scheme == .dark ? Color.black.opacity(0.22) : MarkwayTheme.blue700.opacity(0.08)
    }
}

extension View {
    func glassPanel() -> some View {
        modifier(GlassPanel())
    }
}
