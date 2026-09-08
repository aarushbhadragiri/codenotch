import AppKit
import SwiftUI

/// The part of the panel claimed by the open notch's glass halo.
///
/// The halo reaches half the open notch's depth beyond its free face and the
/// same distance past both ends. Keeping this calculation in stack space
/// makes all four edges share one rule, and keeping the result separate from
/// the tooltip geometry guarantees the card is never part of the glass view.
struct NotchGlassBlurGeometry {
    static func haloRect(
        placement: NotchPlacement,
        notchLeadingInset: CGFloat,
        notchLength: CGFloat,
        notchDepth: CGFloat
    ) -> CGRect {
        let reach = notchDepth / 2
        return placement.rect(
            along: notchLeadingInset - reach,
            across: 0,
            length: notchLength + 2 * reach,
            depth: notchDepth + reach
        )
    }
}

/// Apple's native macOS 26 Liquid Glass surface.
///
/// A strength of 1 is deliberately untouched system glass. Below it, the
/// complete native effect is blended down; above it, AppKit's own tint input
/// adds frost without replacing the live glass with a static translucent fill.
struct NativeLiquidGlass: NSViewRepresentable {
    let strength: Double

    func makeNSView(context: Context) -> NSGlassEffectView {
        let view = NSGlassEffectView()
        view.style = .regular
        view.cornerRadius = NotchLayout.cornerRadius
        view.setAccessibilityElement(false)
        return view
    }

    func updateNSView(_ view: NSGlassEffectView, context: Context) {
        let clamped = min(max(strength, Preferences.notchBlurStrengthRange.lowerBound),
                          Preferences.notchBlurStrengthRange.upperBound)
        view.alphaValue = CGFloat(min(clamped, 1))

        let addedFrost = CGFloat(max(0, clamped - 1))
        view.tintColor = addedFrost == 0
            ? nil
            : NSColor.windowBackgroundColor.withAlphaComponent(addedFrost * 0.62)
    }
}
