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
        setupUI()
        setupGestures()
        embedNotebookContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
        scrollView.setZoomScale(0.8, animated: false)
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        scrollView.frame = view.bounds
        view.addSubview(scrollView)
        containerView.frame = CGRect(origin: .zero, size: paperSize.size)
        scrollView.addSubview(containerView)
    }

    private func embedNotebookContent() {
        addChild(notebookSpreadVC)
        containerView.addSubview(notebookSpreadVC.view)
        notebookSpreadVC.view.frame = containerView.bounds
        notebookSpreadVC.didMove(toParent: self)
    }

    private func updateLayout() {
        let size = paperSize.size
        scrollView.contentSize = size
        containerView.frame.size = size
        notebookSpreadVC.view.frame.size = containerView.bounds
        centerContent()
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    private func centerContent(animated: Bool = false) {
        let scrollSize = scrollView.bounds.size
        let contentSize = containerView.frame.size
        let visibleSize = CGSize(width: contentSize.width * scrollView.zoomScale, height: contentSize.height * scrollView.zoomScale)
        
        var offset = CGPoint(
            x: max((scrollSize.width - visibleSize.width) / 2, 0),
            y: max((scrollSize.height - visibleSize.height) / 2, 0))

        switch currentPageRole {
        case .cover:
            offset.x -= (contentSize.width / 4) * scrollView.zoomScale
        case .back:
            offset.x += (contentSize.width / 4) * scrollView.zoomScale
        default:
            break
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.scrollView.contentOffset = offset
            }
        } else {
            scrollView.contentOffset = offset
        }
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
