import XCTest
import SwiftUI
@testable import Codenotch

/// Renders the tooltip with a session in every state.
///
/// Partly a smoke test — a card that fails to lay out fails here rather than on
/// someone's screen — and partly a way to actually look at it: set
/// `TOOLTIP_RENDER_PATH` and the frame is written there.
@MainActor
final class TooltipRenderTests: XCTestCase {
    private func session(_ name: String, _ state: AgentSession.State,
                         minutes: Int) -> AgentSession {
        AgentSession(id: name, name: name, detail: "Terminal · usage-notch",
                     state: state, waitingFor: state == .waiting ? "your answer" : nil,
                     since: Date().addingTimeInterval(Double(-minutes) * 60))
    }

    func testTheCardLaysOutEverySessionState() throws {
        let snapshot = ProviderSnapshot(
            id: "claude", displayName: "Claude", glyph: .claude,
            fidelity: .official, status: .ok,
            windows: [LimitWindow(id: "session", label: "Session", usedFraction: 0.47)]
        )
        let activity = ActivitySummary(sessions: [
            session("codenotch-6f", .idle, minutes: 0),
            session("hivinz-web-2f", .busy, minutes: 1),
            session("codenotch-18", .waiting, minutes: 3)
        ])

        let view = TooltipCard(snapshot: snapshot, activity: activity, now: Date())
            .padding(20)
            .background(Color.black)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        let image = try XCTUnwrap(renderer.nsImage)

        // Three sessions of two lines each, under the window rows: a card that
        // silently collapsed would still render, just far too short.
        XCTAssertGreaterThan(image.size.height, NotchLayout.cardWidth * 0.5,
                             "the card laid out far shorter than three sessions need")
        XCTAssertGreaterThan(image.size.width, NotchLayout.cardWidth)

        if let path = ProcessInfo.processInfo.environment["TOOLTIP_RENDER_PATH"] {
            let tiff = try XCTUnwrap(image.tiffRepresentation)
            let png = try XCTUnwrap(NSBitmapImageRep(data: tiff)?
                .representation(using: .png, properties: [:]))
            try png.write(to: URL(fileURLWithPath: path))
        }
    }
}

final class TooltipTailShapeTests: XCTestCase {
    func testEveryTailUsesCurvesAtTheCardJoin() {
        for direction in [NotchEdge.TooltipDirection.leading, .trailing, .up, .down] {
            let size = TooltipTail.size(for: direction)
            let path = TooltipTail(direction: direction)
                .path(in: CGRect(origin: .zero, size: size))
                .cgPath
            var curves = 0
            path.applyWithBlock { element in
                if element.pointee.type == .addCurveToPoint { curves += 1 }
            }
            XCTAssertEqual(curves, 2, "\(direction): the tail fell back to sharp shoulders")
        }
    }

    func testEveryTailStillReachesItsCellFacingEdge() {
        for direction in [NotchEdge.TooltipDirection.leading, .trailing, .up, .down] {
            let size = TooltipTail.size(for: direction)
            let bounds = TooltipTail(direction: direction)
                .path(in: CGRect(origin: .zero, size: size))
                .boundingRect
            XCTAssertEqual(bounds.minX, 0, accuracy: 0.001, "\(direction)")
            XCTAssertEqual(bounds.minY, 0, accuracy: 0.001, "\(direction)")
            XCTAssertEqual(bounds.width, size.width, accuracy: 0.001,
                           "\(direction): rounding moved the tail tip or card join")
            XCTAssertEqual(bounds.height, size.height, accuracy: 0.001,
                           "\(direction): rounding moved the tail tip or card join")
        }
    }
}
