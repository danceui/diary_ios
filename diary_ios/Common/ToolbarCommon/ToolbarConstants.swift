import UIKit
import SwiftUI
import CoreGraphics

struct BezierSegment {
    let p0, c1, c2, p3: CGPoint
}

let baseSegments: [BezierSegment] = {
    let rawPoints: [(p0: CGPoint, c1: CGPoint, c2: CGPoint, p3: CGPoint)] = [
        (p0: CGPoint(x: 2.82, y: 13.6), c1: CGPoint(x: 2.52, y: 11.5), c2: CGPoint(x: 3.62, y: 8.7), p3: CGPoint(x: 5.32, y: 6.8)),
        (p0: CGPoint(x: 5.32, y: 6.8), c1: CGPoint(x: 6.22, y: 5.7), c2: CGPoint(x: 7.72, y: 5.3), p3: CGPoint(x: 9.12, y: 5.9)),
        (p0: CGPoint(x: 9.12, y: 5.9), c1: CGPoint(x: 10.62, y: 6.5), c2: CGPoint(x: 11.32, y: 8.5), p3: CGPoint(x: 11.78, y: 10.4)),
        (p0: CGPoint(x: 11.78, y: 10.4), c1: CGPoint(x: 12.02, y: 11.8), c2: CGPoint(x: 12.42, y: 13.7), p3: CGPoint(x: 13.82, y: 14.2)),
        (p0: CGPoint(x: 13.82, y: 14.2), c1: CGPoint(x: 15.02, y: 14.6), c2: CGPoint(x: 17.12, y: 13.7), p3: CGPoint(x: 17.82, y: 10.6))
    ]
    return rawPoints.map { (p0, c1, c2, p3) in BezierSegment(p0: p0, c1: c1, c2: c2, p3: p3) }
}()

struct ToolbarConstants {
    static let toolSelectionHeight: CGFloat = 160.0
    static let stylePresetHeight: CGFloat = 160.0
    static let leadingPadding: CGFloat = 30.0
    static let trailingPadding: CGFloat = 30.0
    static let topPadding: CGFloat = 10.0
    static let popoverGap: CGFloat = 12
    static let iconSize: CGFloat = 30.0
    static let iconPadding: CGFloat = 7.0
    static let iconSpacing: CGFloat = 4.0
    static let toolbarBackgroundColor: UIColor = .systemBackground
    static let toolbarButtonColor: UIColor = .systemBlue
    static let toolbarButtonSelectedColor: UIColor = .systemGreen
}


struct PenPreviewConstants {
    static let minPressure: CGFloat = 0.55
    static let maxPressure: CGFloat = 0.75
    static let minPx: CGFloat = 0.5
    static let segmentSteps = [18, 16, 16, 18, 22]
    static let segmentStepSums = [18, 34, 50, 68, 90]
    static let totalSteps = 90
}  

struct PreviewConstants {
    static let previewColors: [Color] = [
        .red.opacity(1.0),
        .blue.opacity(0.7),
        .green.opacity(0.5),
        .orange.opacity(0.8),
        .purple.opacity(0.6),
        .pink.opacity(1.0),
        .yellow.opacity(0.5),
        .pink.opacity(0.9)
    ]
}

// 只把“会影响形状的参数”放进 Key；颜色/透明度不放！
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