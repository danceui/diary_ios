import PencilKit
import UIKit

@available(iOS 16.0, *)
class HandwritingCanvas: PKCanvasView {
    var waitingForStrokeFinish: Bool = false

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
        drawingPolicy = .pencilOnly
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

    // MARK: - 设置工具
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
        let currentTool = self.tool
        self.isUserInteractionEnabled = false
        self.tool = PKInkingTool(.pen, color: .clear, width: 1)
        
    RunLoop.main.perform(inModes: [.default]) {
        self.becomeFirstResponder()
        self.resignFirstResponder()
        self.drawing = newDrawing
        self.setNeedsDisplay()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.tool = currentTool
            self.isUserInteractionEnabled = true
        }
    }
    }
}
