import PencilKit

protocol CanvasCommand {
    func execute()
    func undo()
}

// MARK: - AddStroke
class AddStrokeCommand: CanvasCommand {
    private let stroke: PKStroke
    private var strokesAppearedOnce: Bool
    private unowned let handwritingLayer: HandwritingLayer
    
    init(stroke: PKStroke, strokesAppearedOnce: Bool, layer: HandwritingLayer) {
        self.stroke = stroke
        self.strokesAppearedOnce = strokesAppearedOnce
        self.handwritingLayer = layer
    }

    func execute() {
        guard strokesAppearedOnce else {
            strokesAppearedOnce = true
            return 
        }
        handwritingLayer.drawing.strokes.append(stroke)
    }

    func undo() {
        if !handwritingLayer.drawing.strokes.isEmpty {
            handwritingLayer.drawing.strokes.removeLast()
        }
    }
}

// MARK: - MultiErase
class MultiEraseCommand: CanvasCommand {
    private var eraseInfo: [(HandwritingLayer, [IndexedStroke])]
    private var strokesErasedOnce: Bool = false

    init(eraseInfo: [(HandwritingLayer, [IndexedStroke])], strokesErasedOnce: Bool) {
        self.eraseInfo = eraseInfo
        self.strokesErasedOnce = strokesErasedOnce
    }
    
    func execute() {
        guard strokesErasedOnce else {
            strokesErasedOnce = true
            return
        }
        for (layer, indexedStrokes) in eraseInfo {
            let current = layer.drawing.strokes
            let remaining = current.enumerated().filter { (i, s) in
                !indexedStrokes.contains { indexed in 
                    indexed.index == i && isStrokeEqual(indexed.stroke, s) 
                }
            }.map { $0.element }
            layer.drawing = PKDrawing(strokes: remaining)
        }
    }

    func undo() {
        for (layer, indexedStrokes) in eraseInfo {
            var current = layer.drawing.strokes
            for (i, s) in indexedStrokes.sorted(by: { $0.index < $1.index }) {
                current.insert(s, at: min(i, current.count))
            }
            layer.drawing = PKDrawing(strokes: current)
        }
    }
}

// MARK: - AddSticker
class AddStickerCommand: CanvasCommand {
    private let sticker: Sticker
    private unowned let stickerLayer: StickerLayer

    init(sticker: Sticker, stickerLayer: StickerLayer) {
        self.sticker = sticker
        self.stickerLayer = stickerLayer
    }

    func execute() {
        let view = StickerView(sticker: sticker)
        stickerLayer.stickers.append(sticker)
        stickerLayer.stickerViews.append(view)
        stickerLayer.addSubview(view)
    }

    func undo() {
        if !stickerLayer.stickers.isEmpty {
            stickerLayer.stickers.removeLast()
            let view = stickerLayer.stickerViews.removeLast()
            view.removeFromSuperview()
        }
    }
}

// MARK: - MoveLasso
class MoveLassoCommand: CanvasCommand {
    private var lassoStrokesInfo: [(layer: PKCanvasView, indexedStrokes: [(Int, PKStroke)])]
    private var transform: CGAffineTransform
    private var originalLassoPath: UIBezierPath
    private var strokesMovedOnce: Bool = false
    private unowned let lassoLayer: LassoLayer

    init(lassoStrokesInfo: [(PKCanvasView, [(Int, PKStroke)])], lassoLayer: LassoLayer, transform: CGAffineTransform, strokesMovedOnce: Bool) {
        self.lassoStrokesInfo = lassoStrokesInfo
        self.lassoLayer = lassoLayer
        self.originalLassoPath = lassoLayer.originalLassoPath
        self.transform = transform
        self.strokesMovedOnce = strokesMovedOnce
    }

    func execute() {
        guard strokesMovedOnce else {
            strokesMovedOnce = true
            return
        }
        transformStrokes(lassoStrokesInfo: lassoStrokesInfo, transform: transform)
        lassoLayer.updateLassoPath(originalLassoPath: originalLassoPath, transform: transform)
    }

    func undo() {
        transformStrokes(lassoStrokesInfo: lassoStrokesInfo, transform: CGAffineTransform.identity)
        lassoLayer.updateLassoPath(originalLassoPath: originalLassoPath, transform: CGAffineTransform.identity)
    }

}

// class EraseStrokesCommand: CanvasCommand {
//     private let erasedStrokes: [PKStroke]
//     private var strokesErasedOnce: Bool
//     private unowned let handwritingLayer: HandwritingLayer

//     init(erasedStrokes: [PKStroke], strokesErasedOnce: Bool, layer: HandwritingLayer) {
//         self.erasedStrokes = erasedStrokes
//         self.strokesErasedOnce = strokesErasedOnce
//         self.handwritingLayer = layer
//     }

//     func execute() {
//         guard strokesErasedOnce else {
//             strokesErasedOnce = true
//             return 
//         }
//         let currentStrokes = handwritingLayer.drawing.strokes
//         let remainingStrokes = currentStrokes.filter { stroke in
//             !erasedStrokes.contains(where: { isStrokeEqual($0, stroke) })
//         }
//         handwritingLayer.drawing = PKDrawing(strokes: remainingStrokes)
//     }

//     func undo() {
//         handwritingLayer.drawing.strokes.append(contentsOf: erasedStrokes)
//     }
// }
