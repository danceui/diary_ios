import PencilKit
import UIKit

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
    private let stickerView: StickerView
    private unowned let container: UIView

    init(stickerView: StickerView, container: UIView) {
        self.stickerView = stickerView
        self.container = container
    }

    func execute() {
        container.addSubview(stickerView)
    }

    func undo() {
        stickerView.removeFromSuperview()
    }
}

class FreezeCanvasCommand: CanvasCommand {
    private var frozenCanvas: HandwritingLayer
    private weak var pageView: NotebookPageView?

    private var previousDelegate: PKCanvasViewDelegate?
    // private var wasUserInteractionEnabled: Bool = true

    init(canvas: HandwritingLayer, pageView: NotebookPageView) {
        self.frozenCanvas = canvas
        self.pageView = pageView
    }

    func execute() {
        // 保存原状态并冻结该 canvas
        previousDelegate = frozenCanvas.delegate
        // wasUserInteractionEnabled = frozenCanvas.isUserInteractionEnabled
        frozenCanvas.delegate = nil
        frozenCanvas.isUserInteractionEnabled = false
    }

    func undo() {
        guard let pageView = pageView else { return }

        // 1. 恢复 canvas 的可编辑状态
        frozenCanvas.delegate = pageView
        frozenCanvas.isUserInteractionEnabled = true

        // 2. 设置为当前 handwritingLayer
        pageView.setHandwritingLayerRestored(from: frozenCanvas)
    }
}