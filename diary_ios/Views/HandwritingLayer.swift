import PencilKit
import UIKit

class HandwritingLayer: PKCanvasView {
    var touchFinished = false
    var isEmpty: Bool {
        return drawing.strokes.isEmpty
    }

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        drawingPolicy = .pencilOnly
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    func setTool(tool: Tool, color: UIColor = .black, width: CGFloat = 2.0) {
        switch tool {
        case .pen:
            self.tool = PKInkingTool(.pen, color: color, width: width)
        case .highlighter:
            self.tool = PKInkingTool(.marker, color: color, width: width)
        default:
            break
        }
    }
}