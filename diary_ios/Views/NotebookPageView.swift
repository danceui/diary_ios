import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate, ToolObserver {
    private let pageRole: PageRole
    private let isLeft: Bool
    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners
    private(set) var lastEditedTimestamp: Date?

    private var containerView = UIView()
    private var handwritingLayers: [HandwritingLayer] = []
    private var currentHandwritingLayer: HandwritingLayer? // 当前活动的笔画层
    private var stickerInputLayer = StickerInputLayer()

    private var previousStrokes: [PKStroke] = []
    // private var currentStrokeBatch: [PKStroke] = []
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    private var currentTool: Tool = .pen

    // MARK: - 初始化
    init(role: PageRole = .normal, isLeft: Bool = true, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.size))
        setupView()

        ToolManager.shared.addObserver(self)
        if role == .normal {
            addSubview(containerView)
            containerView.addSubview(stickerInputLayer)
            stickerInputLayer.onStickerAdded = { [weak self] sticker in self?.handleStickerAdded(sticker) }
            createNewHandwritingLayer()
        }
    }

    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
        stickerInputLayer.frame = bounds
        for layer in handwritingLayers {
            layer.frame = bounds
        }
    }
    
    private func setupView() {
        backgroundColor = backgroundColorForRole(pageRole)
        layer.cornerRadius = pageCornerRadius
        layer.maskedCorners = isLeft ? leftMaskedCorners : rightMaskedCorners
        layer.masksToBounds = true
    }

    private func createNewHandwritingLayer() {
        print("🔄 Creating new handwriting layer. \(handwritingLayers.count) layers in total.")
        let newLayer = HandwritingLayer()
        newLayer.delegate = self
        newLayer.frame = bounds
        handwritingLayers.append(newLayer)
        currentHandwritingLayer = newLayer
        containerView.addSubview(newLayer)
    }

    private func backgroundColorForRole(_ role: PageRole) -> UIColor {
        switch role {
        case .normal:
            return UIColor(red: 0.76, green: 0.88, blue: 0.77, alpha: 1)
        case .cover, .back:
            return UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        case .empty:
            return .clear
        }
    }

    // MARK: - 切换工具
    func toolDidChange(tool: Tool, color: UIColor, width: CGFloat) {
        if !(currentTool.isDrawing || currentTool.isEraser), (tool.isDrawing || tool.isEraser) {
            if currentHandwritingLayer == nil {
                createNewHandwritingLayer()
            }
        } else if tool.isSticker {
            currentHandwritingLayer = nil
            containerView.bringSubviewToFront(stickerInputLayer)
        }
        currentTool = tool
    }

    // MARK: - 处理笔画
    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard let handwritingLayer = currentHandwritingLayer, handwritingLayer.touchFinished else { return }
        if handwritingLayer.currentTool.isDrawing, let newStroke = handwritingLayer.drawing.strokes.last {
            let cmd = AddStrokeCommand(stroke: newStroke, strokesAppearedOnce: false, layer: handwritingLayer)
            executeAndSave(command: cmd)
        } else if handwritingLayer.currentTool.isEraser {
            let currentStrokes = handwritingLayer.drawing.strokes
            let erasedStrokes = previousStrokes.filter { oldStroke in 
                !currentStrokes.contains(where: { isStrokeEqual($0, oldStroke) })
            }
            if !erasedStrokes.isEmpty {
                let cmd = EraseStrokesCommand(erasedStrokes: erasedStrokes, strokesErasedOnce: false, layer: handwritingLayer)
                executeAndSave(command: cmd)
            }
        }
        handwritingLayer.touchFinished = false
    }

    // MARK: - 处理贴纸
    private func handleStickerAdded(_ sticker: Sticker) {
        let view = StickerView(sticker: sticker)
        let cmd = AddStickerCommand(stickerView: view, container: containerView)
        executeAndSave(command: cmd)
    }

    // MARK: - Undo/Redo
    func executeAndSave(command: CanvasCommand) {
        command.execute()
        undoStack.append(command)
        redoStack.removeAll()
        // previousStrokes = currentHandwritingLayer.drawing.strokes
        lastEditedTimestamp = Date()

        print("🕹️ Added new command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        // previousStrokes = currentHandwritingLayer.drawing.strokes

        print("🕹️ UndoStack pops command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        // previousStrokes = currentHandwritingLayer.drawing.strokes

        print("🕹️ RedoStack pops command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }
}
