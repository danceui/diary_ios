import PencilKit

protocol CanvasCommand {
    func execute()
    func undo()
}

class AddStrokeCommand: CanvasCommand {
    private let stroke: PKStroke
    private var strokesAppearedOnce: Bool
    private var canvasLayer: CanvasLayer
    
    init(stroke: PKStroke, strokesAppearedOnce: Bool, canvasLayer: CanvasLayer) {
        self.stroke = stroke
        self.strokesAppearedOnce = strokesAppearedOnce
        self.canvasLayer = canvasLayer
    }

    func execute() {
        guard strokesAppearedOnce else {
            strokesAppearedOnce = true
            return 
        }
        canvasLayer.drawing.strokes.append(stroke)
    }

    func undo() {
        if !canvasLayer.drawing.strokes.isEmpty {
            canvasLayer.drawing.strokes.removeLast()
        }
    }
}

class EraseStrokesCommand: CanvasCommand {
    private let erasedStrokes: [PKStroke]
    private var strokesErasedOnce: Bool
    private var canvasLayer: CanvasLayer

    init(erasedStrokes: [PKStroke], strokesErasedOnce: Bool, canvasLayer: CanvasLayer) {
        self.erasedStrokes = erasedStrokes
        self.strokesErasedOnce = strokesErasedOnce
        self.canvasLayer = canvasLayer
    }

    func execute() {
        guard strokesErasedOnce else {
            strokesErasedOnce = true
            return 
        }
        let currentStrokes = canvasLayer.drawing.strokes
        let remainingStrokes = currentStrokes.filter { stroke in
            !erasedStrokes.contains(where: { isStrokeEqual($0, stroke) })
        }
        canvasLayer.drawing = PKDrawing(strokes: remainingStrokes)
    }

    func undo() {
        canvasLayer.drawing.strokes.append(contentsOf: erasedStrokes)
    }
}

class AddStickerCommand: CanvasCommand {
    private let sticker: Sticker
    private var canvasLayer: CanvasLayer

    init(sticker: Sticker, canvasLayer: CanvasLayer) {
        self.sticker = sticker
        self.canvasLayer = canvasLayer
    }

    func execute() {
        let view = StickerView(model: sticker)
        canvasLayer.stickers.append(sticker)
        canvasLayer.stickerViews.append(view)
        canvasLayer.addSubview(view)
    }

    func undo() {
        if !canvasLayer.stickers.isEmpty {
            canvasLayer.stickers.removeLast()
            let view = canvasLayer.stickerViews.removeLast()
            view.removeFromSuperview()
        }
    }
}
