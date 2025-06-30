import PencilKit

protocol CanvasCommand {
    func execute(on state: CanvasState)
    func undo(on state: CanvasState)
}

class AddStrokeCommand: CanvasCommand {
    let stroke: PKStroke
    let handwritingLayer: HandwritingLayer
    
    init(stroke: PKStroke, handwritingLayer: HandwritingLayer) {
        self.stroke = stroke
        self.handwritingLayer = handwritingLayer
    }

    func execute() {
        handwritingLayer.add(stroke: stroke)
    }

    func undo() {
        handwritingLayer.remove(stroke: stroke)
    }
}