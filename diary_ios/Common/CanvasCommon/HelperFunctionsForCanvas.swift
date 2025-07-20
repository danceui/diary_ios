import UIKit
import PencilKit

func isStrokeEqual(_ lhs: PKStroke, _ rhs: PKStroke) -> Bool {
    // 快速比较常用字段（颜色、宽度、笔类型）
    guard lhs.ink.inkType == rhs.ink.inkType,
          lhs.ink.color == rhs.ink.color,
          lhs.path.count == rhs.path.count,
          lhs.transform == rhs.transform else {
        return false
    }
    for i in 0..<lhs.path.count {
        let lPoint = lhs.path[i].location
        let rPoint = rhs.path[i].location
        if lPoint != rPoint {
            return false
        }
    }
    return true
}

func strokeIntersectsRect(stroke: PKStroke, eraserRect: CGRect) -> Bool {
    return stroke.renderBounds.intersects(eraserRect)
}

func mergeUniqueStrokes(existing: [IndexedStroke], new: [IndexedStroke]) -> [IndexedStroke] {
    var result = existing
    for n in new {
        let duplicated = result.contains { r in
            r.index == n.index && isStrokeEqual(r.stroke, n.stroke)
        }
        if !duplicated { result.append(n) }
    }
    return result
}

func transformStroke(stroke: PKStroke, by transform: CGAffineTransform) -> PKStroke {
    let newPoints = stroke.path.map { point in
        let newLocation = point.location.applying(transform)
        return PKStrokePoint(
            location: newLocation,
            timeOffset: point.timeOffset,
            size: point.size,
            opacity: point.opacity,
            force: point.force,
            azimuth: point.azimuth,
            altitude: point.altitude
        )
    }
    let newPath = PKStrokePath(controlPoints: newPoints, creationDate: stroke.path.creationDate)
    return PKStroke(ink: stroke.ink, path: newPath)
}

func transformStrokes(lassoStrokesInfo: [(layer: PKCanvasView, indexedStrokes: [(Int, PKStroke)])], transform: CGAffineTransform) {
    for (layer, strokes) in lassoStrokesInfo {
        var allStrokes = layer.drawing.strokes
        for (index, stroke) in strokes {
            allStrokes[index] = transformStroke(stroke: stroke, by: transform)
        }
        layer.drawing = PKDrawing(strokes: allStrokes)
    }
}

func generateLassoPathFromAlpha(image: UIImage, in frame: CGRect, alphaThreshold: UInt8 = 20, margin: CGFloat = 8) -> UIBezierPath? {
    guard let cgImage = image.cgImage else { return nil }

    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8
    var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

    guard let context = CGContext(data: &pixelData,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: bitsPerComponent,
                                  bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    // 蒙版图像：记录哪些点是可见的
    var mask = Array(repeating: false, count: width * height)
    for y in 0..<height {
        for x in 0..<width {
            let index = (y * width + x) * 4
            let alpha = pixelData[index + 3]
            if alpha > alphaThreshold {
                mask[y * width + x] = true
            }
        }
    }

    // 提取最外圈边缘点（扫描法）
    var edgePoints: [CGPoint] = []
    for y in 1..<height-1 {
        for x in 1..<width-1 {
            let i = y * width + x
            if mask[i] {
                let neighbors = [
                    mask[(y-1)*width + x],
                    mask[(y+1)*width + x],
                    mask[y*width + (x-1)],
                    mask[y*width + (x+1)]
                ]
                if neighbors.contains(false) {
                    edgePoints.append(CGPoint(x: x, y: y))
                }
            }
        }
    }

    guard edgePoints.count > 2 else { return nil }

    // 将点映射到 frame 坐标
    let scaleX = frame.width / CGFloat(width)
    let scaleY = frame.height / CGFloat(height)
    let transformedPoints = edgePoints.map {
        CGPoint(x: CGFloat($0.x) * scaleX + frame.origin.x,
                y: CGFloat($0.y) * scaleY + frame.origin.y)
    }

    // 用 convex hull 包裹
    let hull = convexHull(transformedPoints)
    guard hull.count > 2 else { return nil }

    let path = UIBezierPath()
    path.move(to: hull[0])
    for pt in hull.dropFirst() {
        path.addLine(to: pt)
    }
    path.close()

    // 可选放大
    let expandedPath = path.cgPath.copy(strokingWithWidth: margin * 2,
                                        lineCap: .round,
                                        lineJoin: .round,
                                        miterLimit: 0)
    return UIBezierPath(cgPath: expandedPath)
}

func convexHull(_ points: [CGPoint]) -> [CGPoint] {
    let sorted = points.sorted { $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x }

    func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    }

    var lower: [CGPoint] = []
    for p in sorted {
        while lower.count >= 2 && cross(lower[lower.count-2], lower[lower.count-1], p) <= 0 {
            lower.removeLast()
        }
        lower.append(p)
    }

    var upper: [CGPoint] = []
    for p in sorted.reversed() {
        while upper.count >= 2 && cross(upper[upper.count-2], upper[upper.count-1], p) <= 0 {
            upper.removeLast()
        }
        upper.append(p)
    }

    lower.removeLast()
    upper.removeLast()
    return lower + upper
}