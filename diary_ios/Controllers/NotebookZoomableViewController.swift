import UIKit

class NotebookZoomableViewController: UIViewController, UIScrollViewDelegate {
    let notebookSpreadVC: NotebookSpreadViewController
    let paperSize: PaperSize
    private let scrollView = UIScrollView()
    private let containerView = UIView()
    private var currentPageRole: PageRole = .cover

    init(notebookSpreadVC: NotebookSpreadViewController, paperSize: PaperSize = .a4a4) {
        self.notebookSpreadVC = notebookSpreadVC
        self.paperSize = paperSize
        super.init(nibName: nil, bundle: nil)
        self.notebookSpreadVC.pageDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        embedNotebookContent()
        setupDoubleTapGesture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupContainerIfNeeded()
        centerContent()
        scrollView.setZoomScale(0.8, animated: false)
    }

    // MARK: - Setup
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.7
        scrollView.maximumZoomScale = 2.0
        // scrollView.bouncesZoom = true
        // scrollView.contentInsetAdjustmentBehavior = .never
        // scrollView.showsHorizontalScrollIndicator = false
        // scrollView.showsVerticalScrollIndicator = false
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
    }

    private func embedNotebookContent() {
        addChild(notebookSpreadVC)
        scrollView.addSubview(containerView)
        containerView.addSubview(notebookSpreadVC.view)
        notebookSpreadVC.didMove(toParent: self)
    }

    private func setupContainerIfNeeded() {
        guard containerView.bounds.size == .zero else { return }
        let size = paperSize.size
        scrollView.contentSize = size
        containerView.frame.size = size
        notebookSpreadVC.view.frame.size = size
    }

    private func setupDoubleTapGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    private func centerContent(animated: Bool = false) {
        let scrollSize = scrollView.bounds.size
        let contentSize = containerView.frame.size
        let offsetX = max((scrollSize.width - contentSize.width) / 2, 0)
        let offsetY = max((scrollSize.height - contentSize.height) / 2, 0)

        var roleXOffset: CGFloat = 0
        switch currentPageRole {
        case .cover:
            roleXOffset = -contentSize.width / 4
        case .back:
            roleXOffset = contentSize.width / 4
        default:
            roleXOffset = 0
        }

        let newCenter = CGPoint(
            x: contentSize.width / 2 + offsetX + roleXOffset,
            y: contentSize.height / 2 + offsetY
        )

        if animated {
            let animator = UIViewPropertyAnimator(
                duration: 0.5, // 稍长，给用户一点“惯性”感
                dampingRatio: 0.8, // 弹性值越低，弹簧越强（0.7~0.85是常用范围）
                animations: {
                    self.containerView.center = newCenter
                }
            )
            animator.startAnimation()
        } else {
            containerView.center = newCenter
        }
    }

    @objc private func handleCoverPage(_ notification: Notification) {
        currentPageRole = .cover
    }

    @objc private func handleBackPage(_ notification: Notification) {
        currentPageRole = .back
    }
    
    @objc private func handleNormalPage(_ notification: Notification) {
        currentPageRole = .normal
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        scrollView.setZoomScale(0.8, animated: true)
        printLayoutInfo(context: "handleDoubleTap")
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
        printLayoutInfo(context: "scrollViewDidZoom")
    }

    // MARK: - Debug Info
    private func printLayoutInfo(context: String) {
        print("======== \(context) ========")
        print("📐 scrollView.frame: \(scrollView.frame)")
        print("📐 scrollView.contentSize: \(scrollView.contentSize)")
        print("📐 scrollView.contentOffset: \(scrollView.contentOffset)")
        print("📐 scrollView.zoomScale: \(scrollView.zoomScale)")
        print("📐 containerView.frame: \(containerView.frame)")
        print("📐 containerView.bounds: \(containerView.bounds)")
        print("📐 notebookView.frame: \(notebookSpreadVC.view.frame)")
        print("📐 notebookView.bounds: \(notebookSpreadVC.view.bounds)")
        print("================")
    }
}

extension NotebookZoomableViewController: NotebookSpreadViewControllerDelegate {
    func notebookSpreadViewController(_ controller: NotebookSpreadViewController, didUpdatePageRole role: PageRole) {
        currentPageRole = role
        centerContent(animated: true)
    }
}