import UIKit

class NotebookZoomableViewController: UIViewController, UIScrollViewDelegate {
    let notebookSpreadVC: NotebookSpreadViewController
    let paperSize: PaperSize
    var currentPageRole: PageRole = .normal {
        didSet {
            print("currentPageRole changed to \(currentPageRole)")
            centerContent()
        }
    }
    private let scrollView = UIScrollView()
    private let containerView = UIView()

    init(notebookSpreadVC: NotebookSpreadViewController, paperSize: PaperSize = .a4a4) {
        self.notebookSpreadVC = notebookSpreadVC
        self.paperSize = paperSize
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // setupScrollView
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.7
        scrollView.maximumZoomScale = 2.0
        scrollView.bouncesZoom = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // embedNotebookSpreadVC
        addChild(notebookSpreadVC)
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(notebookSpreadVC.view)
        notebookSpreadVC.didMove(toParent: self)

        // addDoubleTapGesture
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        // notificationObservers
        NotificationCenter.default.addObserver(self, selector: #selector(handleCoverPage), name: .notebookPageIsCover, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBackPage), name: .notebookPageIsBack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNormalPage), name: .notebookPageIsNormal, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if containerView.bounds.size == .zero {
            let size = paperSize.size
            scrollView.contentSize = size
            containerView.frame.size = size
            notebookSpreadVC.view.frame.size = size
        }
        centerContent()
        scrollView.setZoomScale(0.8, animated: false)
    }

    // MARK: - Zoom Handling
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
        printLayoutInfo(context: "scrollViewDidZoom")
    }

    private func centerContent() {
        let scrollSize = scrollView.bounds.size
        let contentSize = containerView.frame.size

        let offsetX = max((scrollSize.width - contentSize.width) / 2, 0)
        let offsetY = max((scrollSize.height - contentSize.height) / 2, 0)
        var addtionalXOffset: CGFloat = 0
        if currentPageRole == .cover {
            addtionalXOffset = -contentSize.width / 4
        } else if currentPageRole == .back {
            addtionalXOffset = contentSize.width / 4
        }
        containerView.center = CGPoint(x: contentSize.width / 2 + offsetX + addtionalXOffset,
                                       y: contentSize.height / 2 + offsetY)
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

    // MARK: - Double Tap
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        scrollView.setZoomScale(0.8, animated: true)
        printLayoutInfo(context: "handleDoubleTap")
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
    }
}
