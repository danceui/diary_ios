import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageViewController: UIViewController, PKCanvasViewDelegate {

    let pageIndex: Int
    let pageRole: PageRole
    let canvas = HandwritingCanvas()

    private var pageSnapshots: [PageSnapshot] = [PageSnapshot(drawing: PKDrawing())]
    private var snapshotIndex = 0
    private let maxSnapshots = 50

    // MARK: - Init
    init(pageIndex: Int, role: PageRole = .normal, initialData: Data? = nil) {
        self.pageIndex = pageIndex
        self.pageRole = role
        super.init(nibName: nil, bundle: nil)
        if let initialData = initialData {
            loadDrawing(data: initialData)
        }
        if pageRole != .empty {
            self.view.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCanvas()
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
        
        canvas.layer.cornerRadius = 20
        canvas.layer.masksToBounds = true
        canvas.layer.borderColor = UIColor.lightGray.cgColor
        canvas.layer.borderWidth = 2

        canvas.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvas)

        NSLayoutConstraint.activate([
            canvas.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            canvas.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            canvas.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            canvas.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.85)
        ])
    }

    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if canvas.waitingForStrokeFinish {
            // print("Drawing updated — saving snapshot.")
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

    func currentSnapshot() -> PageSnapshot {
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
        print("Saved snapshot #\(snapshotIndex) on page \(pageIndex).")
    }

    private func applySnapshotOfIndex(_ index: Int) {
        canvas.drawing = pageSnapshots[index].drawing
        canvas.tool = canvas.tool
        print("Apply snapshot #\(snapshotIndex)/\(pageSnapshots.count) on page \(pageIndex).")
        canvas.setNeedsDisplay()
    }
}
