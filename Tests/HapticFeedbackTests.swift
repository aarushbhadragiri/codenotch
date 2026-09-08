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
            .enteredNotch, .providerChanged, .settingsOpened,
            .sliderBoundary, .integrationToggled, .refreshRequested, .dragBump(.strong)
        ]
        for event in events {
            service.play(event)
            time += 0.1
        }

        XCTAssertEqual(patterns.count, events.count)
    }

    func testMinimalKeepsOnlyDeliberateConfirmations() {
        var patterns: [NSHapticFeedbackManager.FeedbackPattern] = []
        var time: TimeInterval = 1
        let service = HapticFeedbackService(
            detailLevel: .minimal,
            reduceMotion: { false }, now: { time }, perform: { patterns.append($0) }
        )

        for event in [CodenotchHapticEvent.enteredNotch, .providerChanged,
                      .settingsOpened, .integrationToggled, .refreshRequested,
                      .dragBump(.strong)] {
            service.play(event)
            time += 0.1
        }

        XCTAssertEqual(patterns, [.levelChange, .alignment, .levelChange])
    }

    func testReduceMotionUsesTheMinimalInteractionSet() {
        var patterns: [NSHapticFeedbackManager.FeedbackPattern] = []
        let service = HapticFeedbackService(
            reduceMotion: { true }, perform: { patterns.append($0) }
        )

        service.play(.enteredNotch)
        service.play(.refreshRequested)

        XCTAssertEqual(patterns, [.levelChange])
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

    func testRefreshCompletionUsesUsageTiersAndWaitsForAnimation() {
        var scheduled: [(TimeInterval, () -> Void)] = []
        var patterns: [NSHapticFeedbackManager.FeedbackPattern] = []
        let service = HapticFeedbackService(
            reduceMotion: { false },
            perform: { patterns.append($0) },
            schedule: { scheduled.append(($0, $1)) }
        )

        service.playRefreshCompletion(usedFraction: 0.76)

        XCTAssertEqual(scheduled.map(\.0), [0.15, 0.26, 0.37])
        XCTAssertTrue(patterns.isEmpty)
        scheduled.forEach { $0.1() }
        XCTAssertEqual(patterns, [.levelChange, .levelChange, .levelChange])
    }

    func testExhaustedRefreshUsesThreeStrongClicks() {
        var scheduled: [() -> Void] = []
        var patterns: [NSHapticFeedbackManager.FeedbackPattern] = []
        let service = HapticFeedbackService(
            reduceMotion: { false },
            perform: { patterns.append($0) },
            schedule: { _, action in scheduled.append(action) }
        )

        service.playRefreshCompletion(usedFraction: 1)
        scheduled.forEach { $0() }

        XCTAssertEqual(patterns, [.generic, .generic, .generic])
    }
}
