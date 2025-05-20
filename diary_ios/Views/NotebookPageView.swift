import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookPageView: UIView, PKCanvasViewDelegate {

    // MARK: - Public Properties
    let pageIndex: Int
    let canvas = HandwritingCanvas()

    // MARK: - Private Properties
    private var pageSnapshots: [PageSnapshot] = [PageSnapshot(drawing: PKDrawing())]
    private var snapshotIndex = 0
    private let maxSnapshots = 50

    // MARK: - Init
    init(frame: CGRect, pageIndex: Int, initialData: Data? = nil) {
        self.pageIndex = pageIndex
        super.init(frame: frame)
        setupCanvas()
        if let initialData = initialData {
            loadDrawing(data: initialData)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupCanvas() {
        canvas.backgroundColor = .yellow.withAlphaComponent(0.1)
        canvas.delegate = self
        canvas.translatesAutoresizingMaskIntoConstraints = false
        addSubview(canvas)

        NSLayoutConstraint.activate([
            canvas.topAnchor.constraint(equalTo: topAnchor),
            canvas.bottomAnchor.constraint(equalTo: bottomAnchor),
            canvas.leadingAnchor.constraint(equalTo: leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: trailingAnchor)
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
        print("Undo: snapshot #\(snapshotIndex)/\(pageSnapshots.count).")
        applySnapshotOfIndex(snapshotIndex)
    }

    func redo() {
        guard snapshotIndex < pageSnapshots.count - 1 else { return }
        snapshotIndex += 1
        print("Redo: snapshot #\(snapshotIndex)/\(pageSnapshots.count).")
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
        print("Save snapshot #\(snapshotIndex) with \(currentSnapshot.drawing.strokes.count) strokes.")

        if pageSnapshots.count > maxSnapshots {
            pageSnapshots.removeFirst()
            snapshotIndex -= 1
        }
    }

    private func applySnapshotOfIndex(_ index: Int) {
        canvas.drawing = pageSnapshots[index].drawing
        canvas.tool = canvas.tool
        print("iOS: Apply snapshot #\(index) with \(canvas.drawing.strokes.count) strokes.")
        canvas.setNeedsDisplay()
    }
}
