import PencilKit

protocol CanvasCommand {
    func execute(on handwritingLayer: HandwritingLayer)
    func undo(on handwritingLayer: HandwritingLayer)
}

class AddStrokeCommand: CanvasCommand {
    let stroke: PKStroke
    
    init(stroke: PKStroke) {
        self.stroke = stroke
    }

    func execute(on handwritingLayer: HandwritingLayer) {
        handwritingLayer.add(stroke: stroke)
    }

    func undo(on handwritingLayer: HandwritingLayer) {
        handwritingLayer.remove()
    }
}
