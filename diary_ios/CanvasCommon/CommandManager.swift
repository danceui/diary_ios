import PencilKit

protocol CanvasCommand {
    func execute(on handwritingLayer: HandwritingLayer)
    func undo(on handwritingLayer: HandwritingLayer)
}

class AddStrokeCommand: CanvasCommand {
    private let stroke: PKStroke
    private var hasAppearedOnce: Bool
    
    init(stroke: PKStroke, hasAppearedOnce: Bool) {
        self.stroke = stroke
        self.hasAppearedOnce = hasAppearedOnce
    }

    func execute(on handwritingLayer: HandwritingLayer) {
        guard hasAppearedOnce else {
            hasAppearedOnce = true
            return 
        }
        handwritingLayer.drawing.strokes.append(stroke)
        printDrawingInfo(drawing: handwritingLayer.drawing)
    }

    func undo(on handwritingLayer: HandwritingLayer) {
        if !handwritingLayer.drawing.strokes.isEmpty {
            handwritingLayer.drawing.strokes.removeLast()
            printDrawingInfo(drawing: handwritingLayer.drawing)
        }
    }
}

class EraseStrokesCommand: CanvasCommand {
    private let erasedStrokes: [PKStroke]

    init(erasedStrokes: [PKStroke]) {
        self.erasedStrokes = erasedStrokes
    }

    func execute(on handwritingLayer: HandwritingLayer) {
        // 通常执行已在用户交互中完成，这里什么都不做
    }

    func undo(on handwritingLayer: HandwritingLayer) {
        handwritingLayer.drawing.strokes.append(contentsOf: erasedStrokes)
    }
}
