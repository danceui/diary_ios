import UIKit
import PencilKit

class IndexedStrokeManager {
    private(set) var selectedStrokes: [IndexedStroke] = []

    // func setIndexedStrokes(_ strokes: [PKStroke], in layer: PKCanvasView) {
    //     selectedStrokes = strokes.enumerated().map { index, stroke in
    //         IndexedStroke(originalStroke: stroke, layer: layer, index: index)
    //     }
    // }

    // func clearSelection() {
    //     selectedStrokes.removeAll()
    // }

    // func translate(by translation: CGPoint) {
    //     for strokeInfo in selectedStrokes {
    //         guard let layer = strokeInfo.layer else { continue }

    //         let translatedStroke = Self.translateStroke(strokeInfo.originalStroke, by: translation)
    //         replaceStroke(in: layer, at: strokeInfo.index, with: translatedStroke)
    //     }
    // }

    // private func replaceStroke(in layer: PKCanvasView, at index: Int, with stroke: PKStroke) {
    //     var strokes = layer.drawing.strokes
    //     guard strokes.indices.contains(index) else { return }
    //     strokes[index] = stroke
    //     layer.drawing = PKDrawing(strokes: strokes)
    // }

    // private static func translateStroke(_ stroke: PKStroke, by translation: CGPoint) -> PKStroke {
    //     let newPath = PKStrokePath(controlPoints: stroke.path.map { point in
    //         let newLoc = CGPoint(x: point.location.x + translation.x, y: point.location.y + translation.y)
    //         return PKStrokePoint(
    //             location: newLoc,
    //             timeOffset: point.timeOffset,
    //             size: point.size,
    //             opacity: point.opacity,
    //             force: point.force,
    //             azimuth: point.azimuth,
    //             altitude: point.altitude
    //         )
    //     }, creationDate: stroke.path.creationDate)

    //     return PKStroke(ink: stroke.ink, path: newPath, transform: .identity, mask: stroke.mask)
    // }
}