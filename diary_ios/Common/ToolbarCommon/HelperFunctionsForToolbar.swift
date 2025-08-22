import UIKit
import SwiftUI

func cubicBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
    let oneMinusT = 1 - t
    let a = oneMinusT * oneMinusT * oneMinusT
    let b = 3 * oneMinusT * oneMinusT * t
    let c = 3 * oneMinusT * t * t
    let d = t * t * t

    let x = a * p0.x + b * p1.x + c * p2.x + d * p3.x
    let y = a * p0.y + b * p1.y + c * p2.y + d * p3.y
    return CGPoint(x: x, y: y)
}

// MARK: - Pen Preview
func bellPressure(t: CGFloat) -> CGFloat {
    let clampedT = max(0.0, min(1.0, t))
    let base = 1.0 - pow((clampedT - 0.5) * 2, 2)
    return ToolConstants.penMinPressure + base * (ToolConstants.penMaxPressure - ToolConstants.penMinPressure)
}

func drawPenPreview(
    context: GraphicsContext,
    start: CGPoint,
    ctrl1: CGPoint,
    ctrl2: CGPoint,
    end: CGPoint,
    style: ToolStyle,
    segmentIndex: Int,
    totalSegments: Int
) {
    let steps = PreviewConstants.steps // 每个段的采样点数
    let color = style.color?.toColor() ?? .black
    let width = style.width ?? 2.0
    let opacity = style.opacity ?? 1.0

    var path = Path()
    for i in 0..<steps {
        let t = CGFloat(i) / CGFloat(steps - 1)
        let point = cubicBezier(t: t, p0: start, p1: ctrl1, p2: ctrl2, p3: end) // 计算第 i 点的位置
        let globalT = (CGFloat(segmentIndex) + t) / CGFloat(totalSegments - 1)
        let pressure = bellPressure(t: globalT)
        let radius = width * pressure / 2 // 该处圆的半径
        path.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
    }
    context.fill(path, with: .color(color.opacity(opacity)))
}

// MARK: - Highlighter Preview

let highlighterOpacities: [CGFloat] = [
    0.8, // 0 起笔最深
    0.8, // 1
    0.8, // 2
    0.8, // 3 第一次转弯更实
    0.8, // 4
    0.8, // 5
    0.8, // 6 第二次转弯更实
    0.8  // 7 收尾最淡
]

func drawHighlighterPreview(
    context: GraphicsContext,
    style: ToolStyle,
    segments: [(CGPoint, CGPoint, CGPoint, CGPoint)]
) {
    let color = style.color?.toColor() ?? .yellow
    let width = style.width ?? 12.0
    let baseOpacity = style.opacity ?? 0.35

    // 每段的固定透明度（你之前定义的数组）
    // let segmentOpacity = highlighterOpacities[segmentIndex % highlighterOpacities.count]

    var path = Path()
    path.move(to: segments[0].0)
    for seg in segments {
        path.addCurve(to: seg.3, control1: seg.1, control2: seg.2)
    }
    let outline = path.strokedPath(.init(lineWidth: width, lineCap: .butt, lineJoin: .round))
    context.fill(outline, with: .color(color.opacity(baseOpacity)))
}

// MARK: - Monoline Preview
func drawMonolinePreview(
    context: GraphicsContext,
    style: ToolStyle,
    segments: [(CGPoint, CGPoint, CGPoint, CGPoint)]
) {
    let color = style.color?.toColor() ?? .yellow
    let width = style.width ?? 12.0
    let baseOpacity = style.opacity ?? 0.35

    var path = Path()
    path.move(to: segments[0].0)
    for seg in segments {
        path.addCurve(to: seg.3, control1: seg.1, control2: seg.2)
    }
    let outline = path.strokedPath(.init(lineWidth: width, lineCap: .round, lineJoin: .round))
    context.fill(outline, with: .color(color.opacity(baseOpacity)))

}

func generatePathSegments(inset: CGFloat, drawingSize: CGSize) -> [(CGPoint, CGPoint, CGPoint, CGPoint)] {
    let scaleX = drawingSize.width / 26.458333
    let scaleY = drawingSize.height / 26.458333

    func convert(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: x * scaleX + inset, y: y * scaleY + inset)
    }
    
    let bezierSegments: [(CGPoint, CGPoint, CGPoint, CGPoint)] = [
        (convert(x: 1.850687, y: 17.570022), convert(x: 0.932941, y: 15.069087), convert(x: 2.005763, y: 12.310653), convert(x: 3.595063, y: 10.347862)), // 第一个转弯前
        (convert(x: 3.595063, y: 10.347862), convert(x: 4.369668, y: 9.059063), convert(x: 6.114127, y: 8.652024), convert(x: 7.413834, y: 9.341245)), // 第一个转弯
        (convert(x: 7.413834, y: 9.341245), convert(x: 9.210874, y: 10.161493), convert(x: 10.110526, y: 12.176224), convert(x: 10.264806, y: 14.073580)), // 第一、二个转弯之间
        (convert(x: 10.264806, y: 14.073580), convert(x: 10.483572, y: 15.465286), convert(x: 10.861685, y: 17.156747), convert(x: 12.273829, y: 17.778131)), // 第二个转弯前半段
        (convert(x: 12.273829, y: 17.778131), convert(x: 13.613956, y: 18.174263), convert(x: 14.812265, y: 17.042496), convert(x: 15.463040, y: 15.976733)), // 第二个转弯后半段
        (convert(x: 15.463040, y: 15.976733), convert(x: 16.207361, y: 14.831670), convert(x: 17.789632, y: 13.946173), convert(x: 19.090702, y: 14.688075)), // 第三个转弯
        (convert(x: 19.090702, y: 14.688075), convert(x: 20.187863, y: 15.560343), convert(x: 20.831390, y: 17.184842), convert(x: 22.366480, y: 17.372298)), // 第三、四个转弯之间
        (convert(x: 22.366480, y: 17.372298), convert(x: 23.412848, y: 17.497058), convert(x: 24.159403, y: 16.672955), convert(x: 24.955118, y: 16.138709)) // 第四个转弯
    ]
    return bezierSegments
}
