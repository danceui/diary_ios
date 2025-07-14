import PencilKit
import UIKit

class HandwritingLayer: PKCanvasView {
    var currentTool: Tool = .pen
    var touchFinished = false

    private let eraserPreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 1 // 先设为1，后面动态更新
        view.isHidden = true
        return view
    }()

    // MARK: - 初始化
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
        isOpaque = false
        drawingPolicy = .pencilOnly
        
        addSubview(eraserPreviewView)
        eraserPreviewView.isHidden = true
    }

    // MARK: - 监听触摸
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }

        if currentTool.isEraser {
            let location = touch.location(in: self)
            let eraserSize: CGFloat = 20 // 可根据实际需要动态设置
            let frame = CGRect(x: location.x - eraserSize / 2,
                            y: location.y - eraserSize / 2,
                            width: eraserSize,
                            height: eraserSize)
            eraserPreviewView.frame = frame
            eraserPreviewView.layer.cornerRadius = eraserSize / 2
            eraserPreviewView.isHidden = false
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        handleTouchFinished()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        handleTouchFinished()
    }

    private func handleTouchFinished() {
        if currentTool.isDrawing {
            touchFinished = true
        } else if currentTool.isEraser {
            eraserPreviewView.isHidden = true
            self.drawing = self.drawing
        }
    }
    
    // MARK: - 切换工具
    func toolDidChange(tool: Tool, color: UIColor = .black, width: CGFloat = 2.0) {
        currentTool = tool
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
