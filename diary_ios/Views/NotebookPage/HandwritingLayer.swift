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
        touchFinished = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchFinished = true
    }
    
    // MARK: - 切换工具
    func setTool(tool: Tool, style: ToolStyle?) {
        let color = style?.color ?? UIColor.black
        let finalColor: UIColor
        if let opacity = style?.opacity {
            finalColor = color.withAlphaComponent(opacity)
        } else {
            finalColor = color
        }
        let width = style?.width ?? 4

        switch tool {
        case .pen:
            self.tool = PKInkingTool(.pen, color: finalColor, width: width)
        case .highlighter:
            self.tool = PKInkingTool(.marker, color: finalColor, width: width)
        case .monoline:
            self.tool = PKInkingTool(.monoline, color: finalColor, width: width)
        default:
            break
        }
    }
}