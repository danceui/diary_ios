import UIKit

class NotebookZoomableViewController: UIViewController, UIScrollViewDelegate {
    let notebookSpreadVC: NotebookSpreadViewController

    private let scrollView = UIScrollView()
    private let containerView = UIView() // 包含 notebookSpreadVC 的 view

    init(notebookSpreadVC: NotebookSpreadViewController) {
        self.notebookSpreadVC = notebookSpreadVC
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 配置 scrollView
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.7
        scrollView.maximumZoomScale = 2.0
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 设置 containerView 固定 notebook 大小
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        // 加入 NotebookSpreadViewController
        addChild(notebookSpreadVC)
        containerView.addSubview(notebookSpreadVC.view)
        notebookSpreadVC.didMove(toParent: self)

        notebookSpreadVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notebookSpreadVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            notebookSpreadVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            notebookSpreadVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            notebookSpreadVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        scrollView.backgroundColor = .lightGray
        containerView.backgroundColor = UIColor.cyan.withAlphaComponent(0.3)

        // 添加双击还原手势（可选）
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - ScrollView Delegate 缩放目标
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        scrollView.setZoomScale(1.0, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if scrollView.contentSize != .zero {
            centerContent()
            printLayoutInfo(context: "🔍 scrollViewDidZoom")
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
        printLayoutInfo(context: "🔍 scrollViewDidZoom")
    }

    private func centerContent() {
        let scrollViewSize = scrollView.bounds.size
        let contentSize = containerView.frame.size

        let verticalInset = max(0, (scrollViewSize.height - contentSize.height) / 2)
        let horizontalInset = max(0, (scrollViewSize.width - contentSize.width) / 2)

        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }

    private func printLayoutInfo(context: String) {
        print("======== \(context) ========")
        print("📐 view.bounds: \(view.bounds)")
        print("📐 scrollView.frame: \(scrollView.frame)")
        print("📐 scrollView.contentSize: \(scrollView.contentSize)")
        print("📐 scrollView.contentOffset: \(scrollView.contentOffset)")
        print("📐 scrollView.zoomScale: \(scrollView.zoomScale)")
        print("📐 scrollView.contentInset: \(scrollView.contentInset)")
        print("📐 containerView.frame: \(containerView.frame)")
        print("📐 containerView.bounds: \(containerView.bounds)")
        if let notebookView = notebookSpreadVC.view {
            print("📐 notebookView.frame: \(notebookView.frame)")
            print("📐 notebookView.bounds: \(notebookView.bounds)")
        }
    }
}

extension NotebookZoomableViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 只允许两个及以上手指开始滑动或缩放
        return gestureRecognizer.numberOfTouches >= 2
    }
}
