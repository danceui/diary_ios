import PencilKit

protocol CanvasLayer {}

protocol CanvasCommand {
    func execute(on layer: CanvasLayer)
    func undo(on layer: CanvasLayer)
}

class AddStrokeCommand: CanvasCommand {
    private let stroke: PKStroke
    private var strokesAppearedOnce: Bool
    
    init(stroke: PKStroke, strokesAppearedOnce: Bool) {
        self.stroke = stroke
        self.strokesAppearedOnce = strokesAppearedOnce
    }

    func execute(on layer: CanvasLayer) {
        guard let handwritingLayer = layer as? HandwritingLayer else { return }
        guard strokesAppearedOnce else {
            strokesAppearedOnce = true
            return 
        }
        handwritingLayer.drawing.strokes.append(stroke)
    }

    func undo(on layer: CanvasLayer) {
        guard let handwritingLayer = layer as? HandwritingLayer else { return }
        if !handwritingLayer.drawing.strokes.isEmpty {
            handwritingLayer.drawing.strokes.removeLast()
        }
    }
}

class EraseStrokesCommand: CanvasCommand {
    private let erasedStrokes: [PKStroke]
    private var strokesErasedOnce: Bool

    init(erasedStrokes: [PKStroke], strokesErasedOnce: Bool) {
        self.erasedStrokes = erasedStrokes
        self.strokesErasedOnce = strokesErasedOnce
    }

    func execute(on layer: CanvasLayer) {
        guard let handwritingLayer = layer as? HandwritingLayer else { return }
        guard strokesErasedOnce else {
            strokesErasedOnce = true
            return 
        }

        let currentStrokes = handwritingLayer.drawing.strokes
        let remainingStrokes = currentStrokes.filter { stroke in
            !erasedStrokes.contains(where: { isStrokeEqual($0, stroke) })
        }
        handwritingLayer.drawing = PKDrawing(strokes: remainingStrokes)
    }

    func undo(on layer: CanvasLayer) {
        guard let handwritingLayer = layer as? HandwritingLayer else { return }
        handwritingLayer.drawing.strokes.append(contentsOf: erasedStrokes)
    }
}

class AddStickerCommand: CanvasCommand {
    private let sticker: Sticker

    init(sticker: Sticker) {
        self.sticker = sticker
    }

    func execute(on layer: CanvasLayer) {
        guard let stickerLayer = layer as? StickerLayer else { return }
        stickerLayer.stickers.append(sticker)
    }

    func undo(on layer: CanvasLayer) {
        guard let stickerLayer = layer as? StickerLayer else { return }
        stickerLayer.stickers.remove?
    }
}
