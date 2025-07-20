import UIKit
import PencilKit
import CoreImage

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

func generateAlphaMaskPath(from image: UIImage, in frame: CGRect) -> UIBezierPath? {
guard let cgImage = image.cgImage else { return nil }

let width = cgImage.width
let height = cgImage.height
let colorSpace = CGColorSpaceCreateDeviceGray()
let bytesPerRow = width
var pixelData = [UInt8](repeating: 0, count: width * height)

guard let context = CGContext(data: &pixelData,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: 0) else {
    return nil
}

context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

let path = UIBezierPath()
for y in 0..<height {
    for x in 0..<width {
        let alpha = pixelData[y * width + x]
        if alpha > 10 {
            let point = CGPoint(x: CGFloat(x) / CGFloat(width) * frame.width,
                                y: CGFloat(y) / CGFloat(height) * frame.height)
            if path.isEmpty {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
    }
}
path.close()
return path
}