import UIKit
import PencilKit

// MARK: - 笔画相关
func mergeUniqueStrokes(existing: [IndexedStroke], new: [IndexedStroke]) -> [IndexedStroke] {
    var result = existing
    for n in new {
        let duplicated = result.contains { r in
            r.index == n.index && r.stroke.isEqualTo(n.stroke)
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

func transformStrokes(lassoStrokesInfo: [LayerStrokes], transform: CGAffineTransform) {
    for info in lassoStrokesInfo {
        var allStrokes = info.layer.drawing.strokes
        for (index, stroke) in info.indexedStrokes {
            guard index >= 0, index < allStrokes.count else { continue }
            allStrokes[index] = transformStroke(stroke: stroke, by: transform)
        }
        info.layer.drawing = PKDrawing(strokes: allStrokes)
    }
}