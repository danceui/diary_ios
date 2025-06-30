import PencilKit

class CanvasState {
    var drawing: PKDrawing
    // var stickers: [StickerModel] = []
    // var texts: [TextModel] = []

    // init(drawing: PKDrawing = PKDrawing(), stickers: [StickerModel] = [], texts: [TextModel] = []) {
    init(drawing: PKDrawing = PKDrawing()) {
        self.drawing = drawing
        // self.stickers = stickers
        // self.texts = texts
    }

    func clone() -> CanvasState {
        // 深拷贝，避免引用干扰
        // return CanvasState(drawing: drawing, stickers: stickers.map { $0.copy() }, texts: texts.map { $0.copy() })
        return CanvasState(drawing: drawing)
    }
}

protocol CanvasCommand {
    func execute(on state: CanvasState)
    func undo(on state: CanvasState)
}

class DrawStrokeCommand: CanvasCommand {
    let stroke: PKStroke
    
    init(stroke: PKStroke) {
        self.stroke = stroke
    }

    func execute(on state: CanvasState) {
        state.drawing.strokes.append(stroke)
    }

    func undo(on state: CanvasState) {
        if !state.drawing.strokes.isEmpty {
            state.drawing.strokes.removeLast()
        }
    }
}