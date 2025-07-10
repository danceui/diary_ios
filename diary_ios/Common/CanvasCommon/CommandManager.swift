import PencilKit

protocol CanvasCommand {
    func execute()
    func undo()
}

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

class EraseStrokesCommand: CanvasCommand {
    private let erasedStrokes: [PKStroke]
    private var strokesErasedOnce: Bool
    private unowned let handwritingLayer: HandwritingLayer

    init(erasedStrokes: [PKStroke], strokesErasedOnce: Bool, layer: HandwritingLayer) {
        self.erasedStrokes = erasedStrokes
        self.strokesErasedOnce = strokesErasedOnce
        self.handwritingLayer = layer
    }

    func execute() {
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

    func undo() {
        handwritingLayer.drawing.strokes.append(contentsOf: erasedStrokes)
    }
}

class AddStickerCommand: CanvasCommand {
    private let sticker: Sticker
    private unowned let stickerLayer: StickerLayer

    init(sticker: Sticker, layer: StickerLayer) {
        self.sticker = sticker
        self.stickerLayer = layer
    }

    func execute() {
        stickerLayer.addSticker(sticker)
    }

    func undo() {
        if !stickerLayer.stickers.isEmpty {
            stickerLayer.stickers.removeLast()
            stickerLayer.updateStickersView()
        }
    }
}
