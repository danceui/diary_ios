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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // centerContent()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. 配置 scrollView
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.5
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

        // 2. 加入 containerView
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        // 3. 加入 NotebookSpreadViewController
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

        // 4. 添加双击还原手势（可选）
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - ScrollView Delegate 缩放目标
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // centerContent()
        printLayoutInfo(context: "scrollViewDidZoom")
    }
    
    // private func centerContent() {
    //     let scrollViewSize = scrollView.bounds.size
    //     let contentSize = containerView.frame.size
    //     let scale = scrollView.zoomScale

    //     let verticalInset = max(0, (scrollViewSize.height - contentSize.height * scale) / 2)
    //     let horizontalInset = max(0, (scrollViewSize.width - contentSize.width * scale) / 2)

    //     scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    // }

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

    // MARK: - 双击还原缩放
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        scrollView.setZoomScale(1.0, animated: true)
        printLayoutInfo(context: "handleDoubleTap")
    }
}