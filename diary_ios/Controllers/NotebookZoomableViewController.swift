import UIKit

protocol NotebookZoomStateDelegate: AnyObject {
    func isNotebookZoomedIn() -> Bool
}

extension NotebookZoomableViewController: NotebookSpreadLayoutDelegate {
    func currentSpreadContentSize() -> CGSize { return spreadContainer.frame.size }
}

extension NotebookZoomableViewController: NotebookZoomStateDelegate {
    func isNotebookZoomedIn() -> Bool { return isZoomedIn}
}

class NotebookZoomableViewController: UIViewController, UIScrollViewDelegate {
    private var scrollView = UIScrollView()
    private var spreadContainer = UIView(frame: CGRect(origin: .zero, 
                                    size: CGSize(
                                        width: PageConstants.pageSize.size.width * 2 + ZoomConstants.leftPadding + ZoomConstants.rightPadding, 
                                        height: PageConstants.pageSize.size.height + ZoomConstants.topPadding + ZoomConstants.bottomPadding)))
    private var notebookSpreadViewController = NotebookSpreadViewController()
    private var lastZoomScale = NotebookConstants.defaultZoomScale
    private var isZoomedIn = false

    // MARK: - 生命周期
    init(notebookSpreadViewController: NotebookSpreadViewController) {
        super.init(nibName: nil, bundle: nil)
        self.notebookSpreadViewController = notebookSpreadViewController
        self.notebookSpreadViewController.layoutDelegate = self
        self.notebookSpreadViewController.zoomStateDelegate = self
        self.notebookSpreadViewController.onProgressChanged = { [weak self] offset in
            self?.centerSpreadContainer(xOffset: offset)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        printLifeCycleInfo(context: "[\(type(of: self))] 3️⃣ viewDidLoad", for: view)
        setupScrollView()
        setupSpreadViewController()
        setupGestures()
        // setupTestFunctions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        printLifeCycleInfo(context: "[\(type(of: self))] 6️⃣ viewDidLayoutSubviews", for: view)
        if scrollView.zoomScale != lastZoomScale {
            scrollView.setZoomScale(lastZoomScale, animated: false)
        }
        centerSpreadContainer()
    }

    // MARK: - Setup
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(spreadContainer)

        scrollView.delegate = self
        scrollView.backgroundColor = backgroundColor
        scrollView.minimumZoomScale = NotebookConstants.minZoomScale
        scrollView.maximumZoomScale = NotebookConstants.maxZoomScale
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = .normal

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupSpreadViewController() {
        addChild(notebookSpreadViewController)
        spreadContainer.addSubview(notebookSpreadViewController.view)

        notebookSpreadViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notebookSpreadViewController.view.topAnchor.constraint(equalTo: spreadContainer.topAnchor, constant: topPadding),
            notebookSpreadViewController.view.bottomAnchor.constraint(equalTo: spreadContainer.bottomAnchor, constant: -bottomPadding),
            notebookSpreadViewController.view.leadingAnchor.constraint(equalTo: spreadContainer.leadingAnchor, constant: leftPadding),
            notebookSpreadViewController.view.trailingAnchor.constraint(equalTo: spreadContainer.trailingAnchor, constant: -rightPadding)
        ])
        // 强制立即布局，确保约束生效，spreadContainer frame 正确
        spreadContainer.layoutIfNeeded()
        notebookSpreadViewController.didMove(toParent: self)
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber] 
        scrollView.addGestureRecognizer(doubleTap)
        scrollView.panGestureRecognizer.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
    }

    // MARK: - 调整内容缩放
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        lastZoomScale = scrollView.zoomScale
        scrollView.panGestureRecognizer.minimumNumberOfTouches = lastZoomScale <= maxZoomScaleForCentering ? 2 : 1
        if notebookSpreadViewController.currentLeftIndex == 0 {
            centerSpreadContainer(xOffset: -spreadContainer.frame.size.width / 4)
        } else if notebookSpreadViewController.currentLeftIndex == notebookSpreadViewController.pageCount - 2 {
            centerSpreadContainer(xOffset: spreadContainer.frame.size.width / 4)
        } else {
            centerSpreadContainer()
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        scrollView.setZoomScale(defaultZoomScale, animated: true)
        lastZoomScale = defaultZoomScale
        printLayoutInfo(context: "Double Tap")
    }

    private func centerSpreadContainer(xOffset: CGFloat = 0) {
        let scrollSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        let centerX = max((scrollSize.width - contentSize.width) / 2, 0) + contentSize.width / 2
        let centerY = max((scrollSize.height - contentSize.height) / 2, 0) + contentSize.height / 2
        spreadContainer.center = CGPoint(x: centerX + xOffset, y: centerY)
    }

    // MARK: - 更新位置关系
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateIsZoomedIn()
    }

    func updateIsZoomedIn() {
        let visibleRect = scrollView.convert(scrollView.bounds, to: notebookSpreadViewController.view)
        let spreadViewBounds = notebookSpreadViewController.view.bounds
        isZoomedIn = !visibleRect.contains(spreadViewBounds)
        // print("🔍 Updating isZoomedIn()")
        // print("   📐 notebookSpreadView.bounds: \(formatRect(spreadViewBounds))")
        // print("   📐 visibleRect in notebookView: \(formatRect(visibleRect))")
        // print("   👀 isFullyVisible: \(!isZoomedIn)")
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return spreadContainer
    }

    // MARK: - 生命周期测试函数
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        printLifeCycleInfo(context: "[\(type(of: self))] 4️⃣ viewWillAppear", for: view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        printLifeCycleInfo(context: "[\(type(of: self))] 7️⃣ viewDidAppear", for: view)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        printLifeCycleInfo(context: "[\(type(of: self))] 8️⃣ viewWillDisappear", for: view)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        printLifeCycleInfo(context: "[\(type(of: self))] 9️⃣ viewDidDisappear", for: view)
    }

    // MARK: - 常量
    private let defaultZoomScale = NotebookConstants.defaultZoomScale
    private let maxZoomScaleForCentering = NotebookConstants.maxZoomScaleForCentering
    private let leftPadding = ZoomConstants.leftPadding
    private let rightPadding = ZoomConstants.rightPadding
    private let topPadding = ZoomConstants.topPadding
    private let bottomPadding = ZoomConstants.bottomPadding
    private let verticalTolerance = ZoomConstants.verticalTolerance
    private let backgroundColor = ZoomConstants.backgroundColor

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
        print("   📌 notebookSpreadView.frame: \(formatRect(notebookSpreadViewController.view.frame))")
        // print("   📌 notebookSpreadView.bounds: \(formatRect(notebookSpreadViewController.view.bounds))")
    }
}
