import AppKit
import XCTest
@testable import Codenotch

@MainActor
final class HapticFeedbackTests: XCTestCase {
    func testFullPlaysEveryRequestedInteraction() {
        var patterns: [NSHapticFeedbackManager.FeedbackPattern] = []
        var time: TimeInterval = 1
        let service = HapticFeedbackService(
            reduceMotion: { false }, now: { time }, perform: { patterns.append($0) }
        )

        let events: [CodenotchHapticEvent] = [
            .enteredNotch, .providerChanged, .expanded, .tooltipHovered,
            .providerRefreshRequested, .manualRefreshSucceeded
        ]
        for event in events {
            service.play(event)
            time += 0.1
        }

        XCTAssertEqual(patterns.count, events.count)
    }

    func testMinimalKeepsOnlyDeliberateRefreshConfirmations() {
        var patterns: [NSHapticFeedbackManager.FeedbackPattern] = []
        var time: TimeInterval = 1
        let service = HapticFeedbackService(
            detailLevel: .minimal,
            reduceMotion: { false }, now: { time }, perform: { patterns.append($0) }
        )

        for event in [CodenotchHapticEvent.enteredNotch, .providerChanged, .expanded,
                      .tooltipHovered, .providerRefreshRequested, .manualRefreshSucceeded] {
            service.play(event)
            time += 0.1
        }

        XCTAssertEqual(patterns, [.generic, .levelChange])
    }

    func testReduceMotionUsesTheMinimalInteractionSet() {
        var patterns: [NSHapticFeedbackManager.FeedbackPattern] = []
        let service = HapticFeedbackService(
            reduceMotion: { true }, perform: { patterns.append($0) }
        )

        service.play(.expanded)
        service.play(.providerRefreshRequested)

        XCTAssertEqual(patterns, [.generic])
    }

    func testDisabledAndRepeatedEventsDoNotPlay() {
        var count = 0
        var time: TimeInterval = 1
        let service = HapticFeedbackService(
            isEnabled: false, reduceMotion: { false }, now: { time }, perform: { _ in count += 1 }
        )
        service.play(.enteredNotch)
        service.isEnabled = true
        service.play(.enteredNotch)
        time += 0.01
        service.play(.enteredNotch)

        XCTAssertEqual(count, 1)
    }
}
