import UIKit
class NotebookZoomableViewController: UIViewController, UIGestureRecognizerDelegate {
    let notebookSpreadVC: NotebookSpreadViewController

    private var currentTransform: CGAffineTransform = .identity

    init(notebookSpreadVC: NotebookSpreadViewController) {
        self.notebookSpreadVC = notebookSpreadVC
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(notebookSpreadVC)
        view.addSubview(notebookSpreadVC.view)
        notebookSpreadVC.didMove(toParent: self)

        notebookSpreadVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notebookSpreadVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notebookSpreadVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            notebookSpreadVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            notebookSpreadVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 分别添加手势
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))

        pinchGesture.delegate = self
        panGesture.delegate = self
        rotationGesture.delegate = self

        view.addGestureRecognizer(pinchGesture)
        view.addGestureRecognizer(panGesture)
        view.addGestureRecognizer(rotationGesture)
    }

    // MARK: 手势处理函数

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let targetView = notebookSpreadVC.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            targetView.transform = targetView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let targetView = notebookSpreadVC.view else { return }

        let translation = gesture.translation(in: view)
        if gesture.state == .began || gesture.state == .changed {
            targetView.transform = targetView.transform.translatedBy(x: translation.x, y: translation.y)
            gesture.setTranslation(.zero, in: view)
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let targetView = notebookSpreadVC.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            targetView.transform = targetView.transform.rotated(by: gesture.rotation)
            gesture.rotation = 0
        }
    }

    // MARK: 同时识别多个手势
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}