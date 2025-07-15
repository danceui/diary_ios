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
    private var eraseInfo: [(layer: HandwritingLayer, strokes: [IndexedStroke])]
    private var strokesErasedOnce: Bool = false

    init(eraseInfo: [(HandwritingLayer, [IndexedStroke])], strokesErasedOnce: Bool) {
        self.eraseInfo = eraseInfo
        self.strokesErasedOnce = strokesErasedOnce
    }
    
    func execute() {
        guard strokesErasedOnce else {
            strokesErasedOnce = true
            return 
        }
        for (layer, indexedStrokes) in eraseInfo {
            let current = layer.drawing.strokes
            let remaining = current.enumerated().filter { (i, stroke) in
                !indexedStrokes.contains(where: { $0.index == i && isStrokeEqual($0.stroke, stroke) })
            }.map { $0.element }
            layer.drawing = PKDrawing(strokes: remaining)
        }
    }

    func undo() {
        for (layer, indexedStrokes) in eraseInfo {
            var current = layer.drawing.strokes
            // for (index, stroke) in indexedStrokes.sorted(by: { $0.index < $1.index }) {
            //     let safeIndex = min(index, current.count)
            //     current.insert(stroke, at: safeIndex)
            // }
            // layer.drawing = PKDrawing(strokes: current)
            for (index, stroke) in indexedStrokes {
                layer.drawing.strokes.append(stroke)
            }
        }
    }
}

// class MultiEraseCommand: CanvasCommand {
//     private var layerToErasedStrokes: [(layer: HandwritingLayer, strokes: [IndexedStroke])]
//     private var strokesErasedOnce: Bool = false

//     init(eraseInfo: [(HandwritingLayer, [PKStroke])], strokesErasedOnce: Bool) {
//         // 把 eraseInfo 换成带下标的笔画
//         self.layerToErasedStrokes = eraseInfo.map { (layer, strokes) in
//             let current = layer.drawing.strokes
//             var indexedStrokes: [IndexedStroke] = []
//             for (i, s) in current.enumerated() {
//                 if strokes.contains(where: { isStrokeEqual($0, s)}) { 
//                     indexedStrokes.append((i, s))
//                 }
//             }
//             return (layer, indexedStrokes)
//         }
//         self.strokesErasedOnce = strokesErasedOnce
//     }
    
//     func execute() {
//         guard strokesErasedOnce else {
//             strokesErasedOnce = true
//             return 
//         }
//         for (layer, indexedStrokes) in layerToErasedStrokes {
//             let current = layer.drawing.strokes
//             let remaining = current.enumerated().filter { (i, s) in 
//                 !indexedStrokes.contains(where: { $0.index == i && isStrokeEqual($0.stroke, s) })
//             }.map { $0.element }
//             layer.drawing = PKDrawing(strokes: remaining)
//         }
//     }

//     func undo() {
//         for (layer, indexedStrokes) in layerToErasedStrokes {
//             // var current = layer.drawing.strokes
//             // for indexedStroke in indexedStrokes.sorted(by: { $0.index < $1.index }) {
//             //     current.insert(indexedStroke.stroke, at: min(indexedStroke.index, current.count))
//             // }
//             // layer.drawing = PKDrawing(strokes: current)
//             for (index, stroke) in indexedStrokes {
//                 layer.drawing.strokes.append(stroke)
//             }
//         }
//     }
// }

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
