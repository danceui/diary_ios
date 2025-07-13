import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate {
    private let pageRole: PageRole
    private let isLeft: Bool
    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners
    private(set) var lastEditedTimestamp: Date?

    private var handwritingLayer = HandwritingLayer()
    private var stickerLayer = StickerLayer()

    private var previousStrokes: [PKStroke] = []
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    // MARK: - 初始化
    init(role: PageRole = .normal, isLeft: Bool = true, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.size))
        setupView()

        if role == .normal {
            handwritingLayer.delegate = self 
            addSubview(handwritingLayer)
            // addSubview(stickerLayer)

            stickerLayer.onStickerAdded = { [weak self] sticker in self?.handleStickerAdded(sticker) }
        }
    }

    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        handwritingLayer.frame = bounds
        stickerLayer.frame = bounds
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

    // MARK: - 处理笔画
    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if handwritingLayer.touchFinished {
            if handwritingLayer.currentTool.isDrawing{
                if let newStroke = handwritingLayer.drawing.strokes.last {
                    let cmd = AddStrokeCommand(stroke: newStroke, strokesAppearedOnce: false, layer: handwritingLayer)
                    executeAndSave(command: cmd)
                }
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
    }

    // MARK: - 处理贴纸
    private func handleStickerAdded(_ sticker: Sticker) {
        let cmd = AddStickerCommand(sticker: sticker, layer: stickerLayer)
        executeAndSave(command: cmd)
    }

    // MARK: - Undo/Redo
    func executeAndSave(command: CanvasCommand) {
        command.execute()
        undoStack.append(command)
        redoStack.removeAll()
        previousStrokes = handwritingLayer.drawing.strokes
        lastEditedTimestamp = Date()

        print("🕹️ Added new command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        previousStrokes = handwritingLayer.drawing.strokes

        print("🕹️ UndoStack pops command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        previousStrokes = handwritingLayer.drawing.strokes

        print("🕹️ RedoStack pops command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }
}
