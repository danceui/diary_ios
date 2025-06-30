import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView {
    private let pageRole: PageRole
    private let isLeft: Bool
    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners

    private var canvas: HandwritingCanvas = HandwritingCanvas()
    private var canvasState = CanvasState()
    private var undoRedoManager = UndoRedoManager()

    // MARK: - 生命周期
    init(role: PageRole = .normal, isLeft: Bool = true, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.singleSize))
        setupView()
        if role == .normal {
            canvas.onStrokeFinished = { [weak self] stroke in self?.handleNewStroke(stroke) }
            addSubview(canvas) 
        }
    }

    required init?(coder: NSCoder) { 
        fatalError("init(coder:) has not been implemented") 
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        canvas.frame = bounds
    }

    // MARK: - setup
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

    private func handleNewStroke(_ stroke: PKStroke) {
        let command = DrawStrokeCommand(stroke: stroke)
        undoRedoManager.executeCommand(command)
        canvasState = undoRedoManager.canvasState
    }

    func undo() {
        undoRedoManager.undoCommand()
        canvasState = undoRedoManager.canvasState
    }

    func redo() {
        undoRedoManager.redoCommand()
        canvasState = undoRedoManager.canvasState
    }

    private func currentCanvasState() -> CanvasState {
        return canvasState
    }
}
