import PencilKit
import UIKit
import os

final class HandwritingLayer: PKCanvasView {
    var touchFinished = false
    var isEmpty: Bool { return drawing.strokes.isEmpty }
    // private let touchLogger = Logger(subsystem: "Notebook", category: "touch")

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        drawingPolicy = .pencilOnly
        allowsFingerDrawing = false
        isMultipleTouchEnabled = false
        isExclusiveTouch = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 监听触摸
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchFinished = true
        print("touchesEnded")
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchFinished = true
        print("touchesCancelled")
        super.touchesCancelled(touches, with: event)
    }
    
    // MARK: - 切换工具
    func setTool(tool: Tool, style: BrushStyle?) {
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
