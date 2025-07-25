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
    private var eraseInfo: [LayerStrokes]
    private var strokesErasedOnce: Bool = false

    init(eraseInfo: [LayerStrokes], strokesErasedOnce: Bool) {
        self.eraseInfo = eraseInfo
        self.strokesErasedOnce = strokesErasedOnce
    }
    
    func execute() {
        guard strokesErasedOnce else {
            strokesErasedOnce = true
            return
        }
        for info in eraseInfo {
            let current = info.layer.drawing.strokes
            let remaining = current.enumerated().filter { (i, s) in
                !info.indexedStrokes.contains { indexed in 
                    indexed.index == i && indexed.stroke.isEqualTo(s) 
                }
            }.map { $0.element }
            info.layer.drawing = PKDrawing(strokes: remaining)
        }
    }

    func undo() {
        for info in eraseInfo {
            var current = info.layer.drawing.strokes
            for (i, s) in info.indexedStrokes.sorted(by: { $0.index < $1.index }) {
                current.insert(s, at: min(i, current.count))
            }
            info.layer.drawing = PKDrawing(strokes: current)
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

// MARK: - DeleteSticker
class DeleteStickerCommand: CanvasCommand {
    private var index: Int
    private var stickerView: StickerView
    private unowned let stickerLayer: StickerLayer

    init(indexedStickerView: IndexedStickerView, stickerLayer: StickerLayer) {
        self.index = indexedStickerView.index
        self.stickerView = indexedStickerView.stickerView
        self.stickerLayer = stickerLayer
    }

    func execute() {
        stickerView.removeFromSuperview()
        stickerLayer.stickerViews.remove(at: index)
        stickerLayer.stickers.remove(at: index)
    }

    func undo() {
        stickerLayer.stickerViews.insert(stickerView, at: index)
        stickerLayer.stickers.insert(stickerView.sticker, at: index)
        stickerLayer.addSubview(stickerView) 
    }
}

// MARK: - MoveStrokes
class MoveStrokesCommand: CanvasCommand {
    private var lassoStrokesInfo: [LayerStrokes]
    private var transform: CGAffineTransform
    private var strokesMovedOnce: Bool = false
    private weak var lassoLayer: LassoLayer?

    init(lassoStrokesInfo: [LayerStrokes], lassoLayer: LassoLayer, transform: CGAffineTransform, strokesMovedOnce: Bool) {
        self.lassoStrokesInfo = lassoStrokesInfo
        self.lassoLayer = lassoLayer
        self.transform = transform
        self.strokesMovedOnce = strokesMovedOnce
    }

    func execute() {
        guard strokesMovedOnce else {
            strokesMovedOnce = true
            return
        }
        transformStrokes(lassoStrokesInfo: lassoStrokesInfo, transform: transform)
    }

    func undo() {
        transformStrokes(lassoStrokesInfo: lassoStrokesInfo, transform: CGAffineTransform.identity)
        lassoLayer?.removeLassoPath()
    }
}

// MARK: - MoveSticker
class MoveStickerCommand: CanvasCommand {
    private var stickerView: StickerView
    private var originalCenter: CGPoint
    private let transform: CGAffineTransform
    private var stickerMovedOnce: Bool
    private weak var lassoLayer: LassoLayer?

    init(stickerView: StickerView, lassoLayer: LassoLayer, transform: CGAffineTransform, stickerMovedOnce: Bool) {
        self.stickerView = stickerView
        self.originalCenter = stickerView.sticker.center
        self.transform = transform
        self.stickerMovedOnce = stickerMovedOnce
        self.lassoLayer = lassoLayer
    }

    func execute() {
        guard stickerMovedOnce else {
            stickerMovedOnce = true
            return
        }
        let newCenter = originalCenter.applying(transform)
        stickerView.center = newCenter
        stickerView.sticker.center = newCenter
    }

    func undo() {
        stickerView.center = originalCenter
        stickerView.sticker.center = originalCenter 
        lassoLayer?.removeLassoPath()
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
