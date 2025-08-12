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
    let steps = PreviewConstants.steps // 每个段的采样点数
    let color = style.color?.toColor() ?? .black
    let width = style.width ?? 2.0
    let opacity = style.opacity ?? 1.0

    for i in 0..<steps {
        let t = CGFloat(i) / CGFloat(steps - 1)
        let point = cubicBezier(t: t, p0: start, p1: ctrl1, p2: ctrl2, p3: end) // 计算第 i 点的位置
        let globalT = (CGFloat(segmentIndex) + t) / CGFloat(totalSegments - 1)
        let pressure = bellPressure(t: globalT)
        let radius = width * pressure / 2 // 该处圆的半径
        let dot = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        context.fill(dot, with: .color(color.opacity(opacity)))
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
    let steps = PreviewConstants.steps // 每个段的采样点数
    let color = style.color?.toColor() ?? .black
    let width = style.width ?? 2.0
    let opacity = style.opacity ?? 1.0

    for i in 0..<steps {
        let t = CGFloat(i) / CGFloat(steps - 1) // 将 i 归一化到[0, 1]
        let point = cubicBezier(t: t, p0: start, p1: ctrl1, p2: ctrl2, p3: end) // 计算第 i 点的位置
        let radius = width / 2 // 该处圆的半径
        let dot = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        context.fill(dot, with: .color(color.opacity(opacity)))
    }
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
