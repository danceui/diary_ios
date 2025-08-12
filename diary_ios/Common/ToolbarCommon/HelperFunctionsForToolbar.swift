import UIKit
import SwiftUI

// 按照 t 计算贝塞尔曲线上的点
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
    let color = style.color?.toColor() ?? .black
    let width = style.width ?? 2.0
    let opacity = style.opacity ?? 1.0

    // 估算当前曲线的长度
    let roughSamples = PreviewConstants.samples
    var length: CGFloat = 0
    var prev = cubicBezier(t: 0, p0: start, p1: ctrl1, p2: ctrl2, p3: end)

    // 估计本段的 globalT 起止
    let denom = max(1, totalSegments - 1)
    let segT0 = CGFloat(segmentIndex) / CGFloat(denom)
    let segT1 = CGFloat(segmentIndex + 1) / CGFloat(denom)

    var pressureSum: CGFloat = 0
    for i in 1...roughSamples {
        let t = CGFloat(i) / CGFloat(roughSamples)
        let p = cubicBezier(t: t, p0: start, p1: ctrl1, p2: ctrl2, p3: end)
        length += hypot(p.x - prev.x, p.y - prev.y)
        prev = p

        // 估平均压力
        let globalT = segT0 + (segT1 - segT0) * t
        pressureSum += bellPressure(t: globalT)
    }
    let avgPressure = pressureSum / CGFloat(roughSamples)
    let effectivePressure = max(0.35, min(1.0, avgPressure)) // 给个下限，避免端点极细导致步数过大

    // 用有效笔宽控制点间距, 保证重叠不露缝
    let baseSteps = PreviewConstants.steps
    let effectiveWidth = width * effectivePressure
    let spacing = max(0.3, effectiveWidth * 0.45) // ≈0.45×有效笔宽
    let dynSteps = max(baseSteps, Int(ceil(length / spacing)))

    // 先画点阵
    for i in 0..<dynSteps {
        let t = CGFloat(i) / CGFloat(max(dynSteps - 1, 1))
        let point = cubicBezier(t: t, p0: start, p1: ctrl1, p2: ctrl2, p3: end)

        // 注意 globalT 要与该点在“整条笔画”的相对位置一致
        let globalT = (CGFloat(segmentIndex) + t) / CGFloat(denom)
        let pressure = bellPressure(t: globalT)

        let radius = (width * pressure) / 2
        let dot = Path(ellipseIn: CGRect(
            x: point.x - radius, y: point.y - radius,
            width: radius * 2, height: radius * 2
        ))
        // 点阵略降透明度，给后面的“收边描线”留空间，避免叠色过深
        context.fill(dot, with: .color(color.opacity(opacity * 0.75)))
    }

    // 短线段 + 圆头, 每段线宽随压力变化
    for i in 0..<(max(dynSteps, 2) - 1) {
        let t0 = CGFloat(i) / CGFloat(max(dynSteps - 1, 1))
        let t1 = CGFloat(i + 1) / CGFloat(max(dynSteps - 1, 1))

        let p0 = cubicBezier(t: t0, p0: start, p1: ctrl1, p2: ctrl2, p3: end)
        let p1 = cubicBezier(t: t1, p0: start, p1: ctrl1, p2: ctrl2, p3: end)

        let g0 = (CGFloat(segmentIndex) + t0) / CGFloat(denom)
        let g1 = (CGFloat(segmentIndex) + t1) / CGFloat(denom)

        let pr0 = bellPressure(t: g0)
        let pr1 = bellPressure(t: g1)

        let w0 = max(0.1, width * pr0)
        let w1 = max(0.1, width * pr1)
        let segW = max(0.1, (w0 + w1) * 0.5) * 1.02   // 轻微放大避免缝隙

        var segPath = Path()
        segPath.move(to: p0)
        segPath.addLine(to: p1)

        let strokeStyle = StrokeStyle(
            lineWidth: segW,
            lineCap: .round,
            lineJoin: .round,
            miterLimit: 2
        )
        context.stroke(segPath, with: .color(color.opacity(opacity)), style: strokeStyle)
    }
}

