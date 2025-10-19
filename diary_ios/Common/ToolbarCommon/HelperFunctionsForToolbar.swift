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
private func bellPressure(t: CGFloat) -> CGFloat {
    let clampedT = max(0.0, min(1.0, t))
    let base = 1.0 - pow((clampedT - 0.5) * 2, 2.0)
    return PenPreviewConstants.minPressure + base * (PenPreviewConstants.maxPressure - PenPreviewConstants.minPressure)
}

private func buildPenRibbonCGPath(
    segments: [(CGPoint, CGPoint, CGPoint, CGPoint)],
    width: CGFloat
) -> CGPath {
    let stepsPerSeg = PenPreviewConstants.segmentSteps
    let totalSteps  = PenPreviewConstants.totalSteps
    precondition(stepsPerSeg.count == segments.count)

    var leftPts: [CGPoint] = []; leftPts.reserveCapacity(totalSteps)
    var rightPts: [CGPoint] = []; rightPts.reserveCapacity(totalSteps)

    var startCenter = CGPoint.zero
    var endCenter   = CGPoint.zero
    var startRadius: CGFloat = 0
    var endRadius: CGFloat   = 0
    var stepIndex = 0
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
            let gT = CGFloat(gStep) / CGFloat(max(1, totalSteps - 1))

            // 半径：唯一受 width 影响
            // let r = max(PenPreviewConstants.minPx, (width * taper(gT) * bellPressure(t: gT)) / 2)
            let r = max(PenPreviewConstants.minPx, (width * bellPressure(t: gT)) / 2)

            leftPts.append(.init(x: P.x + nx * r, y: P.y + ny * r))
            rightPts.append(.init(x: P.x - nx * r, y: P.y - ny * r))
            // 记录首尾中心和半径
            if stepIndex == 0 {
                startCenter = P
                startRadius = r
            } else if stepIndex == totalSteps - 1 {
                endCenter = P
                endRadius = r
            }
            stepIndex += 1
        }
    }

    let path = CGMutablePath()
    // 1. 走左边界
    path.move(to: leftPts[0])
    for p in leftPts.dropFirst() { path.addLine(to: p) }

    // 2. 尾部半圆（圆头）
    do {
        let a0 = atan2(leftPts.last!.y - endCenter.y, leftPts.last!.x - endCenter.x)
        let a1 = atan2(rightPts.last!.y - endCenter.y, rightPts.last!.x - endCenter.x)
        path.addArc(center: endCenter, radius: endRadius, startAngle: a0, endAngle: a1, clockwise: true)
    }

    // 3. 右边界反向
    for p in rightPts.dropLast().reversed() { path.addLine(to: p) }

    // 4. 首部半圆（圆头）
    do {
        let a0 = atan2(rightPts.first!.y - startCenter.y, rightPts.first!.x - startCenter.x)
        let a1 = atan2(leftPts.first!.y - startCenter.y, leftPts.first!.x - startCenter.x)
        path.addArc(center: startCenter, radius: startRadius, startAngle: a0, endAngle: a1, clockwise: true)
    }

    path.closeSubpath()
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


func generatePathSegments(in rect: CGRect, base: CGFloat) -> [(CGPoint, CGPoint, CGPoint, CGPoint)] {
    let sx = rect.width / base
    let sy = rect.height / base
    let s = min(sx, sy)
    let dx = rect.minX + (rect.width  - base * s) * 0.5
    let dy = rect.minY + (rect.height - base * s) * 0.5

    func convert(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * s + dx, y: p.y * s + dy)
    }
    return PreviewSVGConstants.baseSegments.map { seg in
        (convert(seg.p0), convert(seg.c1), convert(seg.c2), convert(seg.p3))
    }
}

func generatePathLine(in rect: CGRect, base: CGFloat) -> (start: CGPoint, end: CGPoint) {
    let sx = rect.width / base
    let sy = rect.height / base
    let s = min(sx, sy)
    let dx = rect.minX + (rect.width  - base * s) * 0.5
    let dy = rect.minY + (rect.height - base * s) * 0.5

    let start = CGPoint(x: PreviewSVGConstants.baseLine.start.x * s + dx, y: PreviewSVGConstants.baseLine.start.y * s + dy)
    let end = CGPoint(x: PreviewSVGConstants.baseLine.end.x * s + dx, y: PreviewSVGConstants.baseLine.end.y * s + dy)
    return (start: start, end: end)
}

/// 计算与工具相关的“安全内边距”
func previewSafeMargin(for tool: Tool, width: CGFloat) -> CGFloat {
    var inset = width * 0.5
    if tool == .highlighter {
        inset += max(0.25, width * 0.10) // 跟你 layer.blur(radius: width*0.1) 保持一致
    }
    return ceil(inset)
}