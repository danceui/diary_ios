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
    private var handwritingInputLayer = HandwritingInputLayer()
    private var stickerInputLayer = StickerInputLayer()

    private var previousStrokes: [PKStroke] = []
    private var currentStrokeBatch: [PKStroke] = []
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
            handwritingInputLayer.delegate = self
            addSubview(containerView)
            containerView.addSubview(stickerInputLayer)
            containerView.addSubview(handwritingInputLayer)

            stickerInputLayer.onStickerAdded = { [weak self] sticker in self?.handleStickerAdded(sticker) }
        }
    }

    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
        handwritingInputLayer.frame = bounds
        stickerInputLayer.frame = bounds
    }
    
    private func setupView() {
        backgroundColor = backgroundColorForRole(pageRole) // 浅绿色背景
        layer.cornerRadius = pageCornerRadius
        layer.maskedCorners = isLeft ? leftMaskedCorners : rightMaskedCorners
        layer.masksToBounds = true
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
        if currentTool.isDrawing && !tool.isDrawing {
            finalizeCurrentStrokeBatch()
        }
        if tool.isDrawing || tool.isEraser {
            containerView.bringSubviewToFront(handwritingInputLayer)
        } else if tool.isSticker {
            containerView.bringSubviewToFront(stickerInputLayer)
        }
        currentTool = tool
    }

    private func finalizeCurrentStrokeBatch() {
        guard !currentStrokeBatch.isEmpty else { return }
        print("🪵 This Batch has \(currentStrokeBatch.count) strokes.")
        let batchView = StrokeBatchView(strokes: currentStrokeBatch, frame: bounds)
        containerView.addSubview(batchView) //?
        currentStrokeBatch.removeAll()
    }

    // MARK: - 处理笔画
    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard handwritingInputLayer.touchFinished else { return }
        if handwritingInputLayer.currentTool.isDrawing, let newStroke = handwritingInputLayer.drawing.strokes.last {
            let cmd = AddStrokeCommand(stroke: newStroke, strokesAppearedOnce: false, layer: handwritingInputLayer)
            executeAndSave(command: cmd)
        } else if handwritingInputLayer.currentTool.isEraser {
            let currentStrokes = handwritingInputLayer.drawing.strokes
            let erasedStrokes = previousStrokes.filter { oldStroke in 
                !currentStrokes.contains(where: { isStrokeEqual($0, oldStroke) })
            }
            if !erasedStrokes.isEmpty {
                let cmd = EraseStrokesCommand(erasedStrokes: erasedStrokes, strokesErasedOnce: false, layer: handwritingInputLayer)
                executeAndSave(command: cmd)
            }
        }
        handwritingInputLayer.touchFinished = false
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
        previousStrokes = handwritingInputLayer.drawing.strokes
        lastEditedTimestamp = Date()

        print("🕹️ Added new command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        previousStrokes = handwritingInputLayer.drawing.strokes

        print("🕹️ UndoStack pops command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        previousStrokes = handwritingInputLayer.drawing.strokes

        print("🕹️ RedoStack pops command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }
}
