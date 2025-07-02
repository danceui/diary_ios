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
        handwritingLayer.add(stroke: stroke)
    }

    func undo(on handwritingLayer: HandwritingLayer) {
        handwritingLayer.remove()
    }
}
