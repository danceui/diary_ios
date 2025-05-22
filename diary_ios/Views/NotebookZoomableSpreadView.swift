import UIKit
class NotebookZoomableSpreadView: UIViewController {
    let notebookSpreadViewController: NotebookSpreadViewController
    private var currentScale: CGFloat = 1.0

    init(notebookVC: NotebookSpreadViewController) {
        self.notebookSpreadViewController = notebookVC
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 添加子控制器
        addChild(notebookSpreadViewController)
        view.addSubview(notebookSpreadViewController.view)
        notebookSpreadViewController.didMove(toParent: self)

        // 设置布局
        notebookSpreadViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notebookSpreadViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notebookSpreadViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            notebookSpreadViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            notebookSpreadViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 添加缩放手势
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            let newScale = currentScale * gesture.scale
            if newScale >= 0.5 && newScale <= 2.5 {
                notebookSpreadViewController.view.transform = CGAffineTransform(scaleX: newScale, y: newScale)
            }
        case .ended:
            currentScale = notebookSpreadViewController.view.transform.a
        default:
            break
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
