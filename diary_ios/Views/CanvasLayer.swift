import PencilKit
import UIKit

class CanvasLayer: PKCanvasView, ToolObserver {
    private(set) var readyToAddSticker = true

    var currentTool: Tool = .pen
    var stickers: [Sticker] = []
    var strokeFinished = false
    var onEraserFinished: (() -> Void)?
    var onStickerAdded: ((Sticker) -> Void)?

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
        ToolManager.shared.addObserver(self) 
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCanvas()
        ToolManager.shared.addObserver(self) 
    }

    // deinit {
    //     ToolManager.shared.removeObserver(self)  //防止内存泄漏
    // }

    private func setupCanvas() {
        backgroundColor = .clear
        addSubview(eraserPreviewView)
        isOpaque = false
        drawingPolicy = .pencilOnly
    }
    
    // MARK: - 切换工具
    func toolDidChange(tool: Tool, color: UIColor, width: CGFloat) {
        currentTool = tool

        switch tool {
        case .pen:
            self.tool = PKInkingTool(.pen, color: color, width: width)
        case .highlighter:
            self.tool = PKInkingTool(.marker, color: color, width: width)
        case .eraser:
            self.tool = PKEraserTool(.vector)
        case .sticker:
            self.tool = PKInkingTool(.pen, color: .clear, width: 0.1)  // 占位工具
        default:
            break
        }
    }
    
    // MARK: - 监听触摸
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }

        switch currentTool {
        case .pen, .highlighter, .eraser:
            strokeFinished = false
        case .sticker:
            guard readyToAddSticker else { return }
            let location = touch.location(in: self)
            let sticker = Sticker(id: UUID(), center: location, name: "star")
            onStickerAdded?(sticker)
            readyToAddSticker = false
        default:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }

        if currentTool == .eraser {
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
        print("Touch Finished")
        switch currentTool {
        case .pen, .highlighter:
            strokeFinished = true
        case .eraser:
            self.drawing = self.drawing
            onEraserFinished?()
        case .sticker:
            readyToAddSticker = true
        default:
            break
        }
        
    }

    func updateStickersView() {
        self.subviews.forEach { $0.removeFromSuperview() }
        for sticker in stickers {
            let view = StickerView(model: sticker)
            self.addSubview(view)
        }
    }
}
