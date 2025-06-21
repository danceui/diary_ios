import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageViewController: UIViewController, PKCanvasViewDelegate {
    let pageRole: PageRole
    let canvas = HandwritingCanvas()

    private var pageSnapshots: [PageSnapshot] = [PageSnapshot(drawing: PKDrawing())]
    private var snapshotIndex = 0

    // MARK: - 常量
    private let maxSnapshots = 50
    private let pageCornerRadius = PageConstants.pageCornerRadius

    // MARK: - 生命周期
    init(role: PageRole = .normal, initialData: Data? = nil) {
        pageRole = role
        super.init(nibName: nil, bundle: nil)
        if let initialData = initialData {
            loadDrawing(data: initialData)
        }
        setupViewStyle()
    }

    required init?(coder: NSCoder) {
        // This class is not intended to be initialized from a storyboard.
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCanvas()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        canvas.frame = view.bounds
    }

    private func setupViewStyle() {
        view.backgroundColor = UIColor(red: 0.93, green: 0.91, blue: 0.86, alpha: 1.00) // 浅绿色背景
        view.layer.cornerRadius = pageCornerRadius
        view.layer.masksToBounds = true
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
        canvas.layer.masksToBounds = true
        view.addSubview(canvas)
    }

    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if canvas.waitingForStrokeFinish {
            canvas.waitingForStrokeFinish = false
            saveSnapshot()
        }
    }

    func loadDrawing(data: Data) {
        do {
            canvas.drawing = try PKDrawing(data: data)
        } catch {
            print("NotebookPageViewController: Failed to load drawing: \(error)")
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
