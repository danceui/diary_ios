import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate {
    private let pageRole: PageRole
    private let isLeft: Bool
    private let canvas: HandwritingCanvas = HandwritingCanvas()

    private var snapshotManager = SnapshotManager(initialSnapshot: PageSnapshot(drawing: PKDrawing()))
    private let snapshotQueue = DispatchQueue(label: "com.notebook.snapshotQueue")

    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners

    // MARK: - 生命周期
    init(role: PageRole = .normal, isLeft: Bool = true, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        super.init(frame: CGRect(origin: .zero, size: PageConstants.pageSize.singleSize))
        setupView()
        setupCanvas()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        canvas.frame = bounds
    }

func printCanvasDrawingInfo(tag: String = "") {
    let strokes = self.canvas.drawing.strokes
    print("🖊️ Drawing Info \(tag.isEmpty ? "" : "[\(tag)]"): Total Strokes: \(strokes.count).")
}
    // MARK: - setup
    private func setupView() {
        backgroundColor = UIColor(red: 0.93, green: 0.91, blue: 0.86, alpha: 1.00) // 浅绿色背景
        layer.cornerRadius = pageCornerRadius
        layer.maskedCorners = isLeft ? leftMaskedCorners : rightMaskedCorners
        layer.masksToBounds = true
    }

    private func setupCanvas() {
        guard pageRole != .empty else { return }
        canvas.delegate = self
        switch pageRole {
        case .normal:
            canvas.backgroundColor = UIColor(red: 0.76, green: 0.88, blue: 0.77, alpha: 1) // 正常浅绿色
        case .cover:
            canvas.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) // 灰色封面
            canvas.isUserInteractionEnabled = false // 禁止写字
        case .back:
            canvas.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) // 灰色背页
            canvas.isUserInteractionEnabled = false
        case .empty: break
        }

        canvas.layer.cornerRadius = pageCornerRadius
        canvas.layer.maskedCorners = isLeft ? leftMaskedCorners : rightMaskedCorners
        canvas.layer.masksToBounds = true
        addSubview(canvas)
    }

    // MARK: - 快照管理
    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if canvas.waitingForStrokeFinish {
            canvas.waitingForStrokeFinish = false
            let drawingCopy = canvas.drawing
            snapshotQueue.async {
                let snapshot = PageSnapshot(drawing: drawingCopy)
                self.printCanvasDrawingInfo(tag: "Saving Snapshot.")
                self.snapshotManager.addSnapshot(snapshot)
            }
        }
    }

    func undo() {
        if let prev = snapshotManager.undo() {
            canvas.updateDrawing(prev.drawing)
            printCanvasDrawingInfo(tag: "After Undo")
        }
    }

    func redo() {
        if let next = snapshotManager.redo() {
            canvas.updateDrawing(next.drawing)
            printCanvasDrawingInfo(tag: "After Redo")
        }
    }

    private func currentSnapshot() -> PageSnapshot { return snapshotManager.currentSnapshot }
}
