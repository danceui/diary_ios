import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate {
    private let pageRole: PageRole
    private let isLeft: Bool
    private let snapshotQueue = DispatchQueue(label: "com.notebook.snapshotQueue")

    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners

    private var snapshotManager = SnapshotManager(initialSnapshot: PageSnapshot(drawing: PKDrawing()))
    private var canvas: HandwritingCanvas = HandwritingCanvas(PKDrawing())

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

    // MARK: - canvas 管理
    private func rebuildCanvas(with drawing: PKDrawing, isUndo: Bool = true) {
        // 在主线程异步执行这些代码
        DispatchQueue.main.async {
            guard self.pageRole == .normal else { return }

            let newCanvas = HandwritingCanvas(drawing)
            newCanvas.delegate = self
            newCanvas.frame = self.bounds
            
            let oldCanvas = self.canvas
            self.canvas = newCanvas
            self.addSubview(newCanvas)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                oldCanvas.removeFromSuperview()
            }
        }
    }

    // MARK: - 快照管理
    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if canvas.waitingForStrokeFinish {
            canvas.waitingForStrokeFinish = false
            // 将当前 canvas 的 drawing 内容提前复制一份，在后台线程中使用，避免直接跨线程访问 UI 对象。
            let drawingCopy = canvas.drawing
            snapshotQueue.async {
                let snapshot = PageSnapshot(drawing: drawingCopy)
                self.snapshotManager.addSnapshot(snapshot)
            }
        }
    }

    func undo() { if let prev = snapshotManager.undo() { rebuildCanvas(with: prev.drawing, isUndo: true) } }

    func redo() { if let next = snapshotManager.redo() { rebuildCanvas(with: next.drawing, isUndo: false) } }

    private func currentSnapshot() -> PageSnapshot { return snapshotManager.currentSnapshot }
}
