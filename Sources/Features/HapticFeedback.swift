import AppKit
import Foundation

enum HapticDetailLevel: String, CaseIterable, Identifiable {
    case minimal
    case full

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// Meaningful interaction events, kept separate from AppKit's three physical
/// patterns so callers describe what happened rather than choosing a motor
/// effect themselves.
enum CodenotchHapticEvent: Hashable {
    case enteredNotch
    case providerChanged
    case expanded
    case tooltipHovered
    case providerRefreshRequested
    case manualRefreshSucceeded

    fileprivate var pattern: NSHapticFeedbackManager.FeedbackPattern {
        switch self {
        case .enteredNotch, .providerChanged, .tooltipHovered:
            return .alignment
        case .expanded, .providerRefreshRequested:
            return .generic
        case .manualRefreshSucceeded:
            return .levelChange
        }
    }

    /// Minimal keeps deliberate confirmations and removes pointer-driven
    /// chatter. Reduce Motion uses the same conservative subset.
    fileprivate var isDeliberateConfirmation: Bool {
        switch self {
        case .providerRefreshRequested, .manualRefreshSucceeded: return true
        case .enteredNotch, .providerChanged, .expanded, .tooltipHovered: return false
        }
    }
}

/// The system performer silently does nothing when the Mac has no compatible
/// Force Touch trackpad. No device probing or permission is required.
@MainActor
final class HapticFeedbackService {
    var isEnabled: Bool
    var detailLevel: HapticDetailLevel

    private let reduceMotion: () -> Bool
    private let perform: (NSHapticFeedbackManager.FeedbackPattern) -> Void
    private let now: () -> TimeInterval
    private var lastPlayed: [CodenotchHapticEvent: TimeInterval] = [:]

    init(
        isEnabled: Bool = true,
        detailLevel: HapticDetailLevel = .full,
        reduceMotion: @escaping () -> Bool = {
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        },
        now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        perform: @escaping (NSHapticFeedbackManager.FeedbackPattern) -> Void = { pattern in
            NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
        }
    ) {
        self.isEnabled = isEnabled
        self.detailLevel = detailLevel
        self.reduceMotion = reduceMotion
        self.now = now
        self.perform = perform
    }

    func play(_ event: CodenotchHapticEvent) {
        guard isEnabled else { return }
        if detailLevel == .minimal || reduceMotion() {
            guard event.isDeliberateConfirmation else { return }
        }

        // Cursor polling can observe the same boundary several times. A short
        // per-event gate keeps one physical action from becoming a buzz.
        let timestamp = now()
        guard timestamp - (lastPlayed[event] ?? -.infinity) >= 0.08 else { return }
        lastPlayed[event] = timestamp
        perform(event.pattern)
    }
}
