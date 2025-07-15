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

    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []
    private var pendingEraseInfo: [(HandwritingLayer, [PKStroke])] = []

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
            currentStickerLayer = nil
            eraserLayer = nil
            if currentHandwritingLayer == nil {
                createNewHandwritingLayer()
            }
            currentHandwritingLayer!.setTool(tool: tool)
        } else if tool.isEraser {
            currentStickerLayer = nil
            currentHandwritingLayer = nil
            if eraserLayer == nil {
                createNewEraserLayer()
            }
            // eraserLayer!.setTool(tool: tool)
        } else if tool.isSticker {
            currentHandwritingLayer = nil
            eraserLayer = nil
            if currentStickerLayer == nil {
                createNewStickerLayer()
            }
            // currentStickerLayer!.setTool(tool: tool)
        }
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
        if let newStroke = handwritingLayer.drawing.strokes.last {
            let cmd = AddStrokeCommand(stroke: newStroke, strokesAppearedOnce: false, layer: handwritingLayer)
            executeAndSave(command: cmd)
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
        lastEditedTimestamp = Date()

        print("[P\(pageIndex)] 🕹️ Added new command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)

        print("[P\(pageIndex)] 🕹️ UndoStack pops command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)

        print("[P\(pageIndex)] 🕹️ RedoStack pops command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }
}

extension NotebookPageView: EraserLayerDelegate {
    func applyEraser(eraserLocation: CGPoint, eraserSize: CGFloat) {
        let eraserRect = CGRect(x: eraserLocation.x - eraserSize / 2, y: eraserLocation.y - eraserSize / 2, width: eraserSize, height: eraserSize )

        for layer in handwritingLayers {
            let originalStrokes = layer.drawing.strokes
            let erasedStrokes = originalStrokes.filter { stroke($0, intersects: eraserRect) }
            guard !erasedStrokes.isEmpty else { continue }

            // 实时擦除
            let remainingStrokes = originalStrokes.filter { stroke in !erasedStrokes.contains(where: { isStrokeEqual($0, stroke) }) }
            layer.drawing = PKDrawing(strokes: remainingStrokes)

            // 合并记录擦除信息
            if let index = pendingEraseInfo.firstIndex(where: { $0.0 === layer }) {
                pendingEraseInfo[index].1 = mergeUniqueStrokes(existing: pendingEraseInfo[index].1, new: erasedStrokes)
            } else {
                pendingEraseInfo.append((layer, erasedStrokes))
            }
        }
    }

    func commitEraseCommand() {
        guard !pendingEraseInfo.isEmpty else { return }
        let cmd = MultiEraseCommand(layerToErasedStrokes: pendingEraseInfo, strokesErasedOnce: false)
        executeAndSave(command: cmd)
        pendingEraseInfo.removeAll()
    }

    private func stroke(_ stroke: PKStroke, intersects rect: CGRect) -> Bool {
        for point in stroke.path {
            if rect.contains(point.location) { return true }
        }
        return false
    }
}
