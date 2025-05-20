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
        allowsFingerDrawing = false // 若需支持手指绘图，可以设置 true
    }

    // MARK: - Listening touches
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        waitingForStrokeFinish = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        waitingForStrokeFinish = true
    }

    // MARK: - Set tools
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
}