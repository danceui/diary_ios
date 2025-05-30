import UIKit

class NotebookZoomableViewController: UIViewController, UIScrollViewDelegate {
    let notebookSpreadVC: NotebookSpreadViewController
    let paperSize: PaperSize
    private let containerView = UIView()
    private var currentPageRole: PageRole = .cover

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.delegate = self
        sv.minimumZoomScale = 0.5
        sv.maximumZoomScale = 3.0
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.decelerationRate = .fast
        sv.panGestureRecognizer.minimumNumberOfTouches = 2
        return sv
    }()

    init(notebookSpreadVC: NotebookSpreadViewController, paperSize: PaperSize = .a4a4) {
        self.notebookSpreadVC = notebookSpreadVC
        self.paperSize = paperSize
        super.init(nibName: nil, bundle: nil)
        self.notebookSpreadVC.pageDelegate = self
        self.notebookSpreadVC.onProgressOffsetChanged = { [weak self] offset in
            self?.centerContent(roleXOffset: offset)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNotebookSpreadVC()
        setupGestures()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.setZoomScale(0.8, animated: false)
        centerContent()
    }

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .systemBackground
        scrollView.frame = view.bounds
        view.addSubview(scrollView)
        containerView.frame = CGRect(origin: .zero, size: paperSize.size)
        scrollView.addSubview(containerView)
    }

    private func setupNotebookSpreadVC() {
        addChild(notebookSpreadVC)
        containerView.addSubview(notebookSpreadVC.view)
        notebookSpreadVC.view.frame = containerView.bounds // 确保notebookSpreadVC.view填满containerView
        notebookSpreadVC.didMove(toParent: self)
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - Layout
    private func centerContent(roleXOffset: CGFloat = 0) {
        let scrollSize = scrollView.bounds.size
        let contentSize = containerView.frame.size
        let offsetX = max((scrollSize.width - contentSize.width) / 2, 0)
        let offsetY = max((scrollSize.height - contentSize.height) / 2, 0)

        containerView.center = CGPoint(
            x: contentSize.width / 2 + offsetX + roleXOffset,
            y: contentSize.height / 2 + offsetY
        )
        printLayoutInfo(context: "roleXOffset: \(format(roleXOffset)), centerPoint: \(formatPoint(containerView.center))")
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        scrollView.setZoomScale(0.8, animated: true)
        printLayoutInfo(context: "handleDoubleTap")
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return containerView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
        printLayoutInfo(context: "scrollViewDidZoom")
    }

    // MARK: - Debug Info
    private func printLayoutInfo(context: String) {
        print("\(context)")
        print("📐 scrollView.frame: \(formatRect(scrollView.frame))")
        print("📐 scrollView.contentSize: \(formatSize(scrollView.contentSize))")
        print("📐 scrollView.contentOffset: \(formatPoint(scrollView.contentOffset))")
        print("📐 scrollView.zoomScale: \(format(scrollView.zoomScale))")
        print("📐 containerView.frame: \(formatRect(containerView.frame))")
        print("📐 containerView.bounds: \(formatRect(containerView.bounds))")
        print("📐 notebookView.frame: \(formatRect(notebookSpreadVC.view.frame))")
        print("📐 notebookView.bounds: \(formatRect(notebookSpreadVC.view.bounds))")
        print("================")
    }
}

extension NotebookZoomableViewController: NotebookSpreadViewControllerDelegate {
    func notebookSpreadViewController(_ controller: NotebookSpreadViewController, didUpdatePageRole role: PageRole) {
        currentPageRole = role
        // centerContent()
    }
    func currentContentWidth() -> CGFloat {
        return containerView.frame.size.width
    }
}
