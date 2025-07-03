import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate {
    private let pageRole: PageRole
    private let isLeft: Bool
    private(set) var lastEditedTimestamp: Date?
    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners

    private var handwritingLayer = HandwritingLayer()

    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    // MARK: - 生命周期
    init(role: PageRole = .normal, isLeft: Bool = true, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.singleSize))
        setupView()
        if role == .normal {
            handwritingLayer.delegate = self 
            addSubview(handwritingLayer) 
        }
    }

    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        handwritingLayer.frame = bounds
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
            if let newStroke = handwritingLayer.drawing.strokes.last {
                let addStrokeCommand = AddStrokeCommand(stroke: newStroke, hasAppearedOnce: false)
                executeAndSave(command: addStrokeCommand)
            }
        }
    }

    // MARK: - Undo/Redo Manager
    func executeAndSave(command: CanvasCommand) {
        command.execute(on: handwritingLayer)
        undoStack.append(command)
        redoStack.removeAll()
        print("🕹️ Added new command:", terminator:" ")
        lastEditedTimestamp = Date()
        printUndoStackInfo(undoStack: undoStack)
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        print("🕹️ UndoStack pops command.", terminator:" ")
        command.undo(on: handwritingLayer)
        redoStack.append(command)
        printUndoStackInfo(undoStack: undoStack)
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        print("🕹️ RedoStack pops command.", terminator:" ")
        command.execute(on: handwritingLayer)
        undoStack.append(command)
        printUndoStackInfo(undoStack: undoStack)
    }

    func reset() {
        undoStack.removeAll()
        redoStack.removeAll()
        print("🕹️ Cleared command history.")
    }
}
