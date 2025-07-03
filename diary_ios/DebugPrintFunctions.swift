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

func printUndoStackInfo(undoStack: [CanvasCommand]) {
    print("📈 UndoStack has \(undoStack.count) commands.")
    // for (index, command) in undoStack.enumerated() {
    //     let typeName = String(describing: type(of: command))
    //     print("  [\(index)] \(typeName)")
    // }
}

func printDrawingInfo(drawing: PKDrawing) {
    print("🖊️ Drawing has \(drawing.strokes.count) strokes.")
    // for (index, stroke) in drawing.strokes.enumerated() {
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
    // }
}
