import UIKit
class NotebookZoomableViewController: UIViewController, UIGestureRecognizerDelegate {
    let notebookSpreadVC: NotebookSpreadViewController

    // 限制区域：相对于 self.view 的 frame（中心对齐）
    let gestureArea = CGRect(x: (1024 - 900) / 2, y: (768 - 600) / 2, width: 900, height: 600) // iPad模拟器为例，可调
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
        // let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        pinch.delegate = self
        pan.delegate = self
        // rotation.delegate = self
        doubleTap.numberOfTapsRequired = 2

        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(pan)
        // view.addGestureRecognizer(rotation)
        view.addGestureRecognizer(doubleTap)
    }

    private func allTouches(in gesture: UIGestureRecognizer, within area: CGRect) -> Bool {
        for i in 0..<gesture.numberOfTouches {
            let point = gesture.location(ofTouch: i, in: self.view)
            if !area.contains(point) {
                return false
            }
        }
        return true
    }

    // MARK: 手势处理函数
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.numberOfTouches >= 2,
              let targetView = notebookSpreadVC.view else { return }

        if gesture.state == .began || gesture.state == .changed {
            targetView.transform = targetView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.numberOfTouches >= 2, allTouches(in: gesture, within: gestureArea),
              let targetView = notebookSpreadVC.view else { return }

        let translation = gesture.translation(in: view)
        if gesture.state == .began || gesture.state == .changed {
            targetView.transform = targetView.transform.translatedBy(x: translation.x, y: translation.y)
            gesture.setTranslation(.zero, in: view)
        }
    }

    // @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
    //     guard gesture.numberOfTouches >= 2, allTouches(in: gesture, within: gestureArea),
    //           let targetView = notebookSpreadVC.view else { return }

    //     if gesture.state == .began || gesture.state == .changed {
    //         targetView.transform = targetView.transform.rotated(by: gesture.rotation)
    //         gesture.rotation = 0
    //     }
    // }

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
        return gestureRecognizer.numberOfTouches >= 2 && allTouches(in: gestureRecognizer, within: gestureArea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
