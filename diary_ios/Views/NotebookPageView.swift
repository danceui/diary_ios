// NotebookPageView.swift
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
    private let spineWidth: CGFloat = 12
    private let paperColor = UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0)
    private let lineSpacing: CGFloat = 24

    private lazy var spineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.7, alpha: 1.0)
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 3
        view.layer.shadowOpacity = 0.2
        return view
    }()

    private var guidelinesAdded = false
    private var stitchesAdded = false

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
        setupPageAppearance()
        setupCanvas()
        setupSpine()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !guidelinesAdded {
            addWritingGuidelines()
            guidelinesAdded = true
        }
        if !stitchesAdded {
            addStitches()
            stitchesAdded = true
        }
    }

    private func setupPageAppearance() {
        view.backgroundColor = .clear
        let paperView = UIView()
        paperView.backgroundColor = paperColor
        paperView.layer.cornerRadius = 4
        paperView.layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor
        paperView.layer.borderWidth = 1
        paperView.layer.shadowColor = UIColor.black.cgColor
        paperView.layer.shadowOffset = CGSize(width: 0, height: 2)
        paperView.layer.shadowRadius = 3
        paperView.layer.shadowOpacity = 0.1

        view.addSubview(paperView)
        paperView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paperView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            paperView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            paperView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            paperView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupCanvas() {
        canvas.delegate = self
        canvas.backgroundColor = .clear
        canvas.isOpaque = false

        view.addSubview(canvas)
        canvas.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            canvas.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            canvas.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            canvas.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            canvas.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func setupSpine() {
        view.addSubview(spineView)
        spineView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            spineView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spineView.topAnchor.constraint(equalTo: view.topAnchor, constant: 25),
            spineView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -25),
            spineView.widthAnchor.constraint(equalToConstant: spineWidth)
        ])
    }

    private func addStitches() {
        let stitches = CAShapeLayer()
        let path = UIBezierPath()
        let stitchSpacing: CGFloat = 20

        for y in stride(from: 0, to: view.bounds.height, by: stitchSpacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: spineWidth, y: y + stitchSpacing/2))
            path.move(to: CGPoint(x: 0, y: y + stitchSpacing/2))
            path.addLine(to: CGPoint(x: spineWidth, y: y + stitchSpacing))
        }

        stitches.path = path.cgPath
        stitches.strokeColor = UIColor(white: 0.5, alpha: 0.3).cgColor
        stitches.lineWidth = 1
        spineView.layer.addSublayer(stitches)
    }

    private func addWritingGuidelines() {
        let guidelineView = UIView(frame: view.bounds)
        guidelineView.backgroundColor = .clear
        guidelineView.isUserInteractionEnabled = false

        let lineLayer = CAShapeLayer()
        let path = UIBezierPath()

        for i in 0..<Int((view.bounds.height - 60) / lineSpacing) {
            let y = CGFloat(i) * lineSpacing + 50
            path.move(to: CGPoint(x: 40, y: y))
            path.addLine(to: CGPoint(x: view.bounds.width - 40, y: y))
        }

        lineLayer.path = path.cgPath
        lineLayer.strokeColor = UIColor(white: 0.8, alpha: 0.3).cgColor
        lineLayer.lineWidth = 1.5
        lineLayer.contentsScale = UIScreen.main.scale

        guidelineView.layer.addSublayer(lineLayer)
        view.insertSubview(guidelineView, belowSubview: canvas)
    }

    func updateSpineStyle(isCurrentPage: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.spineView.backgroundColor = isCurrentPage ? UIColor(white: 0.6, alpha: 1.0) : UIColor(white: 0.7, alpha: 1.0)
            self.spineView.layer.shadowOpacity = isCurrentPage ? 0.3 : 0.1
        }
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if canvas.waitingForStrokeFinish {
            canvas.waitingForStrokeFinish = false
            saveSnapshot()
        }
    }

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

    func undo() {
        guard snapshotIndex > 0 else { return }
        snapshotIndex -= 1
        applySnapshotOfIndex(snapshotIndex)
    }

    func redo() {
        guard snapshotIndex < pageSnapshots.count - 1 else { return }
        snapshotIndex += 1
        applySnapshotOfIndex(snapshotIndex)
    }

    private func currentSnapshot() -> PageSnapshot {
        return pageSnapshots[snapshotIndex]
    }

    private func saveSnapshot() {
        let currentSnapshot = PageSnapshot(drawing: PKDrawing(strokes: canvas.drawing.strokes))
        guard currentSnapshot != pageSnapshots[snapshotIndex] else {
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
    }

    private func applySnapshotOfIndex(_ index: Int) {
        canvas.drawing = pageSnapshots[index].drawing
        canvas.reloadInputViews()
    }
} // End of NotebookPageView
