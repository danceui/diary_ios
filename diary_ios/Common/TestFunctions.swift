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

func printAllSnapshotsInfo(snapshots: [PageSnapshot], currentIndex: Int) {
    print("📊 Snapshots Info (Total: \(snapshots.count)):")
    for (index, snapshot) in snapshots.enumerated() {
        let mark = (index == currentIndex) ? "🔸" : "  "
        print("   [#\(index)] StrokeCount: \(snapshot.drawing.strokes.count) \(mark)")
    }
}

func printCanvasDrawingInfo(canvas: PKCanvasView, tag: String = "") {
    let strokes = canvas.drawing.strokes
    print("🖊️ Drawing Info \(tag.isEmpty ? "" : "[\(tag)]"): Total Strokes: \(strokes.count).") 
}
