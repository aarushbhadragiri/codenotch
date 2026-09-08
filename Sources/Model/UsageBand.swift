import SwiftUI

/// The colour a ring or bar takes at a given level of use.
///
/// The thresholds come from the mockup, which shows 21% green, 52% yellow and
/// 73% orange. (The prose table in the design spec says 50–79 is yellow, which
/// would make 73% yellow and contradict the frame it claims to describe — the
/// frame wins.)
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

    /// `accent` only ever stands in for the ample state's colour — the
    /// warning bands stay fixed regardless of the chosen accent, since their
    /// whole job is to interrupt whatever else is on screen and a
    /// customisable warning colour could be tuned into invisibility.
    func color(accent: Color = Palette.ample) -> Color {
        switch self {
        case .ample:                 return accent
        case .watch:                 return Palette.watch
        case .critical, .exhausted:  return Palette.critical
        }
    }

    /// Provider usage indicators are identity indicators, not warnings. Rings
    /// and tooltip bars stay in the chosen accent throughout the usable range
    /// and become white only when the reported limit is fully exhausted.
    static func usageIndicatorColor(for usedFraction: Double, accent: Color) -> Color {
        usedFraction >= 1 ? Palette.textPrimary : accent
    }
}
