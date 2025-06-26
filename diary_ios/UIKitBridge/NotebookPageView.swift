import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate {
    private let pageRole: PageRole
    private let isLeft: Bool
    private let canvas: HandwritingCanvas = HandwritingCanvas()

    private var pageSnapshots: [PageSnapshot] = [PageSnapshot(drawing: PKDrawing())]
    private var snapshotIndex = 0
    private let maxSnapshots = 50
    private let pageCornerRadius = PageConstants.pageCornerRadius
    private let leftMaskedCorners: CACornerMask = PageConstants.leftMaskedCorners
    private let rightMaskedCorners: CACornerMask = PageConstants.rightMaskedCorners

    // MARK: - 生命周期
    init(role: PageRole = .normal, isLeft: Bool = true, initialData: Data? = nil) {
        self.pageRole = role
        self.isLeft = isLeft
        super.init(frame: .zero)
        setupView()
        setupCanvas()
        if let initialData = initialData {
            loadDrawing(data: initialData)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        canvas.frame = bounds
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

    // MARK: - PKCanvasViewDelegate
    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if canvas.waitingForStrokeFinish {
            canvas.waitingForStrokeFinish = false
            saveSnapshot()
        }
    }

    // MARK: - Drawing 管理
    func loadDrawing(data: Data) {
        do {
            canvas.drawing = try PKDrawing(data: data)
        } catch {
            print("NotebookPageView: Failed to load drawing: \(error)")
        }
    }

    func exportDrawing() -> Data {
        return canvas.drawing.dataRepresentation()
    }

    // MARK: - 快照管理
    func undo() {
        guard snapshotIndex > 0 else { return }
        snapshotIndex -= 1
        print("Undo.", terminator: " ")
        applySnapshotOfIndex(snapshotIndex)
    }

    func redo() {
        guard snapshotIndex < pageSnapshots.count - 1 else { return }
        snapshotIndex += 1
        print("Redo.", terminator: " ")
        applySnapshotOfIndex(snapshotIndex)
    }

    private func currentSnapshot() -> PageSnapshot {
        return pageSnapshots[snapshotIndex]
    }

    private func saveSnapshot() {
        let currentSnapshot = PageSnapshot(drawing: PKDrawing(strokes: canvas.drawing.strokes))
        guard currentSnapshot != pageSnapshots[snapshotIndex] else {
            print("Skip snapshot!")
            return
        }

        if snapshotIndex < pageSnapshots.count - 1 {
            pageSnapshots = Array(pageSnapshots.prefix(snapshotIndex + 1))
        }

        pageSnapshots.append(currentSnapshot)
        snapshotIndex += 1
        if pageSnapshots.count > maxSnapshots {
            pageSnapshots.removeFirst()
            snapshotIndex -= 1
        }
        print("Saved snapshot #\(snapshotIndex).")
    }

    private func applySnapshotOfIndex(_ index: Int) {
        canvas.drawing = pageSnapshots[index].drawing
        canvas.tool = canvas.tool
        print("Apply snapshot #\(snapshotIndex)/\(pageSnapshots.count).")
        canvas.setNeedsDisplay()
    }
}
