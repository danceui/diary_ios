import PencilKit
import UIKit

class HandwritingCanvas: PKCanvasView {
    var waitingForStrokeFinish = false

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        drawingPolicy = .pencilOnly  // 也可以设置为 .anyInput
        alwaysBounceVertical = false
        isOpaque = false
    }

    // MARK: - 监听笔画
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        waitingForStrokeFinish = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        waitingForStrokeFinish = true
    }

    // MARK: - 设置笔刷
    func setBrush(color: UIColor, width: CGFloat, type: String) {
        let inkType: PKInkingTool.InkType
        switch type {
        case "pen": inkType = .pen
        case "marker": inkType = .marker
        case "pencil": inkType = .pencil
        default: inkType = .pen
        }
        tool = PKInkingTool(inkType, color: color, width: width)
    }

    func setEraser(partial: Bool, size: CGFloat = 10) {
        tool = PKEraserTool(partial ? .bitmap : .vector, width: size)
    }

    func safeUpdateDrawing(_ newDrawing: PKDrawing) {
        // 通过临时切换工具清除内部缓存
        self.isUserInteractionEnabled = false
        let currentTool = self.tool
        self.tool = PKInkingTool(.pen, color: .clear, width: 2)
        self.drawing = newDrawing
        self.setNeedsDisplay()
        self.tool = currentTool
        self.isUserInteractionEnabled = true
    }
}
