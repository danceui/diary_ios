import UIKit
import SwiftUI

struct BezierSegment {
    let p0, c1, c2, p3: CGPoint
    let baseLength: CGFloat
}

func segmentLength(p0: CGPoint, c1: CGPoint, c2: CGPoint, p3: CGPoint, samples: Int = 20) -> CGFloat {
    var len: CGFloat = 0
    var prev = p0
    for i in 1...samples {
        let t = CGFloat(i)/CGFloat(samples)
        let p = cubicBezier(t: t, p0: p0, p1: c1, p2: c2, p3: p3)
        len += hypot(p.x - prev.x, p.y - prev.y)
        prev = p
    }
    return len
}

let baseSegments: [BezierSegment] = {
    let rawPoints: [(CGPoint, CGPoint, CGPoint, CGPoint)] = [
        (CGPoint(x: 1.850687, y: 17.570022), CGPoint(x: 0.932941, y: 15.069087), CGPoint(x: 2.005763, y: 12.310653), CGPoint(x: 3.595063, y: 10.347862)), // 第一个转弯前
        (CGPoint(x: 3.595063, y: 10.347862), CGPoint(x: 4.369668, y: 9.059063), CGPoint(x: 6.114127, y: 8.652024), CGPoint(x: 7.413834, y: 9.341245)), // 第一个转弯
        (CGPoint(x: 7.413834, y: 9.341245), CGPoint(x: 9.210874, y: 10.161493), CGPoint(x: 10.110526, y: 12.176224), CGPoint(x: 10.264806, y: 14.073580)), // 第一、二个转弯之间
        (CGPoint(x: 10.264806, y: 14.073580), CGPoint(x: 10.483572, y: 15.465286), CGPoint(x: 10.861685, y: 17.156747), CGPoint(x: 12.273829, y: 17.778131)), // 第二个转弯前半段
        (CGPoint(x: 12.273829, y: 17.778131), CGPoint(x: 13.613956, y: 18.174263), CGPoint(x: 14.812265, y: 17.042496), CGPoint(x: 15.463040, y: 15.976733)), // 第二个转弯后半段
        (CGPoint(x: 15.463040, y: 15.976733), CGPoint(x: 16.207361, y: 14.831670), CGPoint(x: 17.789632, y: 13.946173), CGPoint(x: 19.090702, y: 14.688075)), // 第三个转弯
        (CGPoint(x: 19.090702, y: 14.688075), CGPoint(x: 20.187863, y: 15.560343), CGPoint(x: 20.831390, y: 17.184842), CGPoint(x: 22.366480, y: 17.372298)), // 第三、四个转弯之间
        (CGPoint(x: 22.366480, y: 17.372298), CGPoint(x: 23.412848, y: 17.497058), CGPoint(x: 24.159403, y: 16.672955), CGPoint(x: 24.955118, y: 16.138709)) // 第四个转弯
    ]
    return rawPoints.map { (p0, c1, c2, p3) in
        return BezierSegment(p0: p0, c1: c1, c2: c2, p3: p3, baseLength: segmentLength(p0: p0, c1: c1, c2: c2, p3: p3))
    }
}()

struct ToolConstants {
}

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

struct PreviewConstants {
    static let penMinPressure: CGFloat = 0.55
    static let penMaxPressure: CGFloat = 0.75
    static let penMinPx: CGFloat = 0.5
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
