import UIKit
import SwiftUI

struct BezierSegment {
    let p0, c1, c2, p3: CGPoint
}

let baseSegments: [BezierSegment] = {
    let rawPoints: [(p0: CGPoint, c1: CGPoint, c2: CGPoint, p3: CGPoint)] = [
        // M 1.5 17.0
        // C 1.2 14.9, 2.3 12.1, 4.0 10.2
        (p0: CGPoint(x: 1.5,  y: 17.0),
        c1: CGPoint(x: 1.2,  y: 14.9),
        c2: CGPoint(x: 2.3,  y: 12.1),
        p3: CGPoint(x: 4.0,  y: 10.2)),

        // C 4.9 9.1, 6.4 8.7, 7.8 9.3
        (p0: CGPoint(x: 4.0,  y: 10.2),
        c1: CGPoint(x: 4.9,  y: 9.1),
        c2: CGPoint(x: 6.4,  y: 8.7),
        p3: CGPoint(x: 7.8,  y: 9.3)),

        // C 9.3 9.9, 10.3 11.9, 10.5 13.8
        (p0: CGPoint(x: 7.8,  y: 9.3),
        c1: CGPoint(x: 9.3,  y: 9.9),
        c2: CGPoint(x: 10.3, y: 11.9),
        p3: CGPoint(x: 10.5, y: 13.8)),

        // C 10.7 15.2, 11.1 17.1, 12.5 17.6
        (p0: CGPoint(x: 10.5, y: 13.8),
        c1: CGPoint(x: 10.7, y: 15.2),
        c2: CGPoint(x: 11.1, y: 17.1),
        p3: CGPoint(x: 12.5, y: 17.6)),

        // C 13.7 18.0, 15.8 17.1, 16.4 14.3
        (p0: CGPoint(x: 12.5, y: 17.6),
        c1: CGPoint(x: 13.7, y: 18.0),
        c2: CGPoint(x: 15.8, y: 17.1),
        p3: CGPoint(x: 16.4, y: 14.3)),
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
