import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate, ToolObserver {
    private let pageRole: PageRole
    private let isLeft: Bool
    private var lastEditedTimestamp: Date?
    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners

    private var handwritingLayer = HandwritingLayer()
    private var stickerLayer = StickerLayer()

    private var previousStrokes: [PKStroke] = []
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    // MARK: - 生命周期
    init(role: PageRole = .normal, isLeft: Bool = true, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.size))
        setupView()
        ToolManager.shared.addObserver(self)

        if role == .normal {
            handwritingLayer.delegate = self 
            addSubview(handwritingLayer)
            addSubview(stickerLayer)

            stickerLayer.setOnStickerAdded { [weak self] sticker in
                guard let self = self else { return }
                let cmd = AddStickerCommand(sticker: sticker, layer: stickerLayer)
                self.executeAndSaveSticker(command: cmd)
            }
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

    // MARK: - ToolObserver
    func toolDidChange(tool: Tool, color: UIColor, width: CGFloat) {
        updateLayerInteractivity(for: tool)
        switch tool {
        case .pen, .highlighter, .eraser:
            handwritingLayer.toolDidChange(tool: tool, color: color, width: width)
        case .sticker:
        default:
            break
        }
    }
    
    private func updateLayerInteractivity(for tool: Tool) {
        handwritingLayer.isUserInteractionEnabled = tool.isHandwriting
        stickerLayer.isUserInteractionEnabled = tool.isSticker
    }

    // MARK: - Setup
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

    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if handwritingLayer.strokeFinished {
            handwritingLayer.strokeFinished = false

            if handwritingLayer.tool is PKInkingTool {
                // 笔迹添加
                if let newStroke = handwritingLayer.drawing.strokes.last {
                    let cmd = AddStrokeCommand(stroke: newStroke, strokesAppearedOnce: false, layer: handwritingLayer)
                    executeAndSave(command: cmd)
                }
            } else if handwritingLayer.tool is PKEraserTool {
                // 橡皮擦除
                let currentStrokes = handwritingLayer.drawing.strokes
                let erasedStrokes = previousStrokes.filter { oldStroke in 
                    !currentStrokes.contains(where: { isStrokeEqual($0, oldStroke) })
                }
                if !erasedStrokes.isEmpty {
                    let cmd = EraseStrokesCommand(erasedStrokes: erasedStrokes, strokesErasedOnce: false, layer: handwritingLayer)
                    executeAndSave(command: cmd)
                }
            }
        }
    }

    // MARK: - Undo/Redo Manager
    func executeAndSave(command: CanvasCommand) {
        command.execute(on: handwritingLayer)
        undoStack.append(command)
        redoStack.removeAll()
        updateTimestamp()

        print("🕹️ Added new command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
        updatePreviousStrokes()
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo(on: handwritingLayer)
        redoStack.append(command)

        print("🕹️ UndoStack pops command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
        updatePreviousStrokes()
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute(on: handwritingLayer)
        undoStack.append(command)

        print("🕹️ RedoStack pops command.", terminator:" ")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
        updatePreviousStrokes()
    }

    private func updatePreviousStrokes() {
        previousStrokes = handwritingLayer.drawing.strokes
        print("   ✏️ Updated drawing has \(previousStrokes.count) strokes.")
    }

    private func updateTimestamp() {
        lastEditedTimestamp = Date()
    }
}
