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

    private var canvasLayer = CanvasLayer()
    private var commandManager: CanvasCommandManager!
    private var previousStrokes: [PKStroke] = []

    // MARK: - 生命周期
    init(role: PageRole = .normal, isLeft: Bool = true, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.size))
        setupView()

        if role == .normal {
            canvasLayer.delegate = self 
            addSubview(canvasLayer)
            commandManager = CanvasCommandManager(canvasLayer: canvasLayer)
            commandManager.onCommandExecuted = { [weak self] in self?.updateTimestamp() }
            canvasLayer.onEraserFinished = { [weak self] in self?.handleEraserFinished() }
            canvasLayer.onStickerAdded = { [weak self] sticker in self?.handleStickerAdded(sticker) }
        }
    }

    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        canvasLayer.frame = bounds
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
        if canvasLayer.strokeFinished {
            canvasLayer.strokeFinished = false
            if let stroke = canvasLayer.drawing.strokes.last {
                let cmd = AddStrokeCommand(stroke: stroke, strokesAppearedOnce: false, canvasLayer: canvasLayer)
                execute(command: cmd)
            }
        }
    }

    private func handleEraserFinished() {
        let currentStrokes = canvasLayer.drawing.strokes
        let erasedStrokes = previousStrokes.filter { old in
            !currentStrokes.contains(where: { isStrokeEqual($0, old) })
        }
        if !erasedStrokes.isEmpty {
            let cmd = EraseStrokesCommand(erasedStrokes: erasedStrokes, strokesErasedOnce: false, canvasLayer: canvasLayer)
            execute(command: cmd)
        }
    }

    private func handleStickerAdded(_ sticker: Sticker) {
        let cmd = AddStickerCommand(sticker: sticker, canvasLayer: canvasLayer)
        commandManager.executeAndSave(command: cmd)
    }

    // MARK: - Undo/Redo
    func execute(command: CanvasCommand) {
        commandManager.executeAndSave(command: command)
        updatePreviousStrokes()
    }

    func undo() {
        commandManager.undo()
        updatePreviousStrokes()
    }

    func redo() {
        commandManager.redo()
        updatePreviousStrokes()
    }

    private func updateTimestamp() {
        lastEditedTimestamp = Date()
    }

    private func updatePreviousStrokes() {
        previousStrokes = canvasLayer.drawing.strokes
    }
}
