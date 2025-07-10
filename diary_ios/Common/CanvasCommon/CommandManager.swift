import PencilKit

protocol CanvasCommand {
    func execute(on handwritingLayer: HandwritingLayer)
    func undo(on handwritingLayer: HandwritingLayer)
}

class AddStrokeCommand: CanvasCommand {
    private let stroke: PKStroke
    private var strokesAppearedOnce: Bool
    
    init(stroke: PKStroke, strokesAppearedOnce: Bool) {
        self.stroke = stroke
        self.strokesAppearedOnce = strokesAppearedOnce
    }

    func execute(on handwritingLayer: HandwritingLayer) {
        guard strokesAppearedOnce else {
            strokesAppearedOnce = true
            return 
        }
        handwritingLayer.drawing.strokes.append(stroke)
    }

    func undo(on handwritingLayer: HandwritingLayer) {
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

    func execute(on handwritingLayer: HandwritingLayer) {
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

    func undo(on handwritingLayer: HandwritingLayer) {
        handwritingLayer.drawing.strokes.append(contentsOf: erasedStrokes)
    }
}
