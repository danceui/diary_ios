import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate, ToolObserver {
    private let pageRole: PageRole
    var pageIndex: Int
    private let isLeft: Bool
    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners
    private(set) var lastEditedTimestamp: Date?

    private var containerView = UIView()
    private var handwritingLayers: [HandwritingLayer] = []
    private var currentHandwritingLayer: HandwritingLayer?
    private var stickerLayers: [StickerLayer] = []
    private var currentStickerLayer: StickerLayer?

    private var previousStrokes: [PKStroke] = []
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    private var currentTool: Tool = .pen

    // MARK: - 初始化
    init(role: PageRole = .normal, isLeft: Bool = true, leftPageIndex: Int = 0, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        self.pageIndex = isLeft ? leftPageIndex : leftPageIndex + 1
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.size))
        setupView()

        if role == .normal {
            ToolManager.shared.addObserver(self)
            addSubview(containerView)
        }
    }

    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
        for layer in handwritingLayers {
            layer.frame = bounds
        }
        for layer in stickerLayers {
            layer.frame = bounds
        }
    }
    
    private func setupView() {
        backgroundColor = backgroundColorForRole(pageRole)
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
        if tool.isDrawing || tool.isEraser {
            if currentHandwritingLayer == nil {
                createNewHandwritingLayer()
                print("[P\(pageIndex)] Created handwriting layer. handwritingLayers.count = \(handwritingLayers.count).")
            }
            currentHandwritingLayer!.toolDidChange(tool: tool)
            currentStickerLayer = nil
        } else if tool.isSticker {
            if currentStickerLayer == nil {
                createNewStickerLayer()
                print("[P\(pageIndex)] Created sticker layer. stickerLayers.count = \(stickerLayers.count).")
            }
            currentStickerLayer!.toolDidChange(tool: tool)
            currentHandwritingLayer = nil
        }
        currentTool = tool
    }

    private func createNewHandwritingLayer() {
        let newLayer = HandwritingLayer()
        newLayer.frame = bounds
        newLayer.delegate = self
        handwritingLayers.append(newLayer)
        currentHandwritingLayer = newLayer
        containerView.addSubview(newLayer)
    }

    private func createNewStickerLayer() {
        let newLayer = StickerLayer()
        newLayer.frame = bounds
        newLayer.onStickerAdded = { [weak self] sticker in self?.handleStickerAdded(sticker) }
        stickerLayers.append(newLayer)
        currentStickerLayer = newLayer
        containerView.addSubview(newLayer)
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
        guard let stickerLayer = currentStickerLayer else { return }
        let cmd = AddStickerCommand(sticker: sticker, stickerLayer: stickerLayer)
        executeAndSave(command: cmd)
    }

    // MARK: - Undo/Redo
    func executeAndSave(command: CanvasCommand) {
        command.execute()
        undoStack.append(command)
        redoStack.removeAll()
        // previousStrokes = currentHandwritingLayer.drawing.strokes
        lastEditedTimestamp = Date()

        print("[P\(pageIndex)] Added new command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        // previousStrokes = currentHandwritingLayer.drawing.strokes

        print("[P\(pageIndex)] UndoStack pops command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        // previousStrokes = currentHandwritingLayer.drawing.strokes

        print("[P\(pageIndex)] RedoStack pops command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }
}
