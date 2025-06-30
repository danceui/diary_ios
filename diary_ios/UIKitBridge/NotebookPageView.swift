import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate {
    private let pageRole: PageRole
    private let isLeft: Bool
    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners

    private var canvas = CustomCanvasView()
    private var undoRedoManager = UndoRedoManager()
    private var canvasState = CanvasState() { didSet { canvas.drawing = canvasState.drawing} }

    // MARK: - 生命周期
    init(role: PageRole = .normal, isLeft: Bool = true, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.singleSize))
        setupView()
        if role == .normal {
            canvas.delegate = self 
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

    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if canvas.waitingForStrokeFinish {
            canvas.waitingForStrokeFinish = false
            if let newStroke = canvas.drawing.strokes.last {
                print("✍️ Added new stroke.")
                let command = DrawStrokeCommand(stroke: newStroke)
                undoRedoManager.executeCommand(command)
            }
        }
    }

    func undo() {
        print("✍️ Call undoCommand.")
    Thread.callStackSymbols.forEach { print($0) } // 打印调用栈
        undoRedoManager.undoCommand()
        canvasState = undoRedoManager.canvasState
    }

    func redo() {
        print("✍️ Call redoCommand.")
        undoRedoManager.redoCommand()
        canvasState = undoRedoManager.canvasState
    }
}
