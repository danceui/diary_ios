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
    private var eraserLayer: EraserLayer?

    private var previousStrokes: [PKStroke] = []
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    private var currentTool: Tool = .pen
    private var isObservingTool: Bool = false

    // MARK: - 初始化
    init(role: PageRole = .normal, isLeft: Bool = true, leftPageIndex: Int = 0, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        self.pageIndex = isLeft ? leftPageIndex : leftPageIndex + 1
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.size))
        setupView()
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
        if pageRole == .normal { addSubview(containerView) }
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
        if tool.isDrawing {
            if currentHandwritingLayer == nil {
                createNewHandwritingLayer()
            }
            currentHandwritingLayer!.toolDidChange(tool: tool)
            currentStickerLayer = nil
            eraserLayer == nil
        } else if tool.isEraser {
            if eraserLayer == nil {
                createNewEraserLayer()
            }
            currentStickerLayer = nil
            currentHandwritingLayer = nil
        } else if tool.isSticker {
            if currentStickerLayer == nil {
                createNewStickerLayer()
            }
            currentHandwritingLayer = nil
            eraserLayer == nil
        }
        currentTool = tool
    }

    // MARK: - 创建视图层
    private func createNewHandwritingLayer() {
        clearEmptyHandwritingLayer()
        let newLayer = HandwritingLayer()
        newLayer.frame = bounds
        newLayer.delegate = self
        handwritingLayers.append(newLayer)
        currentHandwritingLayer = newLayer
        containerView.addSubview(newLayer)
        print("[P\(pageIndex)] ✏️ Created handwriting layer. handwritingLayers.count = \(handwritingLayers.count).")
    }

    private func createNewStickerLayer() {
        clearEmptyStickerLayer()
        let newLayer = StickerLayer()
        newLayer.frame = bounds
        newLayer.onStickerAdded = { [weak self] sticker in self?.handleStickerAdded(sticker) }
        stickerLayers.append(newLayer)
        currentStickerLayer = newLayer
        containerView.addSubview(newLayer)
        print("[P\(pageIndex)] ⭐️ Created sticker layer. stickerLayers.count = \(stickerLayers.count).")
    }

    private func createNewEraserLayer() {
        if let eraserLayer = eraserLayer {
            eraserLayer.removeFromSuperview()
        }
        let newLayer = EraserLayer()
        newLayer.frame = bounds
        newLayer.eraseDelegate = self
        containerView.addSubview(newLayer)
        eraserLayer = newLayer
        print("[P\(pageIndex)] 🫧 Created eraser layer")
    }

    // MARK: - 清理视图层
    func clearEmptyHandwritingLayer() {
        if let lastHandwriting = handwritingLayers.last, lastHandwriting.isEmpty {
            lastHandwriting.removeFromSuperview()
            handwritingLayers.removeLast()
            print("[P\(pageIndex)] 🗑️ Cleared last empty handwriting layer. handwritingLayers.count = \(handwritingLayers.count).")
        }
    }

    func clearEmptyStickerLayer() {
        if let lastSticker = stickerLayers.last, lastSticker.isEmpty {
            lastSticker.removeFromSuperview()
            stickerLayers.removeLast()
            print("[P\(pageIndex)] 🗑️ Cleared last empty sticker layer. stickerLayers.count = \(stickerLayers.count).")
        }
    }

    // MARK: - 监听工具
    func activateToolListener() {
        guard !isObservingTool else { return }
        ToolManager.shared.addObserver(self)
        isObservingTool = true
        print("[P\(pageIndex)] 👂 Tool listener activated.")
    }

    func deactivateToolListener() {
        guard isObservingTool else { return }
        ToolManager.shared.removeObserver(self)
        isObservingTool = false
        // print("[P\(pageIndex)] ❌ Tool listener deactivated.")
    }

    // MARK: - 处理笔画
    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard let handwritingLayer = currentHandwritingLayer, handwritingLayer.touchFinished else { return }
        if handwritingLayer.currentTool.isDrawing, let newStroke = handwritingLayer.drawing.strokes.last {
            let cmd = AddStrokeCommand(stroke: newStroke, strokesAppearedOnce: false, layer: handwritingLayer)
            executeAndSave(command: cmd)
        } else if handwritingLayer.currentTool.isEraser {
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

        print("[P\(pageIndex)] 🕹️ Added new command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        // previousStrokes = currentHandwritingLayer.drawing.strokes

        print("[P\(pageIndex)] 🕹️ UndoStack pops command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        // previousStrokes = currentHandwritingLayer.drawing.strokes

        print("[P\(pageIndex)] 🕹️ RedoStack pops command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }
}

extension NotebookPageView: EraserLayerDelegate {
    func applyEraser(eraserLocation: CGPoint, eraserSize: CGFloat) {
        print("[P\(pageIndex)] Applying eraser.")
        let eraserRect = CGRect(x: eraserLocation.x - eraserSize / 2, y: eraserLocation.y - eraserSize / 2, width: eraserSize, height: eraserSize )

        var eraseInfo: [(HandwritingLayer, [PKStroke])] = []
        for layer in handwritingLayers {
            let originalStrokes = layer.drawing.strokes
            let erasedStrokes = originalStrokes.filter { stroke($0, intersects: eraserRect) }
            if !erasedStrokes.isEmpty {
                // let remainingStrokes = originalStrokes.filter { _ in !erasedStrokes.contains(where: { isStrokeEqual($0, $1) }) }
                // layer.drawing = PKDrawing(strokes: remainingStrokes)
                eraseInfo.append((layer, erasedStrokes))
            }
        }
        if !eraseInfo.isEmpty {
            let cmd = MultiEraseStrokesCommand(layerToErasedStrokes: eraseInfo, strokesErasedOnce: true)
            executeAndSave(command: cmd)
        }
    }

    private func stroke(_ stroke: PKStroke, intersects rect: CGRect) -> Bool {
        for point in stroke.path {
            if rect.contains(point.location) { return true }
        }
        return false
    }
}
