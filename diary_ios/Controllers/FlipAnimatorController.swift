import UIKit
class FlipAnimatorController {
    private weak var host: NotebookSpreadViewController?
    private var animator: UIViewPropertyAnimator?
    private var container: UIView?
    private var frontSnapshot: UIView?
    private var backSnapshot: UIView?
    var state: FlipState = .idle

    init(host: NotebookSpreadViewController) {
        self.host = host
    }

    func begin(direction: PageTurnDirection) {
        guard let host = host, !state.isFlipping else { return }
        cleanup()

        let newIndex = direction == .nextPage ? host.currentIndex + 2 : host.currentIndex - 2
        guard let currentPagePair = host.currentPagePair(),
              let targetPagePair = host.pagePair(at: newIndex) else { return }
        print("🎮 Control animation begin - target \(newIndex), \(newIndex + 1)")

        // 提前显示未来的左右页
        switch direction {
        case .nextPage:
            if let preloadPair = host.pagePair(at: host.currentIndex + 2) {
                let right = preloadPair.right
                right.view.frame = host.rightPageContainer.bounds
                host.rightPageContainer.subviews.forEach { $0.removeFromSuperview() }
                host.rightPageContainer.addSubview(right.view)
            }

        case .lastPage:
            if let preloadPair = host.pagePair(at: host.currentIndex - 2) {
                let left = preloadPair.left
                left.view.frame = host.leftPageContainer.bounds
                host.leftPageContainer.subviews.forEach { $0.removeFromSuperview() }
                host.leftPageContainer.addSubview(left.view)
            }
        }
        
        let container = UIView(frame: CGRect(x: direction == .nextPage ? host.view.bounds.width / 2 : 0, 
                                                y: 0, 
                                                width: host.view.bounds.width / 2, 
                                                height: host.view.bounds.height))
        container.layer.anchorPoint = CGPoint(x: direction == .nextPage ? 0 : 1, y: 0.5)
        container.layer.position = CGPoint(x: host.view.bounds.width / 2, y: host.view.bounds.height / 2)
        container.clipsToBounds = true
        container.layer.transform.m34 = -1.0 / 1500
        
        host.view.addSubview(container)
        self.container = container

        let fromPage = direction == .nextPage ? currentPagePair.right : currentPagePair.left
        let toPage = direction == .nextPage ? targetPagePair.left : targetPagePair.right
        guard let front = fromPage.view.snapshotView(afterScreenUpdates: true),
            let back = toPage.view.snapshotView(afterScreenUpdates: true) else { return }

        front.frame = container.bounds
        back.frame = container.bounds
        back.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0)
        container.addSubview(back)
        container.addSubview(front)

        backSnapshot = back
        frontSnapshot = front
        back.isHidden = true
        front.isHidden = false
        state = direction == .nextPage ? .flippingToNext : .flippingToLast
    }

    func update(direction: PageTurnDirection, progress: CGFloat) {
        guard let container = container else { return }

        var t = CATransform3DIdentity
        t.m34 = -1.0 / 1500
        container.layer.transform = CATransform3DRotate(t, progress * .pi, 0, 1, 0)

        print("🎮 Control animation update - progress \(format(progress))")
        frontSnapshot?.isHidden = abs(progress) >= 0.5
        backSnapshot?.isHidden = abs(progress) < 0.5
        host?.updateProgressOffset(direction: direction, progress: abs(progress))

        state = direction == .nextPage ? .flippingToNext : .flippingToLast
    }

    func complete(direction: PageTurnDirection) {
        guard let host = host, let container = container else { return }
        let newIndex = direction == .nextPage ? host.currentIndex + 2 : host.currentIndex - 2

        animator?.stopAnimation(true)
        print("🎮 Control animation complete.")

        animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeOut) {
            var t = CATransform3DIdentity
            t.m34 = -1.0 / 1000
            container.layer.transform = CATransform3DRotate(t, .pi, 0, 1, 0)
            self.frontSnapshot?.isHidden = true
            self.backSnapshot?.isHidden = false
            host.updateProgressOffset(direction: direction, progress: 1.0)
        }

        animator?.addCompletion { _ in
            host.goToPagePair(to: newIndex)
            self.cleanup()
        }
        animator?.startAnimation()
    }

    func cancel(direction: PageTurnDirection) {
        guard let host = host, let container = container else { return }

        animator?.stopAnimation(true)
        print("🎮 Control animation cancel.")

        animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
            var t = CATransform3DIdentity
            t.m34 = -1.0 / 1500
            container.layer.transform = CATransform3DRotate(t, 0, 0, 1, 0)
            self.frontSnapshot?.isHidden = false
            self.backSnapshot?.isHidden = true
            host.updateProgressOffset(direction: direction, progress: 0.0)
        }

        animator?.addCompletion { _ in
            host.goToPagePair(to: host.currentIndex)
            self.cleanup()
        }
        animator?.startAnimation()
    }

    func cleanup() {
        animator?.stopAnimation(true)
        animator = nil
        container?.removeFromSuperview()
        frontSnapshot?.removeFromSuperview()
        backSnapshot?.removeFromSuperview()
        container = nil
        frontSnapshot = nil
        backSnapshot = nil
        state = .idle
    }
}