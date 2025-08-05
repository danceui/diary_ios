import UIKit
import SwiftUI

/// Returns a bell-shaped pressure value between min and max pressure
func bellPressure(t: CGFloat, minPressure: CGFloat = 0.0, maxPressure: CGFloat = 1.0) -> CGFloat {
    let clampedT = max(0.0, min(1.0, t))
    let base = 1.0 - pow((clampedT - 0.5) * 2, 2)
    return minPressure + base * (maxPressure - minPressure)
}

func generatePenPath(
    from bezierSegments: [(CGPoint, CGPoint, CGPoint, CGPoint)],
    width: CGFloat,
    minPressure: CGFloat = 0.2,
    maxPressure: CGFloat = 1.0,
    samplesPerSegment: Int = 20) -> Path {
    var strokePoints: [CGPoint] = []

    for (p0, c1, c2, p3) in bezierSegments {
        let segmentPoints = sampleCubicBezier(p0: p0, c1: c1, c2: c2, p3: p3, samples: samplesPerSegment)
        strokePoints.append(contentsOf: segmentPoints.dropFirst())
    }

    let count = strokePoints.count
    var topEdge: [CGPoint] = []
    var bottomEdge: [CGPoint] = []

    for i in 0..<count {
        let p = strokePoints[i]
        let prev = i > 0 ? strokePoints[i - 1] : strokePoints[i]
        let next = i < count - 1 ? strokePoints[i + 1] : strokePoints[i]

        // direction vector
        let dx = next.x - prev.x
        let dy = next.y - prev.y
        let len = max(sqrt(dx * dx + dy * dy), 0.001)
        let nx = -dy / len
        let ny = dx / len

        // pressure simulation
        let t = CGFloat(i) / CGFloat(count - 1)
        let pressure = bellPressure(t: t, minPressure: 0.2, maxPressure: 1.0)
        let localWidth = width * pressure
        let offset = localWidth / 2

        topEdge.append(CGPoint(x: p.x + nx * offset, y: p.y + ny * offset))
        bottomEdge.append(CGPoint(x: p.x - nx * offset, y: p.y - ny * offset))
    }

    var path = Path()
    path.move(to: topEdge[0])
    for pt in topEdge.dropFirst() {
        path.addLine(to: pt)
    }
    for pt in bottomEdge.reversed() {
        path.addLine(to: pt)
    }
    path.closeSubpath()

    return path
}

// Bézier curve sampler
func sampleCubicBezier(p0: CGPoint, c1: CGPoint, c2: CGPoint, p3: CGPoint, samples: Int) -> [CGPoint] {
    var points: [CGPoint] = []
    for i in 0...samples {
        let t = CGFloat(i) / CGFloat(samples)
        let mt = 1 - t
        let a = mt * mt * mt
        let b = 3 * mt * mt * t
        let c = 3 * mt * t * t
        let d = t * t * t
        let x = a * p0.x + b * c1.x + c * c2.x + d * p3.x
        let y = a * p0.y + b * c1.y + c * c2.y + d * p3.y
        points.append(CGPoint(x: x, y: y))
    }
    return points
}
