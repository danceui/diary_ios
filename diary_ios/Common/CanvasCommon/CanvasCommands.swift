import PencilKit

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

// class EraseStrokesCommand: CanvasCommand {
//     private let erasedStrokes: [PKStroke]
//     private var strokesErasedOnce: Bool
//     private unowned let handwritingLayer: HandwritingLayer

//     init(erasedStrokes: [PKStroke], strokesErasedOnce: Bool, layer: HandwritingLayer) {
//         self.erasedStrokes = erasedStrokes
//         self.strokesErasedOnce = strokesErasedOnce
//         self.handwritingLayer = layer
//     }

//     func execute() {
//         guard strokesErasedOnce else {
//             strokesErasedOnce = true
//             return 
//         }
//         let currentStrokes = handwritingLayer.drawing.strokes
//         let remainingStrokes = currentStrokes.filter { stroke in
//             !erasedStrokes.contains(where: { isStrokeEqual($0, stroke) })
//         }
//         handwritingLayer.drawing = PKDrawing(strokes: remainingStrokes)
//     }

//     func undo() {
//         handwritingLayer.drawing.strokes.append(contentsOf: erasedStrokes)
//     }
// }

class MultiEraseCommand: CanvasCommand {
    private var layerToErasedStrokes: [(layer: HandwritingLayer, strokes: [PKStroke])]
    private var strokesErasedOnce: Bool = false

    init(layerToErasedStrokes: [(HandwritingLayer, [PKStroke])], strokesErasedOnce: Bool) {
        self.layerToErasedStrokes = layerToErasedStrokes
        self.strokesErasedOnce = strokesErasedOnce
    }
    
    func execute() {
        guard strokesErasedOnce else {
            strokesErasedOnce = true
            return 
        }
        for (layer, strokes) in layerToErasedStrokes {
            let current = layer.drawing.strokes
            let remaining = current.filter { stroke in
                !strokes.contains(where: { isStrokeEqual($0, stroke) })
            }
            layer.drawing = PKDrawing(strokes: remaining)
        }
    }

    func undo() {
        for (layer, strokes) in layerToErasedStrokes {
            layer.drawing.strokes.append(contentsOf: strokes)
        }
    }
}

class AddStickerCommand: CanvasCommand {
    private let sticker: Sticker
    private unowned let stickerLayer: StickerLayer

    init(sticker: Sticker, stickerLayer: StickerLayer) {
        self.sticker = sticker
        self.stickerLayer = stickerLayer
    }

    func execute() {
        let view = StickerView(sticker: sticker)
        stickerLayer.stickers.append(sticker)
        stickerLayer.stickerViews.append(view)
        stickerLayer.addSubview(view)
    }

    func undo() {
        if !stickerLayer.stickers.isEmpty {
            stickerLayer.stickers.removeLast()
            let view = stickerLayer.stickerViews.removeLast()
            view.removeFromSuperview()
        }
    }
}