func drawMonolinePreview(
    context: GraphicsContext,
    start: CGPoint,
    ctrl1: CGPoint,
    ctrl2: CGPoint,
    end: CGPoint,
    style: ToolStyle,
    segmentIndex: Int,
    totalSegments: Int
) {
    let color = style.color?.toColor() ?? .black
    let width = style.width ?? 2.0
    let opacity = style.opacity ?? 1.0

    // 估算当前曲线的长度
    let roughSamples = PreviewConstants.samples
    var length: CGFloat = 0
    var prev = cubicBezier(t: 0, p0: start, p1: ctrl1, p2: ctrl2, p3: end)
    for i in 1...roughSamples {
        let t = CGFloat(i) / CGFloat(roughSamples)
        let p = cubicBezier(t: t, p0: start, p1: ctrl1, p2: ctrl2, p3: end)
        length += hypot(p.x - prev.x, p.y - prev.y) 
        prev = p
    }

    // 用笔宽控制点间距, 使点略有重叠
    let baseSteps = PreviewConstants.steps
    let spacing = max(0.3, width * 0.45) // 点间距 ≈ 0.45 * width, 基本不会露缝
    let dynSteps = max(baseSteps, Int(ceil(length / spacing))) // 动态步数, 保证足够密

    // 先画点阵
    for i in 0..<dynSteps {
        let t = CGFloat(i) / CGFloat(max(dynSteps - 1, 1))
        let point = cubicBezier(t: t, p0: start, p1: ctrl1, p2: ctrl2, p3: end)
        let radius = width / 2
        let dot = Path(ellipseIn: CGRect(
            x: point.x - radius, y: point.y - radius,
            width: radius * 2, height: radius * 2
        ))
        // 点阵略低一点透明度，避免与描边叠加过深
        context.fill(dot, with: .color(color.opacity(opacity * 0.75)))
    }

    // 叠一条略细的圆头曲线做收边, 更清晰
    var path = Path()
    path.move(to: start)
    path.addCurve(to: end, control1: ctrl1, control2: ctrl2)
    let strokeStyle = StrokeStyle(lineWidth: width * 0.86, lineCap: .round, lineJoin: .round, miterLimit: 2)
    context.stroke(path, with: .color(color.opacity(opacity)), style: strokeStyle)
}

func generatePathSegments(inset: CGFloat, drawingSize: CGSize) -> [(CGPoint, CGPoint, CGPoint, CGPoint)] {
    let scaleX = drawingSize.width / 26.458333
    let scaleY = drawingSize.height / 26.458333

    func convert(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: x * scaleX + inset, y: y * scaleY + inset)
    }
    
    let bezierSegments: [(CGPoint, CGPoint, CGPoint, CGPoint)] = [
        (convert(x: 1.850687, y: 17.570022), convert(x: 0.932941, y: 15.069087), convert(x: 2.005763, y: 12.310653), convert(x: 3.595063, y: 10.347862)),
        (convert(x: 3.595063, y: 10.347862), convert(x: 4.369668, y: 9.059063), convert(x: 6.114127, y: 8.652024), convert(x: 7.413834, y: 9.341245)),
        (convert(x: 7.413834, y: 9.341245), convert(x: 9.210874, y: 10.161493), convert(x: 10.110526, y: 12.176224), convert(x: 10.264806, y: 14.073580)),
        (convert(x: 10.264806, y: 14.073580), convert(x: 10.483572, y: 15.465286), convert(x: 10.861685, y: 17.156747), convert(x: 12.273829, y: 17.778131)),
        (convert(x: 12.273829, y: 17.778131), convert(x: 13.613956, y: 18.174263), convert(x: 14.812265, y: 17.042496), convert(x: 15.463040, y: 15.976733)),
        (convert(x: 15.463040, y: 15.976733), convert(x: 16.207361, y: 14.831670), convert(x: 17.789632, y: 13.946173), convert(x: 19.090702, y: 14.688075)),
        (convert(x: 19.090702, y: 14.688075), convert(x: 20.187863, y: 15.560343), convert(x: 20.831390, y: 17.184842), convert(x: 22.366480, y: 17.372298)),
        (convert(x: 22.366480, y: 17.372298), convert(x: 23.412848, y: 17.497058), convert(x: 24.159403, y: 16.672955), convert(x: 24.955118, y: 16.138709))
    ]
    return bezierSegments
}

// func generateMonolinePath(inset: CGFloat, drawingSize: CGSize) -> Path {
//     let scaleX = drawingSize.width / 26.458333
//     let scaleY = drawingSize.height / 26.458333

//     func convert(x: CGFloat, y: CGFloat) -> CGPoint {
//         CGPoint(x: x * scaleX + inset, y: y * scaleY + inset)
//     }

//     var path = Path()
//     // calculated swift path based on SVG data
//     path.move(to: convert(x: 1.850687, y: 17.570022))
//     path.addCurve(to: convert(x: 3.595063, y: 10.347862), control1: convert(x: 0.932941, y: 15.069087), control2: convert(x: 2.005763, y: 12.310653))
//     path.addCurve(to: convert(x: 7.413834, y: 9.341245), control1: convert(x: 4.369668, y: 9.059063), control2: convert(x: 6.114127, y: 8.652024))
//     path.addCurve(to: convert(x: 10.264806, y: 14.073580), control1: convert(x: 9.210874, y: 10.161493), control2: convert(x: 10.110526, y: 12.176224))
//     path.addCurve(to: convert(x: 12.273829, y: 17.778131), control1: convert(x: 10.483572, y: 15.465286), control2: convert(x: 10.861685, y: 17.156747))
//     path.addCurve(to: convert(x: 15.463040, y: 15.976733), control1: convert(x: 13.613956, y: 18.174263), control2: convert(x: 14.812265, y: 17.042496))
//     path.addCurve(to: convert(x: 19.090702, y: 14.688075), control1: convert(x: 16.207361, y: 14.831670), control2: convert(x: 17.789632, y: 13.946173))
//     path.addCurve(to: convert(x: 22.366480, y: 17.372298), control1: convert(x: 20.187863, y: 15.560343), control2: convert(x: 20.831390, y: 17.184842))
//     path.addCurve(to: convert(x: 24.955118, y: 16.138709), control1: convert(x: 23.412848, y: 17.497058), control2: convert(x: 24.159403, y: 16.672955))
//     return path
// }

