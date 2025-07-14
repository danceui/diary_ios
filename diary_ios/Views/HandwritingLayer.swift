import PencilKit
import UIKit

class HandwritingLayer: PKCanvasView {
    var currentTool: Tool = .pen
    var touchFinished = false

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isOpaque = false
        drawingPolicy = .pencilOnly
    }

    // MARK: - 监听触摸
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touchFinished = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchFinished = true
    }
    
    // MARK: - 切换工具
    func toolDidChange(tool: Tool, color: UIColor = .black, width: CGFloat = 2.0) {
        currentTool = tool
        switch tool {
        case .pen:
            self.tool = PKInkingTool(.pen, color: color, width: width)
        case .highlighter:
            self.tool = PKInkingTool(.marker, color: color, width: width)
        // case .eraser:
        //     self.tool = PKEraserTool(.vector) // 或 .bitmap 根据需要切换
        default:
            break
        }
    }
}

extension HandwritingLayer {
    var isEmpty: Bool {
        return drawing.strokes.isEmpty
    }
}