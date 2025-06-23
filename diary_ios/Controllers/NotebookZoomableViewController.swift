import UIKit

extension NotebookZoomableViewController: NotebookSpreadViewControllerDelegate {
    func currentContentWidth() -> CGFloat {
        return spreadContainer.frame.size.width
    }
}

class NotebookZoomableViewController: UIViewController, UIScrollViewDelegate {
    private var notebookSpreadViewController: NotebookSpreadViewController
    private var scrollView: UIScrollView!
    private var spreadContainer: UIView!
    private var layoutAnimator: UIViewPropertyAnimator?
    private var previousZoomScale = NotebookConstants.defaultZoomScale

    private let paperSize: PaperSize

    init(notebookSpreadViewController: NotebookSpreadViewController, paperSize: PaperSize = .a4a4) {
        self.notebookSpreadViewController = notebookSpreadViewController
        self.paperSize = paperSize
        super.init(nibName: nil, bundle: nil)
        self.notebookSpreadViewController.pageDelegate = self
        self.notebookSpreadViewController.onProgressChanged = { [weak self] offset in
            self?.centerContent(roleXOffset: offset)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupViews()
        setupNotebookSpreadViewController()
        setupGestures()
        // setupTestFunctions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if scrollView.zoomScale != previousZoomScale {
            scrollView.setZoomScale(previousZoomScale, animated: false)
        }
        centerContent()
    }

    // MARK: - Setup
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        scrollView.minimumZoomScale = NotebookConstants.minZoomScale
        scrollView.maximumZoomScale = NotebookConstants.maxZoomScale
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
    }

    private func setupViews() {
        // scrollView.frame = view.bounds // 确保scrollView填满整个视图
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        spreadContainer = UIView(frame: CGRect(origin: .zero, size: paperSize.size))
        scrollView.addSubview(spreadContainer)
    }

    private func setupNotebookSpreadViewController() {
        // notebookSpreadViewController.view.frame = spreadContainer.bounds // 确保notebookSpreadViewController.view填满spreadContainer
        addChild(notebookSpreadViewController)
        notebookSpreadViewController.view.translatesAutoresizingMaskIntoConstraints = false
        spreadContainer.addSubview(notebookSpreadViewController.view)
        NSLayoutConstraint.activate([
            notebookSpreadViewController.view.topAnchor.constraint(equalTo: spreadContainer.topAnchor),
            notebookSpreadViewController.view.bottomAnchor.constraint(equalTo: spreadContainer.bottomAnchor),
            notebookSpreadViewController.view.leadingAnchor.constraint(equalTo: spreadContainer.leadingAnchor),
            notebookSpreadViewController.view.trailingAnchor.constraint(equalTo: spreadContainer.trailingAnchor)
        ])
        notebookSpreadViewController.didMove(toParent: self)
        // notebookSpreadViewController.view.backgroundColor = .yellow // 设置背景颜色以便调试
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - 调整内容位置
    private func centerContent(roleXOffset: CGFloat = 0) {
        let scrollSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        let insetX = max((scrollSize.width - contentSize.width) / 2, 0)
        let insetY = max((scrollSize.height - contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX + roleXOffset, bottom: insetY, right: insetX - roleXOffset)
        scrollView.contentOffset = CGPoint(x: -scrollView.contentInset.left, y: -scrollView.contentInset.top)
    }
    
    // MARK: - 调整内容缩放
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let targetScale: CGFloat = scrollView.zoomScale > 0.9 ? 0.8 : 1.0
        scrollView.setZoomScale(targetScale, animated: true)
        previousZoomScale = targetScale
        printLayoutInfo(context: "Double Tap")
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return spreadContainer }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        previousZoomScale = scrollView.zoomScale
        centerContent()
        printLayoutInfo(context: "Scroll View Did Zoom")
    }

    // MARK: - 测试用
    private func setupTestFunctions() {
        addTestBorder(for: scrollView, color: .red, width: 2.0)
        addTestBorder(for: spreadContainer, color: .blue, width: 2.0)
        addTestBorder(for: notebookSpreadViewController.view, color: .green, width: 2.0)
    }

    private func printLayoutInfo(context: String) {
        print("📐 \(context)")
        print("   📌 scrollView.zoomScale: \(format(scrollView.zoomScale))")
        // print("   📌 scrollView.frame: \(formatRect(scrollView.frame))")
        print("   📌 scrollView.bounds: \(formatRect(scrollView.bounds))")
        print("   📌 scrollView.contentSize: \(formatSize(scrollView.contentSize))")
        print("   📌 spreadContainer.frame: \(formatRect(spreadContainer.frame))")
        // print("   📌 spreadContainer.bounds: \(formatRect(spreadContainer.bounds))")
        // print("   📌 notebookView.frame: \(formatRect(notebookSpreadViewController.view.frame))")
        // print("   📌 notebookView.bounds: \(formatRect(notebookSpreadViewController.view.bounds))")
    }
}
