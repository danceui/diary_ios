import PencilKit
import UIKit

class HandwritingLayer: PKCanvasView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCanvas()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCanvas()
    }

    private func setupCanvas() {
        backgroundColor = .clear
        addSubview(eraserPreviewView)
        isOpaque = false
        drawingPolicy = .pencilOnly
    }

    // MARK: - 监听触摸
    var strokeFinished = false

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        strokeFinished = true
        eraserPreviewView.isHidden = true
        refreshDrawingIfEraser()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        strokeFinished = true
        eraserPreviewView.isHidden = true
        refreshDrawingIfEraser()
    }

    private func refreshDrawingIfEraser() {
        if self.tool is PKEraserTool {
            let current = self.drawing
            self.drawing = current
        }
    }

    // MARK: - 橡皮预览
    private let eraserPreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 1 // 先设为1，后面动态更新
        view.isHidden = true
        return view
    }()

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard let touch = touches.first, self.tool is PKEraserTool else { return }
        let point = touch.location(in: self)

        // 根据橡皮大小设置预览圈
        if let eraser = self.tool as? PKEraserTool {
            let eraserSize: CGFloat = 20 // 可根据实际需要动态设置
            let frame = CGRect(x: point.x - eraserSize / 2,
                            y: point.y - eraserSize / 2,
                            width: eraserSize,
                            height: eraserSize)
            eraserPreviewView.frame = frame
            eraserPreviewView.layer.cornerRadius = eraserSize / 2
            eraserPreviewView.isHidden = false
        }
    }

    // MARK: - 切换工具
    func toolDidChange(tool: Tool, color: UIColor, width: CGFloat) {
        guard tool.isHandwriting else { return }
        switch tool {
        case .pen:
            self.tool = PKInkingTool(.pen, color: color, width: width)
        case .highlighter:
            self.tool = PKInkingTool(.marker, color: color, width: width)
        case .eraser:
            self.tool = PKEraserTool(.vector) // 或 .bitmap 根据需要切换
        default:
            break
        }
    }
}
