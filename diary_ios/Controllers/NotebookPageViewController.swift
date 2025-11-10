import UIKit

@available(iOS 16.0, *)
class NotebookPageViewController: UIViewController, UIScrollViewDelegate {
    private(set) var pageID: UUID?
    private var scrollView = UIScrollView()

    private let contentView = UIView() // 真正被缩放/平移的容器
    private let pageView: NotebookPageView // 绘图视图
    private var canvasSize = CGSize(width: 4096, height: 4096)
    private let expandThreshold: CGFloat = 800 // 触边自动扩展阈值
    private let expandStep: CGFloat = 2048 // 触边自动扩展步长

    // MARK: - Initialization
    init(initialData: Data? = nil) {
        self.pageView = NotebookPageView(initialData: initialData)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var _link: CADisplayLink?
    private var _lastTS: CFTimeInterval = 0


    @objc private func _tick(_ dl: CADisplayLink) {
        if _lastTS != 0 {
            let gap = dl.timestamp - _lastTS
            if gap > 0.10 { // >100ms 认为卡住
                print(String(format: "🚨 Main gap %.0f ms", gap*1000))
            }
        }
        _lastTS = dl.timestamp
    }
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        _link = CADisplayLink(target: self, selector: #selector(_tick))
        _link?.add(to: .main, forMode: .common)   // 只监控
        view.backgroundColor = .clear
        setupScrollView()
        setupCanvas()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 先保证 contentView/pageView 的几何关系是最新的
        // （通常此处已经正确，但稳妥起见）
        contentView.frame.size = canvasSize
        pageView.frame = contentView.bounds
        // 旋转/尺寸变化后，确保最小缩放和居中合理
        updateMinZoomToFitIfNeeded()
        centerToMiddleIfWanted()
    }

    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 0.05 // 为了能看清画布，min 要允许很小

        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = false

        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    private func setupCanvas() {
        // contentView 作为被缩放的容器
        contentView.frame = CGRect(origin: .zero, size: canvasSize)
        scrollView.addSubview(contentView)
        scrollView.contentSize = canvasSize
        // 让 pageView 覆盖整个画布
        pageView.frame = contentView.bounds
        pageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(pageView)
        pageView.activateToolListener()
        // 初次缩放与居中
        updateMinZoomToFitIfNeeded()
        centerToMiddle()
        addDoubleTapToReset()
    }

    private func updateMinZoomToFitIfNeeded() {
        let inset: CGFloat = 16
        let wScale = (scrollView.bounds.width  - inset * 2) / contentView.bounds.width
        let hScale = (scrollView.bounds.height - inset * 2) / contentView.bounds.height
        let fitScale = min(wScale, hScale)
        // 允许看全就行，但不要小于一个安全下限
        let newMin = max(min(fitScale, 1.0), 0.02)
        if abs(scrollView.minimumZoomScale - newMin) > 0.001 {
            scrollView.minimumZoomScale = newMin
            if scrollView.zoomScale < newMin {
                scrollView.setZoomScale(newMin, animated: false)
            }
        }
    }

    private func centerToMiddle() {
        let visibleW = scrollView.bounds.width  / scrollView.zoomScale
        let visibleH = scrollView.bounds.height / scrollView.zoomScale
        let offsetX = max((scrollView.contentSize.width  - visibleW) * 0.5, 0)
        let offsetY = max((scrollView.contentSize.height - visibleH) * 0.5, 0)
        scrollView.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: false)
    }

    private func centerToMiddleIfWanted() {
        let visibleW = scrollView.bounds.width  / scrollView.zoomScale
        let visibleH = scrollView.bounds.height / scrollView.zoomScale
        let contentW = scrollView.contentSize.width
        let contentH = scrollView.contentSize.height
        if contentW < visibleW * 1.2 || contentH < visibleH * 1.2 {
            centerToMiddle()
        }
    }

    private func addDoubleTapToReset() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    @objc private func handleDoubleTap(_ gr: UITapGestureRecognizer) {
        updateMinZoomToFitIfNeeded()
        centerToMiddle()
    }

    // MARK: - Auto Expand
    private func autoExpandIfNeeded() {
        let scale = scrollView.zoomScale
        let visibleW = scrollView.bounds.width  / scale
        let visibleH = scrollView.bounds.height / scale
        let rightEdge = scrollView.contentOffset.x + visibleW
        let bottomEdge = scrollView.contentOffset.y + visibleH

        var needResize = false
        var newSize = scrollView.contentSize

        if rightEdge > newSize.width - expandThreshold {
            newSize.width += expandStep
            needResize = true
        }
        if bottomEdge > newSize.height - expandThreshold {
            newSize.height += expandStep
            needResize = true
        }

        if needResize {
            scrollView.contentSize = newSize
            canvasSize = newSize
            // 扩展 contentView / pageView 尺寸（保持原点不变，只往右/下长）
            var f = contentView.frame
            f.size = newSize
            contentView.frame = f
            pageView.frame = contentView.bounds
        }
    }

    // MARK: - UIScrollViewDelegate（缩放）
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { contentView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { autoExpandIfNeeded() }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { autoExpandIfNeeded() }

    // MARK: - undo redo
    func undo() { pageView.undo() }
    func redo() { pageView.redo() }
}
