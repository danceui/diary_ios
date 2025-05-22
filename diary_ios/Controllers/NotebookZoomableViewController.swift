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

        // 计算双指中点
        let touch1 = gesture.location(ofTouch: 0, in: targetView)
        let touch2 = gesture.location(ofTouch: 1, in: targetView)
        let pinchCenter = CGPoint(x: (touch1.x + touch2.x) / 2, 
                                y: (touch1.y + touch2.y) / 2)

        if gesture.state == .began {
            // 只存储初始状态，不修改gesture.scale
            let currentScale = targetView.transform.a
            targetView.layer.setValue(currentScale, forKey: "initialScale")
            targetView.layer.setValue(pinchCenter, forKey: "initialPinchCenter")
        }
        
        if gesture.state == .changed {
            guard let initialScale = targetView.layer.value(forKey: "initialScale") as? CGFloat,
                let initialPinchCenter = targetView.layer.value(forKey: "initialPinchCenter") as? CGPoint else { return }
            // 直接使用gesture.scale作为相对变化量
            var newScale = initialScale * gesture.scale
            newScale = max(0.7, min(newScale, 1.5)) // 限制缩放范围

            // 计算偏移（保持视觉中心稳定）
            let offsetX = pinchCenter.x - initialPinchCenter.x
            let offsetY = pinchCenter.y - initialPinchCenter.y

            // 应用变换
            targetView.transform = CGAffineTransform.identity
                .translatedBy(x: offsetX, y: offsetY)
                .scaledBy(x: newScale, y: newScale)
                .translatedBy(x: -offsetX, y: -offsetY)
        }

        if gesture.state == .ended || gesture.state == .cancelled {
            // 清理存储的状态
            targetView.layer.setValue(nil, forKey: "initialTranslation")
            targetView.layer.setValue(nil, forKey: "initialPinchCenter")
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
