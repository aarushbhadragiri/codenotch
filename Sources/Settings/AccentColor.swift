import AppKit
import SwiftUI

/// The user-selected colour for positive usage and active work indicators.
///
/// Raw values are persistence keys, not display copy. Keeping them stable lets
/// labels and ordering change without losing an existing choice.
enum AccentColorChoice: String, CaseIterable, Identifiable {
    case system
    case pink = "ff33e1"
    case red = "eb4236"
    case blue = "36a8eb"
    case orange = "eb8436"
    case offWhite = "f7f6f5"
    case green = "00ff88"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:   return "Device accent color"
        case .pink:     return "#FF33E1"
        case .red:      return "#EB4236"
        case .blue:     return "#36A8EB"
        case .orange:   return "#EB8436"
        case .offWhite: return "#F7F6F5"
        case .green:    return "#00FF88"
        }
    }

    var color: Color {
        switch self {
        case .system:   return Color(nsColor: .controlAccentColor)
        case .pink:     return Color(hex: 0xFF33E1)
        case .red:      return Color(hex: 0xEB4236)
        case .blue:     return Color(hex: 0x36A8EB)
        case .orange:   return Color(hex: 0xEB8436)
        case .offWhite: return Color(hex: 0xF7F6F5)
        case .green:    return Palette.ample
        }
    }
}

private struct CodenotchAccentColorKey: EnvironmentKey {
    static let defaultValue = Color(nsColor: .controlAccentColor)
}

extension EnvironmentValues {
    var codenotchAccentColor: Color {
        get { self[CodenotchAccentColorKey.self] }
        set { self[CodenotchAccentColorKey.self] = newValue }
    }
}
