import XCTest
@testable import Codenotch

final class NotchGlassBlurGeometryTests: XCTestCase {
    func testSideHaloReachesHalfTheNotchDepthPastItsFreeFaceAndEnds() {
        let placement = NotchPlacement(edge: .right,
                                       panelSize: CGSize(width: 500, height: 600))
        let rect = NotchGlassBlurGeometry.haloRect(
            placement: placement,
            notchLeadingInset: 100,
            notchLength: 200,
            notchDepth: 80
        )

        XCTAssertEqual(rect, CGRect(x: 380, y: 60, width: 120, height: 280))
    }

    func testHorizontalHaloUsesTheSameStackSpaceRule() {
        let placement = NotchPlacement(edge: .top,
                                       panelSize: CGSize(width: 600, height: 500))
        let rect = NotchGlassBlurGeometry.haloRect(
            placement: placement,
            notchLeadingInset: 100,
            notchLength: 200,
            notchDepth: 80
        )

        XCTAssertEqual(rect, CGRect(x: 60, y: 0, width: 280, height: 120))
    }
}

@MainActor
final class NotchGlassBlurPreferenceTests: XCTestCase {
    private func defaults() -> UserDefaults {
        let name = "NotchGlassBlurPreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testBlurIsOptInAndStartsAtSystemStrength() {
        let preferences = Preferences(defaults: defaults())
        XCTAssertFalse(preferences.notchBlurEnabled)
        XCTAssertEqual(preferences.notchBlurStrength, Preferences.defaultNotchBlurStrength)
    }

    func testBlurChoiceAndStrengthPersist() {
        let defaults = defaults()
        let preferences = Preferences(defaults: defaults)
        preferences.notchBlurEnabled = true
        preferences.notchBlurStrength = 1.6

        let restored = Preferences(defaults: defaults)
        XCTAssertTrue(restored.notchBlurEnabled)
        XCTAssertEqual(restored.notchBlurStrength, 1.6)
    }

    func testStoredStrengthIsClampedToTheSupportedRange() {
        let defaults = defaults()
        defaults.set(9.0, forKey: "notchBlurStrength")
        XCTAssertEqual(Preferences(defaults: defaults).notchBlurStrength,
                       Preferences.notchBlurStrengthRange.upperBound)
    }
}
