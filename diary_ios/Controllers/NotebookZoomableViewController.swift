import UIKit

extension NotebookZoomableViewController: NotebookSpreadLayoutDelegate {
    func currentSpreadContentSize() -> CGSize { return spreadContainer.frame.size }
}

extension NotebookZoomableViewController: NotebookZoomStateDelegate {
    func isNotebookZoomedIn() -> Bool { return scrollView.zoomScale > maxZoomScaleForFlipping}
}

class NotebookZoomableViewController: UIViewController, UIScrollViewDelegate {
    private var scrollView = UIScrollView()
    private var spreadContainer = UIView(frame: CGRect(origin: .zero, 
                                    size: CGSize(
                                        width: PageConstants.pageSize.size.width * 2 + ZoomConstants.padding * 2, 
                                        height: PageConstants.pageSize.size.height + ZoomConstants.padding * 2)))
    private var notebookSpreadViewController = NotebookSpreadViewController()
    private var lastZoomScale = NotebookConstants.defaultZoomScale


    private let defaultZoomScale = NotebookConstants.defaultZoomScale
    private let maxZoomScaleForFlipping = NotebookConstants.maxZoomScaleForFlipping
    private let maxZoomScaleForCentering = NotebookConstants.maxZoomScaleForCentering
    private let padding = ZoomConstants.padding

    // MARK: - 生命周期
    init(notebookSpreadViewController: NotebookSpreadViewController) {
        super.init(nibName: nil, bundle: nil)
        self.notebookSpreadViewController = notebookSpreadViewController
        self.notebookSpreadViewController.layoutDelegate = self
        self.notebookSpreadViewController.zoomStateDelegate = self
        self.notebookSpreadViewController.onProgressChanged = { [weak self] offset in
            self?.centerContent(xOffset: offset)
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
        centerContent()
    }

    // MARK: - Setup
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(spreadContainer)

        scrollView.delegate = self
        scrollView.backgroundColor = .clear
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
            notebookSpreadViewController.view.topAnchor.constraint(equalTo: spreadContainer.topAnchor, constant: padding),
            notebookSpreadViewController.view.bottomAnchor.constraint(equalTo: spreadContainer.bottomAnchor, constant: -padding),
            notebookSpreadViewController.view.leadingAnchor.constraint(equalTo: spreadContainer.leadingAnchor, constant: padding),
            notebookSpreadViewController.view.trailingAnchor.constraint(equalTo: spreadContainer.trailingAnchor, constant: -padding)
        ])
        // 强制立即布局，确保约束生效，spreadContainer frame 正确
        spreadContainer.layoutIfNeeded()
        notebookSpreadViewController.didMove(toParent: self)
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - 调整内容缩放
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        scrollView.setZoomScale(defaultZoomScale, animated: true)
        lastZoomScale = defaultZoomScale
        printLayoutInfo(context: "Double Tap")
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return spreadContainer }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        lastZoomScale = scrollView.zoomScale
        if lastZoomScale <= maxZoomScaleForCentering{
            // need centering
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
            if notebookSpreadViewController.currentLeftIndex == 0 {
                centerContent(xOffset: -spreadContainer.frame.size.width / 4)
            } else if notebookSpreadViewController.currentLeftIndex == notebookSpreadViewController.pageCount - 2 {
                centerContent(xOffset: spreadContainer.frame.size.width / 4)
            } else {
                centerContent()
            }
            printLayoutInfo(context: "Need Centering")
        } else {
            // stop centering
            centerContent()
            scrollView.panGestureRecognizer.minimumNumberOfTouches = 1
            printLayoutInfo(context: "Still Centering")
        }
    }

    // MARK: - 调整内容位置
    private func centerContent(xOffset: CGFloat = 0) {
        let scrollSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        let centerX = max((scrollSize.width - contentSize.width) / 2, 0) + contentSize.width / 2
        let centerY = max((scrollSize.height - contentSize.height) / 2, 0) + contentSize.height / 2
        spreadContainer.center = CGPoint(x: centerX + xOffset, y: centerY)
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
        // print("   📌 scrollView.contentSize: \(formatSize(scrollView.contentSize))")
        print("   📌 spreadContainer.frame: \(formatRect(spreadContainer.frame))")
        print("   📌 spreadContainer.bounds: \(formatRect(spreadContainer.bounds))")
        print("   📌 spreadContainer.center: \(formatPoint(spreadContainer.center))")
        // print("   📌 notebookView.frame: \(formatRect(notebookSpreadViewController.view.frame))")
        // print("   📌 notebookView.bounds: \(formatRect(notebookSpreadViewController.view.bounds))")
    }
}
