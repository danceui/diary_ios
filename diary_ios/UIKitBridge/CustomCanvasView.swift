import PencilKit
import UIKit

@available(iOS 16.0, *)
class CustomCanvasView: PKCanvasView {
    var waitingForStrokeFinish = false
    var currentTool: Tool = .pen { didSet { updateTool() } }
    var strokeColor: UIColor = .black { didSet { updateTool() } }
    var strokeWidth: CGFloat = 5.0 { didSet { updateTool() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        alwaysBounceVertical = false
        isOpaque = false
        drawingPolicy = .pencilOnly
        updateTool()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    //  MARK: - 设置工具
    private func updateTool() {
        switch currentTool {
        case .pen:
            tool = PKInkingTool(.pen, color: strokeColor, width: strokeWidth)
        case .highlighter:
            tool = PKInkingTool(.marker, color: strokeColor, width: strokeWidth)
        case .eraser:
            tool = PKEraserTool(.vector) // or .bitmap
        }
    }

    func setBrush(color: UIColor, width: CGFloat, type: String) {
        currentTool = .pen
        strokeColor = color
        strokeWidth = width
    }

    func setEraser(partial: Bool, size: CGFloat = 10) {
        currentTool = .eraser
        strokeWidth = size
    }
}