func bellPressure(t: CGFloat) -> CGFloat {
    let clampedT = max(0.0, min(1.0, t))
    let base = 1.0 - pow((clampedT - 0.5) * 2, 2)
    return ToolConstants.penMinPressure + base * (ToolConstants.penMaxPressure - ToolConstants.penMinPressure)
}

// func generatePenPath(inset: CGFloat, drawingSize: CGSize, width: CGFloat, minPressure: CGFloat = 0.2, maxPressure: CGFloat = 1.0, samplesPerSegment: Int = 20) -> Path {
//     let bezierSegments = generatePathSegments(inset: inset, drawingSize: drawingSize)
//     var strokePoints: [CGPoint] = []

//     for (p0, c1, c2, p3) in bezierSegments {
//         let segmentPoints = sampleCubicBezier(p0: p0, c1: c1, c2: c2, p3: p3, samples: samplesPerSegment)
//         strokePoints.append(contentsOf: segmentPoints.dropFirst())
//     }

//     let count = strokePoints.count
//     var topEdge: [CGPoint] = []
//     var bottomEdge: [CGPoint] = []

//     for i in 0..<count {
//         let p = strokePoints[i]
//         let prev = i > 0 ? strokePoints[i - 1] : strokePoints[i]
//         let next = i < count - 1 ? strokePoints[i + 1] : strokePoints[i]

//         // direction vector
//         let dx = next.x - prev.x
//         let dy = next.y - prev.y
//         let len = max(sqrt(dx * dx + dy * dy), 0.001)
//         let nx = -dy / len
//         let ny = dx / len

//         // pressure simulation
//         let t = CGFloat(i) / CGFloat(count - 1)
//         let pressure = bellPressure(t: t)
//         let localWidth = width * pressure
//         let offset = localWidth / 2

//         topEdge.append(CGPoint(x: p.x + nx * offset, y: p.y + ny * offset))
//         bottomEdge.append(CGPoint(x: p.x - nx * offset, y: p.y - ny * offset))
//     }

//     var path = Path()
//     path.move(to: topEdge[0])
//     for pt in topEdge.dropFirst() {
//         path.addLine(to: pt)
//     }

//     // End cap
//     let capEnd = strokePoints.last!
//     let dxEnd = capEnd.x - strokePoints[strokePoints.count - 2].x
//     let dyEnd = capEnd.y - strokePoints[strokePoints.count - 2].y
//     let angleEnd = atan2(dyEnd, dxEnd)
//     let endRadius = width * bellPressure(t: 1) / 2
//     addRoundCap(path: &path, center: capEnd, radius: endRadius, angle: angleEnd)

//     for pt in bottomEdge.reversed() {
//         path.addLine(to: pt)
//     }

//     // Start cap
//     let capStart = strokePoints.first!
//     let dxStart = strokePoints[1].x - capStart.x
//     let dyStart = strokePoints[1].y - capStart.y
//     let angleStart = atan2(dyStart, dxStart)
//     let startRadius = width * bellPressure(t: 0) / 2
//     addRoundCap(path: &path, center: capStart, radius: startRadius, angle: angleStart)
//     path.closeSubpath()
//     return path
// }

// func addRoundCap(path: inout Path, center: CGPoint, radius: CGFloat, angle: CGFloat, samples: Int = 10) {
//     let delta = -2 * .pi / CGFloat(samples - 1)
//     for i in 0..<samples {
//         let a = angle + .pi + delta * CGFloat(i)
//         let x = center.x + cos(a) * radius
//         let y = center.y + sin(a) * radius
//         path.addLine(to: CGPoint(x: x, y: y))
//     }
// }

// func sampleCubicBezier(p0: CGPoint, c1: CGPoint, c2: CGPoint, p3: CGPoint, samples: Int) -> [CGPoint] {
//     var points: [CGPoint] = []
//     for i in 0...samples {
//         let t = CGFloat(i) / CGFloat(samples)
//         let mt = 1 - t
//         let a = mt * mt * mt
//         let b = 3 * mt * mt * t
//         let c = 3 * mt * t * t
//         let d = t * t * t
//         let x = a * p0.x + b * c1.x + c * c2.x + d * p3.x
//         let y = a * p0.y + b * c1.y + c * c2.y + d * p3.y
//         points.append(CGPoint(x: x, y: y))
//     }
//     return points
// }
