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
    private var pendingEraseInfo: [(HandwritingLayer, [IndexedStroke])] = []
    private var layerIndexedStrokeInfo: [(HandwritingLayer, [IndexedStroke])] = []

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
        print("[P\(pageIndex)] ❌ Tool listener deactivated.")
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
        updateLayerIndexedStrokeInfo()
        print("[P\(pageIndex)] 🕹️ Added new command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        updateLayerIndexedStrokeInfo()
        print("[P\(pageIndex)] 🕹️ UndoStack pops command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        updateLayerIndexedStrokeInfo()
        print("[P\(pageIndex)] 🕹️ RedoStack pops command. undoStack.count = \(undoStack.count), redoStack.count = \(redoStack.count).")
    }
}

// MARK: - EraserLayer 代理
extension NotebookPageView: EraserLayerDelegate {
    func applyEraser(eraserLocation: CGPoint, eraserSize: CGFloat) {
        let eraserRect = CGRect(x: eraserLocation.x - eraserSize / 2, y: eraserLocation.y - eraserSize / 2, width: eraserSize, height: eraserSize )

        for layer in handwritingLayers {
            guard let cachedInfo = layerIndexedStrokeInfo.first(where: { $0.0 === layer }) else { continue }
            let currentStrokes = layer.drawing.strokes
            var indexedErased: [IndexedStroke] = []
            
            // 在当前 strokes 中找被擦中的 stroke，并从 cached 中查原始 index
            for stroke in currentStrokes {
                if strokeIntersectsRect(stroke: stroke, eraserRect: eraserRect), 
                    let index = cachedInfo.1.first(where: { isStrokeEqual($0.stroke, stroke) })?.index {
                    indexedErased.append((index, stroke))
                }
            }
            guard !indexedErased.isEmpty else { continue }

            // 实时擦除
            let remainingStrokes = currentStrokes.filter { stroke in 
                !indexedErased.contains { indexed in 
                    isStrokeEqual(indexed.stroke, stroke)
                }
            }
            layer.drawing = PKDrawing(strokes: remainingStrokes)

            // 合并记录, 防止重复
            if let index = pendingEraseInfo.firstIndex(where: { $0.0 === layer }) {
                pendingEraseInfo[index].1 = mergeUniqueStrokes(existing: pendingEraseInfo[index].1, new: indexedErased)
            } else {
                pendingEraseInfo.append((layer, indexedErased))
            }
            printEraseInfo(eraseInfo: pendingEraseInfo, context: "[P\(pageIndex)] 📄 Erasing Strokes")
        }
    }

    func commitEraseCommand() {
        guard !pendingEraseInfo.isEmpty else { return }
        let cmd = MultiEraseCommand(eraseInfo: pendingEraseInfo, strokesErasedOnce: false)
        executeAndSave(command: cmd)
        pendingEraseInfo.removeAll()
    }
    
    func updateLayerIndexedStrokeInfo() {
        layerIndexedStrokeInfo.removeAll()
        for layer in handwritingLayers {
            let strokes = layer.drawing.strokes
            let indexedStrokes = strokes.enumerated().map { (i, s) in (i, s) }
            layerIndexedStrokeInfo.append((layer: layer, indexedStrokes: indexedStrokes))
        }
    }
}
