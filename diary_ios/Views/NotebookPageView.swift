import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIViewController, PKCanvasViewDelegate {

    // MARK: - Public Properties
    let pageIndex: Int
    let canvas = HandwritingCanvas()

    // MARK: - Private Properties
    private var pageSnapshots: [PageSnapshot] = [PageSnapshot(drawing: PKDrawing())]
    private var snapshotIndex = 0
    private let maxSnapshots = 50

    // MARK: - Init
    init(pageIndex: Int, initialData: Data? = nil) {
        self.pageIndex = pageIndex
        super.init(nibName: nil, bundle: nil)
        if let initialData = initialData {
            loadDrawing(data: initialData)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCanvas()
    }

    private func setupCanvas() {
        canvas.delegate = self
        canvas.backgroundColor = .yellow.withAlphaComponent(0.1)
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

    // MARK: - Drawing Data I/O
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


    // MARK: - Undo/Redo
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

    // MARK: - Snapshot Mgmt
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
