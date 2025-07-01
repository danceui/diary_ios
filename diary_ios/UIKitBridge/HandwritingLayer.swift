import PencilKit
import UIKit

class HandwritingLayer: PKCanvasView {
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

    // MARK: - 监听触摸
    var waitingForStrokeFinish = false

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        waitingForStrokeFinish = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        waitingForStrokeFinish = true
    }

    // MARK: - API for Commands
    func add(stroke: PKStroke) {
        self.drawing.strokes.append(stroke)
        printDrawingInfo(drawing: self.drawing)
    }

    func remove() {
        if !self.drawing.strokes.isEmpty {
            self.drawing.strokes.removeLast()
            printDrawingInfo(drawing: self.drawing)
        }
    }
}
