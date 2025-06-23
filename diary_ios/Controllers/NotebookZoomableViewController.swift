import UIKit

extension NotebookZoomableViewController: NotebookSpreadViewControllerDelegate {
    func currentContentWidth() -> CGFloat {
        return spreadContainer.frame.size.width
    }
}

class NotebookZoomableViewController: UIViewController, UIScrollViewDelegate {
    private var notebookSpreadVC: NotebookSpreadViewController
    private var scrollView: UIScrollView!
    private var spreadContainer: UIView!
    private var centerXConstraint: NSLayoutConstraint!
    private var centerYConstraint: NSLayoutConstraint!
    private var layoutAnimator: UIViewPropertyAnimator?
    private var previousZoomScale = NotebookConstants.defaultZoomScale

    private let paperSize: PaperSize

    init(notebookSpreadVC: NotebookSpreadViewController, paperSize: PaperSize = .a4a4) {
        self.notebookSpreadVC = notebookSpreadVC
        self.paperSize = paperSize
        super.init(nibName: nil, bundle: nil)
        self.notebookSpreadVC.pageDelegate = self
        self.notebookSpreadVC.onProgressChanged = { [weak self] offset in
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
        setupNotebookSpreadVC()
        setupGestures()
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
        // 设置背景颜色以便调试
        // scrollView.backgroundColor = .yellow 

        spreadContainer = UIView()
        centerXConstraint = spreadContainer.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
        centerYConstraint = spreadContainer.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        scrollView.addSubview(spreadContainer)
        spreadContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXConstraint,
            centerYConstraint,
            spreadContainer.widthAnchor.constraint(equalToConstant: paperSize.size.width),
            spreadContainer.heightAnchor.constraint(equalToConstant: paperSize.size.height)
        ])
        spreadContainer.backgroundColor = .yellow // 设置背景颜色以便调试

    }

    private func setupNotebookSpreadVC() {
        // notebookSpreadVC.view.frame = spreadContainer.bounds // 确保notebookSpreadVC.view填满spreadContainer
        addChild(notebookSpreadVC)
        notebookSpreadVC.view.translatesAutoresizingMaskIntoConstraints = false
        spreadContainer.addSubview(notebookSpreadVC.view)
        NSLayoutConstraint.activate([
            notebookSpreadVC.view.topAnchor.constraint(equalTo: spreadContainer.topAnchor),
            notebookSpreadVC.view.bottomAnchor.constraint(equalTo: spreadContainer.bottomAnchor),
            notebookSpreadVC.view.leadingAnchor.constraint(equalTo: spreadContainer.leadingAnchor),
            notebookSpreadVC.view.trailingAnchor.constraint(equalTo: spreadContainer.trailingAnchor)
        ])
        notebookSpreadVC.didMove(toParent: self)
        // notebookSpreadVC.view.backgroundColor = .yellow // 设置背景颜色以便调试
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - 调整内容位置
    private func centerContent(roleXOffset: CGFloat = 0) {
        // centerXConstraint.constant = roleXOffset
        // UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
        //     self.view.layoutIfNeeded()
        // }
    }

    // private func centerContent(roleXOffset: CGFloat = 0) {
    //     let scrollSize = scrollView.bounds.size
    //     let contentSize = spreadContainer.frame.size
    //     let offsetX = max((scrollSize.width - contentSize.width) / 2, 0)
    //     let offsetY = max((scrollSize.height - contentSize.height) / 2, 0)
    //     let targetCenter = CGPoint(
    //         x: contentSize.width / 2 + offsetX + roleXOffset,
    //         y: contentSize.height / 2 + offsetY
    //     )
    //     // 计算距离，设置动态时长
    //     let distance = hypot(spreadContainer.center.x - targetCenter.x,
    //                         spreadContainer.center.y - targetCenter.y)
    //     let duration = min(max(0.15, Double(distance / 500)), 0.5)
    //     // 停止任何已有动画
    //     layoutAnimator?.stopAnimation(true)
    //     // 创建 spring 动画器
    //     layoutAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.5) {
    //         self.spreadContainer.center = targetCenter
    //     }
    //     layoutAnimator?.startAnimation()
    //     // print("📐 roleXOffset: \(format(roleXOffset)), centerPoint: \(formatPoint(spreadContainer.center))")
    // }
    
    // MARK: - 调整内容缩放
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let targetScale: CGFloat = scrollView.zoomScale > 0.9 ? 0.8 : 1.0
        scrollView.setZoomScale(targetScale, animated: true)
        previousZoomScale = targetScale
        printLayoutInfo(context: "handleDoubleTap")
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return spreadContainer }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        previousZoomScale = scrollView.zoomScale
        // centerContent()
        let scrollViewSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        let insetX = max((scrollViewSize.width - contentSize.width) / 2, 0)
        let insetY = max((scrollViewSize.height - contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: 0, right: 0)

        printLayoutInfo(context: "scrollViewDidZoom")
    }

    // MARK: - 调试输出
    private func printLayoutInfo(context: String) {
        print("=======", terminator: " ")
        print("\(context)", terminator: " ")
        print("=======")
        print("📐 scrollView.frame: \(formatRect(scrollView.frame))")
        print("📐 scrollView.contentSize: \(formatSize(scrollView.contentSize))")
        print("📐 scrollView.contentOffset: \(formatPoint(scrollView.contentOffset))")
        print("📐 scrollView.zoomScale: \(format(scrollView.zoomScale))")
        print("📐 spreadContainer.frame: \(formatRect(spreadContainer.frame))")
        // print("📐 spreadContainer.bounds: \(formatRect(spreadContainer.bounds))")
        // print("📐 notebookView.frame: \(formatRect(notebookSpreadVC.view.frame))")
        // print("📐 notebookView.bounds: \(formatRect(notebookSpreadVC.view.bounds))")
        print("=======================")
    }
}
