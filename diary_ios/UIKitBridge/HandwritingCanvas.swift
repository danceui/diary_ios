import PencilKit
import UIKit

@available(iOS 16.0, *)
class HandwritingCanvas: PKCanvasView, PKCanvasViewDelegate {
    var onStrokeFinished: ((PKStroke) -> Void)?
    private var waitingForStrokeFinish = false
    private var lastStrokeCount = 0

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
        delegate = self
    }

    // 等待笔画完成信号
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        waitingForStrokeFinish = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        waitingForStrokeFinish = true
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard waitingForStrokeFinish else { return }
        waitingForStrokeFinish = false

        let strokes = drawing.strokes
        guard strokes.count > lastStrokeCount else { return }

        let newStroke = strokes.last!
        lastStrokeCount = strokes.count
        onStrokeFinished?(newStroke)
    }

    // 设置工具
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