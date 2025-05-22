import UIKit

class NotebookZoomableViewController: UIViewController {
    let notebookSpreadVC: NotebookSpreadViewController
    private var currentScale: CGFloat = 1.0

    init(notebookSpreadVC: NotebookSpreadViewController) {
        self.notebookSpreadVC = notebookSpreadVC
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 添加子控制器
        addChild(notebookSpreadVC)
        view.addSubview(notebookSpreadVC.view)
        notebookSpreadVC.didMove(toParent: self)

        // 设置布局
        notebookSpreadVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notebookSpreadVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notebookSpreadVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            notebookSpreadVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            notebookSpreadVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
                notebookSpreadVC.view.transform = CGAffineTransform(scaleX: newScale, y: newScale)
            }
        case .ended:
            currentScale = notebookSpreadVC.view.transform.a
        default:
            break
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
