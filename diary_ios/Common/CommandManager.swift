import PencilKit

protocol CanvasCommand {
    func execute(on handwritingLayer: HandwritingLayer)
    func undo(on handwritingLayer: HandwritingLayer)
}

class AddStrokeCommand: CanvasCommand {
    let stroke: PKStroke
    private var isUserStroke: Bool
    
    init(stroke: PKStroke, isUserStroke: Bool) {
        self.stroke = stroke
        self.isUserStroke = isUserStroke
    }

    func execute(on handwritingLayer: HandwritingLayer) {
        guard !isUserStroke else { 
            isUserStroke = false
            return 
        }
        handwritingLayer.add(stroke: stroke)
    }

    func undo(on handwritingLayer: HandwritingLayer) {
        handwritingLayer.remove()
    }
}
