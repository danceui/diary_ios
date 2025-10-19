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

// PenPreview用带状多边形（ribbon），更顺滑也能缓存为矢量路径
private func buildPenRibbonCGPath(
    segments: [(CGPoint, CGPoint, CGPoint, CGPoint)],
    width: CGFloat
) -> CGPath {
    let stepsPerSeg = PenPreviewConstants.segmentSteps
    let totalSteps  = PenPreviewConstants.totalSteps
    precondition(stepsPerSeg.count == segments.count)

    var leftPts: [CGPoint] = []; leftPts.reserveCapacity(totalSteps)
    var rightPts: [CGPoint] = []; rightPts.reserveCapacity(totalSteps)

    for (segIndex, (p0, c1, c2, p3)) in segments.enumerated() {
        let steps = stepsPerSeg[segIndex]
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(max(1, steps - 1))
            let P  = cubicBezier(t: t, p0: p0, p1: c1, p2: c2, p3: p3)

            // 数值导数 → 切线 → 法线
            let e: CGFloat = 1e-3
            let P1 = cubicBezier(t: max(0, t - e), p0: p0, p1: c1, p2: c2, p3: p3)
            let P2 = cubicBezier(t: min(1, t + e), p0: p0, p1: c1, p2: c2, p3: p3)
            let dx = P2.x - P1.x, dy = P2.y - P1.y
            let L  = max(1e-6, hypot(dx, dy))
            let nx = -dy / L, ny = dx / L

            // 全局进度（用于你的 taper/pressure）
            let gStep = PenPreviewConstants.segmentStepSums[segIndex] - steps + i
            let gT    = CGFloat(gStep) / CGFloat(max(1, totalSteps - 1))

            // 半径：唯一受 width 影响
            let r = max(PenPreviewConstants.minPx, (width * taper(gT) * bellPressure(t: gT)) / 2)

            leftPts.append(.init(x: P.x + nx * r, y: P.y + ny * r))
            rightPts.append(.init(x: P.x - nx * r, y: P.y - ny * r))
        }
    }

    let path = CGMutablePath()
    if let first = leftPts.first {
        path.move(to: first)
        for p in leftPts.dropFirst() { path.addLine(to: p) }
        for p in rightPts.reversed() { path.addLine(to: p) }
        path.closeSubpath()
    }
    return path
}

func drawPenPreview(
    context: GraphicsContext,
    style: ToolStyle,
    segments: [(CGPoint, CGPoint, CGPoint, CGPoint)]
) {
    let color = style.color?.toColor() ?? .black
    let width = style.width ?? 2.0
    let opacity = style.opacity ?? 1.0
    let key = PenPreviewPathKey(width: width)

    // 命中缓存就直接用；未命中则构建一次带状路径
    let cgPath = PenPreviewPathCache.shared.path(for: key) {
        buildPenRibbonCGPath(segments: segments, width: width)
    }
    // 颜色/透明度不会改变几何形状，直接复用同一条路径
    context.fill(Path(cgPath), with: .color(color.opacity(opacity)))
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
// MARK: - Highlighter Preview
func highlighterAlpha(t: CGFloat) -> CGFloat {
    let clampedT = max(0.0, min(1.0, t))
    let base = 1.0 - pow((clampedT - 0.5) * 2, 2.0)
    return 0.2 + base * (1.0 - 0.2)
}

func drawHighlighterPreview(
    context: GraphicsContext,
    style: ToolStyle,
    line: (CGPoint, CGPoint)
) {
    let color = style.color?.toColor() ?? .yellow
    let width = style.width ?? 12.0
    let baseOpacity = style.opacity ?? 0.35

    var path = Path()
    path.move(to: line.0)
    path.addLine(to: line.1)
    let outline = path.strokedPath(.init(lineWidth: width, lineCap: .square, lineJoin: .miter))
    let shading = GraphicsContext.Shading.linearGradient(
        .init(stops: [
            .init(color: color.opacity(baseOpacity * 0.75), location: 0.00),
            .init(color: color.opacity(baseOpacity * 0.85), location: 0.50),
            .init(color: color.opacity(baseOpacity * 0.65), location: 1.00),
        ]),
        startPoint: line.0,
        endPoint: line.1
    )
    context.drawLayer { layer in
        layer.blendMode = .multiply
        layer.addFilter(.blur(radius: 0.3))
        layer.fill(outline, with: shading)
    }
}


func generatePathSegments(in rect: CGRect) -> [(CGPoint, CGPoint, CGPoint, CGPoint)] {
    let base = 20.0
    let sx = rect.width / base
    let sy = rect.height / base
    let s = min(sx, sy)
    let dx = rect.minX + (rect.width  - base * s) * 0.5
    let dy = rect.minY + (rect.height - base * s) * 0.5

    func convert(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * s + dx, y: p.y * s + dy)
    }
    return baseSegments.map { seg in
        (convert(seg.p0), convert(seg.c1), convert(seg.c2), convert(seg.p3))
    }
}

func generatePathLine(in rect: CGRect) -> (start: CGPoint, end: CGPoint) {
    let base = 20.0
    let sx = rect.width / base
    let sy = rect.height / base
    let s = min(sx, sy)
    let dx = rect.minX + (rect.width  - base * s) * 0.5
    let dy = rect.minY + (rect.height - base * s) * 0.5

    let start = CGPoint(x: baseLine.start.x * s + dx, y: baseLine.start.y * s + dy)
    let end = CGPoint(x: baseLine.end.x * s + dx, y: baseLine.end.y * s + dy)
    return (start: start, end: end)
}

