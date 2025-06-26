import UIKit

extension NotebookZoomableViewController: NotebookSpreadLayoutDelegate {
    func currentSpreadContentSize() -> CGSize {
        return spreadContainer.frame.size
    }
}

class NotebookZoomableViewController: UIViewController, UIScrollViewDelegate {
    private var scrollView = UIScrollView()
    private var spreadContainer = UIView(frame: CGRect(origin: .zero, size: PageConstants.pageSize.doubleSize))
    private var notebookSpreadViewController = NotebookSpreadViewController()
    private var layoutAnimator: UIViewPropertyAnimator?
    private var previousZoomScale = NotebookConstants.defaultZoomScale

    // MARK: - 生命周期
    init(notebookSpreadViewController: NotebookSpreadViewController) {
        self.notebookSpreadViewController = notebookSpreadViewController
        super.init(nibName: nil, bundle: nil)
        self.notebookSpreadViewController.layoutDelegate = self
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
        if scrollView.zoomScale != previousZoomScale {
            scrollView.setZoomScale(previousZoomScale, animated: false)
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
        scrollView.decelerationRate = .fast
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2

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
            notebookSpreadViewController.view.topAnchor.constraint(equalTo: spreadContainer.topAnchor),
            notebookSpreadViewController.view.bottomAnchor.constraint(equalTo: spreadContainer.bottomAnchor),
            notebookSpreadViewController.view.leadingAnchor.constraint(equalTo: spreadContainer.leadingAnchor),
            notebookSpreadViewController.view.trailingAnchor.constraint(equalTo: spreadContainer.trailingAnchor)
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

    // MARK: - 居中函数
    private func centerContent(xOffset: CGFloat = 0) {
        let scrollSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        let insetX = max((scrollSize.width - contentSize.width) / 2, 0)
        let insetY = max((scrollSize.height - contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX + xOffset, bottom: insetY, right: insetX - xOffset)
        scrollView.contentOffset = CGPoint(x: -scrollView.contentInset.left, y: -scrollView.contentInset.top)
    }
    
    // MARK: - 调整内容缩放
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let targetScale: CGFloat = scrollView.zoomScale > 0.9 ? 0.8 : 1.0
        scrollView.setZoomScale(targetScale, animated: true)
        previousZoomScale = targetScale
        printLayoutInfo(context: "Double Tap")
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return spreadContainer }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        previousZoomScale = scrollView.zoomScale
        if notebookSpreadViewController.currentIndex == 0 {
            centerContent(xOffset: -spreadContainer.frame.size.width / 4)
        } else if notebookSpreadViewController.currentIndex == notebookSpreadViewController.pageCount - 2 {
            centerContent(xOffset: spreadContainer.frame.size.width / 4)
        } else {
            centerContent()
        }
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
        print("   📌 scrollView.contentSize: \(formatSize(scrollView.contentSize))")
        print("   📌 spreadContainer.frame: \(formatRect(spreadContainer.frame))")
        print("   📌 spreadContainer.bounds: \(formatRect(spreadContainer.bounds))")
        // print("   📌 notebookView.frame: \(formatRect(notebookSpreadViewController.view.frame))")
        // print("   📌 notebookView.bounds: \(formatRect(notebookSpreadViewController.view.bounds))")
    }
}
