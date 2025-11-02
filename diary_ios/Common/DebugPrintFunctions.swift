import UIKit
import PencilKit

func addTestBorder(for view: UIView, color: UIColor = .red, width: CGFloat = 2.0) {
    view.layer.borderColor = color.cgColor
    view.layer.borderWidth = width
}

func printLifeCycleInfo(context: String, for view: UIView){
    // print("⚙️ \(context)")
    // print("   📌 view.frame.size: \(formatSize(view.frame.size))")
}

func printStackInfo(undoStack: [CanvasCommand], redoStack: [CanvasCommand]) {
    print("📦 UndoStack: \(undoStack.count) commands, RedoStack: \(redoStack.count) commands.")
    // for (index, command) in undoStack.enumerated() {
    //     let typeName = String(describing: type(of: command))
    //     print("  [\(index)] \(typeName)")
    // }
}

func printDrawingInfo(drawing: PKDrawing) {
    print("🖊️ Drawing has \(drawing.strokes.count) strokes.")
    for (index, stroke) in drawing.strokes.enumerated() {
        print("   Stroke \(index): \(stroke.path.count) points.")
    //     let pointCount = stroke.path.count
    //     let toolType = stroke.ink.inkType.rawValue
    //     let color = stroke.ink.color
    //     let width = stroke.ink.width
    //     print("""
    //     ┌─ Stroke \(index):
    //     │  • Points: \(pointCount)
    //     │  • Tool: \(toolType)
    //     │  • Color: \(color)
    //     │  • Width: \(width)
    //     └──────────────────────
    //     """)
    }
}

func printLayerStrokesInfo(info: [LayerStrokes], context: String) {
    print("\(context)", terminator: ": ")
    for (i, item) in info.enumerated() {
        if i == info.count - 1 {
            print("\(item.indexedStrokes.count)", terminator: " ")
        } else {
            print("\(item.indexedStrokes.count) +", terminator: " ")
        }
    }
    print("Strokes.")
}

func printIndexedStrokesInfo(indexedStrokes: [IndexedStroke], index: Int) {
    // for (i, s) in indexedStrokes.enumerated() {
    //     print("         • Stroke \(s.index) has \(s.stroke.path.count) points")
    // }
}
