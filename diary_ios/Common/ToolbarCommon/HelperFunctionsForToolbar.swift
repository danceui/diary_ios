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
    let base = 1.0 - pow((clampedT - 0.5) * 2, 2.0)
    return PenPreviewConstants.minPressure + base * (PenPreviewConstants.maxPressure - PenPreviewConstants.minPressure)
}

func taper(_ u: CGFloat) -> CGFloat {
    let x = max(0, min(1, u))
    let power = 3.0
    let minScale = 0.6
    // sin 需要 Double，完了再转回 CGFloat
    let s = CGFloat(sin(Double(x * .pi)))
    return minScale + (1 - minScale) * pow(max(0, s), power)
}

func drawPenPreview(
    context: GraphicsContext,
    style: ToolStyle,
    segments: [(CGPoint, CGPoint, CGPoint, CGPoint)]
) {
    let color = style.color?.toColor() ?? .black
    let width = style.width ?? 2.0
    let opacity = style.opacity ?? 1.0

    var path = Path()
    for (index, (p0, c1, c2, p3)) in segments.enumerated() {
        let steps = PenPreviewConstants.segmentSteps[index]
        for i in 0..<steps {
            // 全局归一化位置 globalT ∈ [0,1]
            let globalT = (CGFloat(PenPreviewConstants.segmentStepSums[index] - steps + i)) / CGFloat(PenPreviewConstants.totalSteps - 1)
            let t = CGFloat(i) / CGFloat(steps - 1)
            let point = cubicBezier(t: t, p0: p0, p1: c1, p2: c2, p3: p3) // 计算第 i 点的位置
            let pressure = bellPressure(t: globalT)
            let radius = max(PenPreviewConstants.minPx, width * taper(globalT) * pressure / 2) // 该处圆的半径
            path.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        }
    }
    context.fill(path, with: .color(color.opacity(opacity)))
}

// MARK: - Highlighter Preview
func highlighterAlpha(t: CGFloat) -> CGFloat {
    let clampedT = max(0.0, min(1.0, t))
    let base = 1.0 - pow((clampedT - 0.5) * 2, 2.0)
    return 0.2 + base * (1.0 - 0.2)
}

func drawHighlighterPreview(
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
    let outline = path.strokedPath(.init(lineWidth: width, lineCap: .square, lineJoin: .miter))
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

func generatePathSegments(in rect: CGRect) -> [(CGPoint, CGPoint, CGPoint, CGPoint)] {
    let base = 20.0
    // let tx: CGFloat = 1.32
    // let ty: CGFloat = -3.4
    let sx = rect.width / base
    let sy = rect.height / base
    let s = min(sx, sy)
    let dx = rect.minX + (rect.width  - base * s) * 0.5
    let dy = rect.minY + (rect.height - base * s) * 0.5

    func convert(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * s + dx, y: p.y * s + dy)
        // CGPoint(x: (p.x + tx) * s + dx, y: (p.y + ty) * s + dy)
    }

    return baseSegments.map { seg in
        (convert(seg.p0), convert(seg.c1), convert(seg.c2), convert(seg.p3))
    }
}

