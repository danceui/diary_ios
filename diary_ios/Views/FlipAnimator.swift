import UIKit
import RiveRuntime

class FlipAnimator {
    private var riveViewModel: RiveViewModel
    private var riveView: RiveView

    init(container: UIView) {
        // ✅ 初始化 view model
        riveViewModel = RiveViewModel(
            fileName: "page_flip",
            stateMachineName: "FlipMachine",
            artboardName: "NotebookPageFlip"
        )

        // ✅ 获取 RiveView 并绑定到 container
        riveView = riveViewModel.createRiveView()
        riveView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(riveView)
        NSLayoutConstraint.activate([
            riveView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            riveView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            riveView.topAnchor.constraint(equalTo: container.topAnchor),
            riveView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // ✅ 必须将 RiveView 注入 ViewModel
        riveViewModel.setView(riveView)
        riveView.isHidden = true
        riveView.isUserInteractionEnabled = false  // 也可避免它拦截事件
    }

    func playFlip(direction: String, completion: (() -> Void)? = nil) {
        riveView.isHidden = false  // 👉 播放前显示
        if direction == "flipLeft" {
            riveViewModel.triggerInput("flipLeft")
        } else if direction == "flipRight" {
            riveViewModel.triggerInput("flipRight")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.riveView.isHidden = true  // 👉 播放后隐藏
            completion?()
        }
    }
}