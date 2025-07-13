import PencilKit

protocol CanvasCommand {
    func execute()
    func undo()
}

class AddStrokeCommand: CanvasCommand {
    private let stroke: PKStroke
    private var strokesAppearedOnce: Bool
    private unowned let handwritingInputLayer: HandwritingInputLayer
    
    init(stroke: PKStroke, strokesAppearedOnce: Bool, layer: HandwritingInputLayer) {
        self.stroke = stroke
        self.strokesAppearedOnce = strokesAppearedOnce
        self.handwritingInputLayer = layer
    }

    func execute() {
        guard strokesAppearedOnce else {
            strokesAppearedOnce = true
            return 
        }
        handwritingInputLayer.drawing.strokes.append(stroke)
    }

    func undo() {
        if !handwritingInputLayer.drawing.strokes.isEmpty {
            handwritingInputLayer.drawing.strokes.removeLast()
        }
    }
}

class EraseStrokesCommand: CanvasCommand {
    private let erasedStrokes: [PKStroke]
    private var strokesErasedOnce: Bool
    private unowned let handwritingInputLayer: HandwritingInputLayer

    init(erasedStrokes: [PKStroke], strokesErasedOnce: Bool, layer: HandwritingInputLayer) {
        self.erasedStrokes = erasedStrokes
        self.strokesErasedOnce = strokesErasedOnce
        self.handwritingInputLayer = layer
    }

    func execute() {
        guard strokesErasedOnce else {
            strokesErasedOnce = true
            return 
        }
        let currentStrokes = handwritingInputLayer.drawing.strokes
        let remainingStrokes = currentStrokes.filter { stroke in
            !erasedStrokes.contains(where: { isStrokeEqual($0, stroke) })
        }
        handwritingInputLayer.drawing = PKDrawing(strokes: remainingStrokes)
    }

    func undo() {
        handwritingInputLayer.drawing.strokes.append(contentsOf: erasedStrokes)
    }
}

class AddStickerCommand: CanvasCommand {
    private let stickerView: StickerView
    weak var container: UIView?

    init(stickerView: StickerView, container: UIView) {
        self.stickerView = stickerView
        self.container = container
    }

    func execute() {
        guard let container = container else { return }
        container.addSubview(stickerView)
    }

    func undo() {
        stickerView.removeFromSuperview()
    }
}
