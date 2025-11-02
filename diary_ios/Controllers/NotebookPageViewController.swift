import UIKit

@available(iOS 16.0, *)
class NotebookPageViewController: UIViewController, UIScrollViewDelegate {
    private(set) var pageID: UUID?
    private var scrollView = UIScrollView()
    private let pageView: NotebookPageView

    // MARK: - Initialization
    init(initialData: Data? = nil) {
        self.pageView = NotebookPageView(initialData: initialData)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupScrollView()
        setupCanvas()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerCanvasIfNeeded()
    }

    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 0.5

        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    private func setupCanvas() {
        // 让 pageView 初始尺寸等于“纸张”大小（你在 init 里已用 PageConstants 定了）
        pageView.frame = CGRect(origin: .zero, size: pageView.bounds.size)
        scrollView.addSubview(pageView)
        scrollView.contentSize = pageView.bounds.size

        pageView.activateToolListener()
        resetZoomToFit()
    }

    private func resetZoomToFit() {
        // 让画布尽量贴合宽度，同时保留最小/最大缩放范围
        let inset: CGFloat = 16
        let wScale = (scrollView.bounds.width  - inset * 2) / pageView.bounds.width
        let hScale = (scrollView.bounds.height - inset * 2) / pageView.bounds.height
        let fitScale = max(min(wScale, hScale), scrollView.minimumZoomScale)
        scrollView.minimumZoomScale = min(scrollView.minimumZoomScale, fitScale)
        scrollView.setZoomScale(fitScale, animated: false)
        centerCanvasIfNeeded()
    }

    private func centerCanvasIfNeeded() {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = pageView.frame

        frameToCenter.origin.x = frameToCenter.size.width  < boundsSize.width
            ? (boundsSize.width  - frameToCenter.size.width)  / 2 : 0
        frameToCenter.origin.y = frameToCenter.size.height < boundsSize.height
            ? (boundsSize.height - frameToCenter.size.height) / 2 : 0

        pageView.frame = frameToCenter
    }

    // MARK: - UIScrollViewDelegate（缩放）
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { pageView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerCanvasIfNeeded() }

    // MARK: - undo redo
    func undo() {
        pageView.undo()
    }

    func redo() {
        pageView.redo()
    }
    
}
