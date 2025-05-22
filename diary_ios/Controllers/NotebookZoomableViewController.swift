import UIKit
class NotebookZoomableViewController: UIViewController, UIGestureRecognizerDelegate {
    let notebookSpreadVC: NotebookSpreadViewController

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
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        pinch.delegate = self
        pan.delegate = self
        rotation.delegate = self
        doubleTap.numberOfTapsRequired = 2

        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(rotation)
        view.addGestureRecognizer(doubleTap)
    }

    // MARK: 手势处理函数
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.numberOfTouches >= 2,
              let targetView = notebookSpreadVC.view else { return }

        let locationInView = gesture.location(in: targetView) // 获取缩放中心点

        if gesture.state == .began || gesture.state == .changed {
            let currentScale = targetView.transform.a
            var newScale = currentScale * gesture.scale
            newScale = max(0.5, min(newScale, 1.5)) // 限制缩放范围
            let scaleFactor = newScale / currentScale

            let anchor = locationInView
            let translatedAnchor = CGPoint(x: anchor.x - targetView.bounds.midX,
                                        y: anchor.y - targetView.bounds.midY)
            let translation = CGAffineTransform(translationX: translatedAnchor.x, y: translatedAnchor.y)
            let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
            let back = CGAffineTransform(translationX: -translatedAnchor.x, y: -translatedAnchor.y)

            // 先平移到缩放中心点，再缩放，最后平移回去
            targetView.transform = targetView.transform.concatenating(translation)
                                                        .concatenating(scale)
                                                        .concatenating(back)

            gesture.scale = 1.0
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.numberOfTouches >= 2,
              let targetView = notebookSpreadVC.view else { return }

        let translation = gesture.translation(in: view)
        if gesture.state == .began || gesture.state == .changed {
            targetView.transform = targetView.transform.translatedBy(x: translation.x, y: translation.y)
            gesture.setTranslation(.zero, in: view)
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.numberOfTouches >= 2,
              let targetView = notebookSpreadVC.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            targetView.transform = targetView.transform.rotated(by: gesture.rotation)
            gesture.rotation = 0
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let targetView = notebookSpreadVC.view else { return }

        UIView.animate(withDuration: 0.25, animations: {
            targetView.transform = .identity
        })
    }

    // MARK: 手势控制策略
    // 允许多个手势同时识别
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // 只允许两指及以上手势开始
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.numberOfTouches >= 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
