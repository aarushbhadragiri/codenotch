import SwiftUI

/// The state a ring or bar enters at a given level of use.
///
/// The thresholds still drive exhausted-state treatment and leave room for
/// other urgency cues, but colour belongs to the user's accent choice until a
/// limit is completely spent. Exhausted usage turns white so it remains clear
/// without replacing the chosen identity colour with a warning palette.
enum UsageBand: Equatable {
    case ample       // under half
    case watch       // getting close
    case critical    // nearly out
    case exhausted   // limit hit, waiting for the reset

    static func band(for usedFraction: Double) -> UsageBand {
        switch usedFraction {
        case ..<0.50: return .ample
        case ..<0.70: return .watch
        case ..<1.00: return .critical
        default:      return .exhausted
        }
    }

    func color(accent: Color = Palette.ample) -> Color {
        switch self {
        case .ample, .watch, .critical: return accent
        case .exhausted:                 return Palette.textPrimary
        }
    }
}
