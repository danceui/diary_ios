import PencilKit
import UIKit

class HandwritingLayer: PKCanvasView, ToolObserver {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCanvas()
        ToolManager.shared.addObserver(self)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCanvas()
        ToolManager.shared.addObserver(self)
    }

    private func setupCanvas() {
        backgroundColor = .clear
        isOpaque = false
        drawingPolicy = .pencilOnly
        // tool = PKInkingTool(.pen, color: .black, width: 5) // 默认工具
    }

    // MARK: - 监听触摸
    var strokeFinished = false

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        strokeFinished = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        strokeFinished = true
    }

    // MARK: - API for commands
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

    // MARK: - 切换工具
    func toolDidChange(tool: Tool, color: UIColor, width: CGFloat) {
        switch tool {
        case .pen:
            self.tool = PKInkingTool(.pen, color: color, width: width)
        case .highlighter:
            self.tool = PKInkingTool(.marker, color: color, width: width)
        case .eraser:
            self.tool = PKEraserTool(.vector) // 或 .bitmap 根据需要切换
        }
    }
}
