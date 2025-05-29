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
        return sv
    }()

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
        setupViews()
        setupNotebookSpreadVC()
        setupGestures()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerContent()
        scrollView.setZoomScale(0.8, animated: false)
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

    private func updateCenterOffset(progress: CGFloat, role: PageRole) {
        let offsetX = containerView.bounds.width / 4
        var roleXOffset: CGFloat = 0

        switch role {
        case .cover:
            roleXOffset = -offsetX * (1 - progress) // progress 从 0 到 -1
        case .back:
            roleXOffset = offsetX * (1 + progress) // progress 从 0 到 1
        default:
            return
        }

        let scrollSize = scrollView.bounds.size
        let contentSize = containerView.frame.size
        let offsetXCenter = max((scrollSize.width - contentSize.width) / 2, 0)
        let offsetYCenter = max((scrollSize.height - contentSize.height) / 2, 0)

        let newCenter = CGPoint(
            x: contentSize.width / 2 + offsetXCenter + roleXOffset,
            y: contentSize.height / 2 + offsetYCenter
        )

        containerView.center = newCenter
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
    func notebookSpreadViewController(_ controller: NotebookSpreadViewController, didUpdatePageFlipProgress progress: CGFloat, role: PageRole) {
        updateCenterOffset(progress: progress, role: role)
    }
}
