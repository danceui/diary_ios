import UIKit
import SwiftUI
import CoreGraphics

struct BezierSegment {
    let p0, c1, c2, p3: CGPoint
}

struct PreviewSVGConstants {
    static let canvasSize = CGSize(width: 200, height: 200)
    static let baseSize = 24.0 // original SVG size
    static let baseSegments: [BezierSegment] = {
        let rawPoints: [(p0: CGPoint, c1: CGPoint, c2: CGPoint, p3: CGPoint)] = [
            (p0: CGPoint(x: 4.82, y: 15.6), c1: CGPoint(x: 4.52, y: 13.5), c2: CGPoint(x: 5.62, y: 10.7), p3: CGPoint(x: 7.32, y: 8.8)),
            (p0: CGPoint(x: 7.32, y: 8.8), c1: CGPoint(x: 8.22, y: 7.7), c2: CGPoint(x: 9.72, y: 7.3), p3: CGPoint(x: 11.12, y: 7.9)),
            (p0: CGPoint(x: 11.12, y: 7.9), c1: CGPoint(x: 12.62, y: 8.5), c2: CGPoint(x: 13.32, y: 10.5), p3: CGPoint(x: 13.78, y: 12.4)),
            (p0: CGPoint(x: 13.78, y: 12.4), c1: CGPoint(x: 14.02, y: 13.8), c2: CGPoint(x: 14.42, y: 15.7), p3: CGPoint(x: 15.82, y: 16.2)),
            (p0: CGPoint(x: 15.82, y: 16.2), c1: CGPoint(x: 17.02, y: 16.6), c2: CGPoint(x: 19.12, y: 15.7), p3: CGPoint(x: 19.82, y: 12.6))
        ]
        return rawPoints.map { (p0, c1, c2, p3) in BezierSegment(p0: p0, c1: c1, c2: c2, p3: p3) }
    }()
    static let baseLine: (start: CGPoint, end: CGPoint) = (start: CGPoint(x: 5.5, y: 15.0), end: CGPoint(x: 19.0, y: 8.0))
}

struct ToolbarConstants {
    static let toolPanelHeight: CGFloat = 260.0
    static let stylePresetPanelHeight: CGFloat = 160.0
    static let panelWidth: CGFloat = 50.0
    static let styleDetailWidth: CGFloat = 200.0
    static let styleDetailHeight: CGFloat = 230.0
    static let leadingPadding: CGFloat = 30.0
    static let trailingPadding: CGFloat = 30.0
    static let topPadding: CGFloat = 10.0
    static let popoverGap: CGFloat = 12
    static let iconSize: CGFloat = 30.0
    static let iconPadding: CGFloat = 4.0
    static let buttonPadding: CGFloat = 4.0
    static let buttonSpacing: CGFloat = 4.0
    static let toolbarCornerRadius: CGFloat = 24.0
    static let toolbarBackgroundColor: UIColor = .systemBackground
    static let toolbarButtonColor: UIColor = .systemBlue
    static let toolbarButtonSelectedColor: UIColor = .systemGreen
}

// MARK: - Pen Preview Constants
struct PenPreviewConstants {
    static let minPressure: CGFloat = 0.45
    static let maxPressure: CGFloat = 0.75
    static let minPx: CGFloat = 0.5
    static let segmentSteps = [18, 16, 16, 18, 22]
    static let segmentStepSums = [18, 34, 50, 68, 90]
    static let totalSteps = 90
}  

struct PenPreviewPathKey: Hashable {
    let width: CGFloat
}

final class PenPreviewPathCache {
    static let shared = PenPreviewPathCache()
    private var map: [PenPreviewPathKey: CGPath] = [:]
    func path(for key: PenPreviewPathKey, build: () -> CGPath) -> CGPath {
        if let p = map[key] { return p }
        let p = build()
        map[key] = p
        return p
    }
}
