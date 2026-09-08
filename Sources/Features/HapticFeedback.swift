import AppKit
import Foundation

enum HapticDetailLevel: String, CaseIterable, Identifiable {
    case minimal
    case full

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum HapticStrength: Hashable { case medium, strong }

enum CodenotchHapticEvent: Hashable {
    case enteredNotch
    case providerChanged
    case settingsOpened
    case sliderBoundary
    case integrationToggled
    case refreshRequested
    case dragBump(HapticStrength)

    var isPointerDriven: Bool {
        switch self {
        case .enteredNotch, .providerChanged, .dragBump: true
        default: false
        }
    }

    var pattern: NSHapticFeedbackManager.FeedbackPattern {
        switch self {
        case .enteredNotch, .providerChanged, .sliderBoundary, .integrationToggled: .alignment
        case .settingsOpened, .refreshRequested, .dragBump(.medium): .levelChange
        case .dragBump(.strong): .generic
        }
    }
}

@MainActor
final class HapticFeedbackService {
    static let shared = HapticFeedbackService()

    var isEnabled: Bool
    var detailLevel: HapticDetailLevel

    private let reduceMotion: () -> Bool
    private let perform: (NSHapticFeedbackManager.FeedbackPattern) -> Void
    private let now: () -> TimeInterval
    private let schedule: (TimeInterval, @escaping () -> Void) -> Void
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
        },
        schedule: @escaping (TimeInterval, @escaping () -> Void) -> Void = { delay, action in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
        }
    ) {
        self.isEnabled = isEnabled
        self.detailLevel = detailLevel
        self.reduceMotion = reduceMotion
        self.perform = perform
        self.now = now
        self.schedule = schedule
    }

    func play(_ event: CodenotchHapticEvent) {
        guard isEnabled else { return }
        if detailLevel == .minimal || reduceMotion() {
            guard !event.isPointerDriven else { return }
        }
        let timestamp = now()
        guard timestamp - (lastPlayed[event] ?? -.infinity) >= interval(for: event) else { return }
        lastPlayed[event] = timestamp
        perform(event.pattern)
    }

    func playDragBump(speed: CGFloat) {
        play(.dragBump(speed >= 900 ? .strong : .medium))
    }

    func playRefreshCompletion(usedFraction: Double?) {
        guard isEnabled, let usedFraction else { return }
        let count: Int
        let pattern: NSHapticFeedbackManager.FeedbackPattern
        switch usedFraction {
        case 1...: count = 3; pattern = .generic
        case 0.75..<1: count = 3; pattern = .levelChange
        case 0.5.nextUp..<0.75: count = 2; pattern = .levelChange
        default: count = 1; pattern = .levelChange
        }
        for index in 0..<count {
            schedule(0.15 + Double(index) * 0.11) { [weak self] in
                guard let self, self.isEnabled else { return }
                self.perform(pattern)
            }
        }
    }

    private func interval(for event: CodenotchHapticEvent) -> TimeInterval {
        switch event {
        case .dragBump(.strong): 0.035
        case .dragBump(.medium): 0.075
        case .providerChanged: 0.08
        default: 0.12
        }
    }
}
