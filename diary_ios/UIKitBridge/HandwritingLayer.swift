import PencilKit
import UIKit

class HandwritingLayer: PKCanvasView {
    var strokes: [MyStroke] = []
    var waitingForStrokeFinish = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCanvas()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCanvas()
    }

    private func setupCanvas() {
        backgroundColor = .clear
        isOpaque = false
        drawingPolicy = .pencilOnly
        tool = PKInkingTool(.pen, color: .black, width: 5) // 默认工具
    }

    func add(stroke: PKStroke) {
        print("✍️ Draw stroke with \(stroke.path.count) points.")
        let myStroke = MyStroke(id: UUID(), stroke: stroke)
        strokes.append(myStroke)
        refreshCanvas()
    }

    func remove() {
        if !strokes.isEmpty {
            let removed = strokes.last!
            print("✍️ Remove stroke with \(removed.stroke.path.count) points.")
            strokes.removeLast()
            refreshCanvas()
        }
    }

    private func refreshCanvas() {
        waitingForStrokeFinish = false
        self.drawing = PKDrawing(strokes: strokes.map { $0.stroke })
    }

    // MARK: - 监听触摸
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        waitingForStrokeFinish = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        waitingForStrokeFinish = true
    }
}
