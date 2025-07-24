import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate, ToolObserver {
    private let pageRole: PageRole
    var pageIndex: Int
    private let isLeft: Bool
    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let lassoCornerRadius = LassoConstants.cornerRadius
    private let inset = LassoConstants.inset
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners
    private(set) var lastEditedTimestamp: Date?

    private var containerView = UIView()
    private var currentHandwritingLayer: HandwritingLayer?
    private var currentStickerLayer: StickerLayer?
    private var currentEraserLayer: EraserLayer?
    private var currentLassoLayer: LassoLayer?
    private var handwritingLayers: [HandwritingLayer] = []
    private var stickerLayers: [StickerLayer] = []

    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []
    private var layerStrokesInfo: [LayerStrokes] = [] // 缓存每个 layer 的笔画信息
    private var pendingEraseInfo: [LayerStrokes] = [] // 记录每个 layer 待擦除的笔画信息
    private var lassoStrokesInfo: [LayerStrokes] = [] // 记录套索选中的每个 layer 的笔画信息
    private var lassoStickerView: StickerView? // 记录套索选中的贴纸信息

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
    func toolDidChange(tool: Tool) {
        removeCurrentLayers()
        if tool.isDrawing {
            if currentHandwritingLayer == nil {
                createNewHandwritingLayer()
            }
            currentHandwritingLayer?.setTool(tool: tool)
        } else if tool.isEraser {
            if currentEraserLayer == nil {
                createNewEraserLayer()
            }
            // currentEraserLayer?.setTool(tool: tool)
        } else if tool.isSticker {
            if currentStickerLayer == nil {
                createNewStickerLayer()
            }
            // currentStickerLayer?.setTool(tool: tool)
        } else if tool.isLasso {
            if currentLassoLayer == nil {
                createNewLassoLayer()
            }
            // currentLassoLayer?.setTool(tool: tool)
        }
    }

    // MARK: - 清理视图层
    func removeCurrentLayers() {
        // currentHandwritingLayer 和 currentStickerLayer 是实际显示层
        currentHandwritingLayer = nil
        currentStickerLayer = nil
        print("[P\(pageIndex)] 🗑️ Cleared CurrentHandwritingLayer and CurrentStickerLayer.")

        // currentEraserLayer 和 currentLassoLayer 只是手势响应层
        currentEraserLayer?.removeFromSuperview()
        currentEraserLayer = nil

        currentLassoLayer?.removeFromSuperview()
        currentLassoLayer = nil
        print("[P\(pageIndex)] 🗑️ Cleared and removed CurrentEraserLayer and CurrentLassoLayer.")
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

// MARK: - Handwriting Layer 回调
extension NotebookPageView {
    private func createNewHandwritingLayer() {
        let newLayer = HandwritingLayer()
        newLayer.frame = bounds
        newLayer.delegate = self
        handwritingLayers.append(newLayer)
        currentHandwritingLayer = newLayer
        containerView.addSubview(newLayer)
        print("[P\(pageIndex)] ✏️ Created handwriting layer. handwritingLayers.count = \(handwritingLayers.count).")
    }

    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard let handwritingLayer = currentHandwritingLayer, handwritingLayer.touchFinished else { return }
        if let newStroke = handwritingLayer.drawing.strokes.last {
            let cmd = AddStrokeCommand(stroke: newStroke, strokesAppearedOnce: false, layer: handwritingLayer)
            executeAndSave(command: cmd)
        }
        handwritingLayer.touchFinished = false
    }
}

// MARK: - Sticker Layer 回调
extension NotebookPageView {
    private func createNewStickerLayer() {
        let newLayer = StickerLayer()
        newLayer.frame = bounds
        newLayer.onStickerAdded = { [weak self] sticker in self?.handleStickerAdded(sticker) }
        stickerLayers.append(newLayer)
        currentStickerLayer = newLayer
        containerView.addSubview(newLayer)
        print("[P\(pageIndex)] ⭐️ Created sticker layer. stickerLayers.count = \(stickerLayers.count).")
    }

    private func handleStickerAdded(_ sticker: Sticker) {
        guard let stickerLayer = currentStickerLayer else { return }
        let cmd = AddStickerCommand(sticker: sticker, stickerLayer: stickerLayer)
        executeAndSave(command: cmd)
    }
}

// MARK: - Eraser Layer 代理
extension NotebookPageView: EraserLayerDelegate {
    private func createNewEraserLayer() {
        let newLayer = EraserLayer()
        newLayer.frame = bounds
        newLayer.eraseDelegate = self
        containerView.addSubview(newLayer)
        currentEraserLayer = newLayer
        print("[P\(pageIndex)] 🫧 Created eraser layer")
    }

    func applyEraser(eraserLocation: CGPoint, eraserSize: CGFloat) {
        let eraserRect = CGRect(x: eraserLocation.x - eraserSize / 2, y: eraserLocation.y - eraserSize / 2, width: eraserSize, height: eraserSize )

        for layer in handwritingLayers {
            guard let cachedInfo = layerStrokesInfo.first(where: { $0.layer === layer }) else { continue }
            let currentStrokes = layer.drawing.strokes
            var indexedErased: [IndexedStroke] = []
            
            // 在当前 strokes 中找被擦中的 stroke
            // 并从 cached 中查原始 index 存储
            for stroke in currentStrokes {
                if stroke.intersectsRect(eraserRect),
                   let index = cachedInfo.indexedStrokes.first(where: { $0.stroke.isEqualTo(stroke) })?.index {
                    indexedErased.append((index, stroke))
                }
            }
            guard !indexedErased.isEmpty else { continue }

            // 实时擦除
            let remainingStrokes = currentStrokes.filter { stroke in 
                !indexedErased.contains { indexed in 
                    indexed.stroke.isEqualTo(stroke)
                }
            }
            layer.drawing = PKDrawing(strokes: remainingStrokes)

            // 记录擦除笔画
            if let index = pendingEraseInfo.firstIndex(where: { $0.layer === layer }) {
                pendingEraseInfo[index].indexedStrokes = mergeUniqueStrokes(existing: pendingEraseInfo[index].indexedStrokes, new: indexedErased)
            } else {
                pendingEraseInfo.append(LayerStrokes(layer: layer, indexedStrokes: indexedErased))
            }
            // printLayerStrokesInfo(eraseInfo: pendingEraseInfo, context: "[P\(pageIndex)] 🧩 Erasing Strokes")
        }
    }

    func commitEraseCommand() {
        guard !pendingEraseInfo.isEmpty else { return }
        let cmd = MultiEraseCommand(eraseInfo: pendingEraseInfo, strokesErasedOnce: false)
        executeAndSave(command: cmd)
        pendingEraseInfo.removeAll()
    }
    
    func updateLayerIndexedStrokeInfo() {
        layerStrokesInfo.removeAll()
        for layer in handwritingLayers {
            let strokes = layer.drawing.strokes
            let indexedStrokes = strokes.enumerated().map { (i, s) in (i, s) }
            layerStrokesInfo.append(LayerStrokes(layer: layer, indexedStrokes: indexedStrokes))
        }
    }
}

// MARK: - Lasso Layer 回调
extension NotebookPageView {
    private func createNewLassoLayer() {
        let newLayer = LassoLayer()
        newLayer.frame = bounds
        newLayer.onLassoFinished = { [weak self] path in self?.handleLassoFinished(path: path) }
        newLayer.onLassoDragged = { [weak self] transform in self?.handleLassoDragged(transform: transform) }
        newLayer.onLassoDragFinished = { [weak self] transform in self?.handleLassoDragFinished(transform: transform) }
        newLayer.onStickerTapped = { [weak self] point in self?.handleStickerTapped(point: point) }
        containerView.addSubview(newLayer)
        currentLassoLayer = newLayer
        print("[P\(pageIndex)] ⛓️‍💥 Created lasso layer")
    }

    private func handleLassoFinished(path: UIBezierPath) {
        guard let lassoLayer = currentLassoLayer else { return }
        lassoStrokesInfo.removeAll()
        lassoStickerView = nil
        for layer in handwritingLayers {
            let strokes = layer.drawing.strokes
            var selected: [IndexedStroke] = []
            
            for (i, stroke) in strokes.enumerated() where path.bounds.intersects(stroke.renderBounds) {
                if stroke.path.contains(where: { path.contains($0.location) }) {
                    selected.append((i, stroke))
                }
            }
            if !selected.isEmpty {
                lassoStrokesInfo.append(LayerStrokes(layer: layer, indexedStrokes: selected))
            }
        }
        // 如果有笔画被选中，按笔画范围更新套索路径
        if !lassoStrokesInfo.isEmpty {
            updateLassoPathForStrokes(strokesInfo: lassoStrokesInfo, in: lassoLayer)
            printLayerStrokesInfo(info: lassoStrokesInfo, context: "[P\(pageIndex)] 🧩 Selected Strokes")
        } else {
            lassoLayer.removeLassoPath()
        }
    }

    private func handleStickerTapped(point: CGPoint) {
        guard let lassoLayer = currentLassoLayer else { return }
        lassoStrokesInfo.removeAll()
        lassoStickerView = nil
        // 从顶层到低层寻找贴纸（优先最上方）
        for layer in stickerLayers.reversed() {
            for view in layer.stickerViews.reversed() {
                let convertedPoint = view.convert(point, from: lassoLayer)
                if view.bounds.contains(convertedPoint) {
                    lassoStickerView = view
                    updateLassoPathForSticker(view: view, in: lassoLayer)
                    print("[P\(pageIndex)] ⭐️ Selected sticker \(view.sticker.id)")
                    return
                }
            }
        }
    }

    private func handleLassoDragged(transform: CGAffineTransform) {
        guard let lassoLayer = currentLassoLayer else { return }
        
        if let view = lassoStickerView {
            // 有贴纸被选中，实时更新贴纸及其套索位置
            view.center = view.sticker.center.applying(transform)
            lassoLayer.updateLassoPath(transform: transform)
        }
        if !lassoStrokesInfo.isEmpty {
            // 有笔画被选中，实时更新笔画及套索位置
            transformStrokes(lassoStrokesInfo: lassoStrokesInfo, transform: transform)
            lassoLayer.updateLassoPath(transform: transform)
        }
    }
    
    private func handleLassoDragFinished(transform: CGAffineTransform) {
        guard let lassoLayer = currentLassoLayer else { return }
        
        if let view = lassoStickerView {
            // 有贴纸被选中，提交移动命令
            let cmd = MoveStickerCommand(stickerView: view, lassoLayer: lassoLayer, transform: transform, stickerMovedOnce: false)
            executeAndSave(command: cmd)
            view.sticker.center = view.center
        }
        if !lassoStrokesInfo.isEmpty {
            // 有笔画被选中，提交移动命令
            let cmd = MoveStrokesCommand(lassoStrokesInfo: lassoStrokesInfo, lassoLayer: lassoLayer, transform: transform, strokesMovedOnce: false)
            executeAndSave(command: cmd)
            updateLassoStrokesInfo()
        }
        lassoLayer.updateOriginalLassoPath()
    }


    // 辅助函数
    private func updateLassoStrokesInfo() {
        lassoStrokesInfo = lassoStrokesInfo.compactMap { info in
            let allStrokes = info.layer.drawing.strokes
            let updatedIndexed: [IndexedStroke] = info.indexedStrokes.compactMap { (index, _) in
                guard index >= 0, index < allStrokes.count else { return nil }
                return (index, allStrokes[index])
            }
            return updatedIndexed.isEmpty ? nil : LayerStrokes(layer: info.layer, indexedStrokes: updatedIndexed)
        }
    }

    private func updateLassoPathForSticker(view: StickerView?, in lassoLayer: LassoLayer) {
        guard let view = view else { return }
        let frameInLasso = lassoLayer.convert(view.frame, from: view.superview)
        let path = UIBezierPath(rect: frameInLasso.insetBy(dx: inset, dy: inset))
        lassoLayer.configureLassoPath(path: path)
    }

    private func updateLassoPathForStrokes(strokesInfo: [LayerStrokes], in lassoLayer: LassoLayer) {
        guard !strokesInfo.isEmpty else { return }
        var unionBounds: CGRect?
        for indexed in strokesInfo {
            for (_, stroke) in indexed.indexedStrokes {
                let strokeBounds = stroke.renderBounds
                unionBounds = unionBounds == nil ? strokeBounds : unionBounds!.union(strokeBounds)
            }
        }
        if let bounds = unionBounds {
            let path = UIBezierPath(rect: bounds.insetBy(dx: -inset, dy: -inset))
            lassoLayer.configureLassoPath(path: path)
        }
    }
}
