import UIKit
class FlipAnimatorController {
    private weak var host: NotebookSpreadViewController?
    private var animator: UIViewPropertyAnimator?
    private var container: UIView?
    private var frontSnapshot: UIView?
    private var backSnapshot: UIView?
    private var lastProgressForTesting: CGFloat?
    var state: FlipState = .idle

    init(host: NotebookSpreadViewController) {
        self.host = host
    }

    func begin(direction: PageTurnDirection) {
        guard let host = host, !state.isFlipping else { return }
        cleanup()

        let newIndex = direction == .nextPage ? host.currentIndex + 2 : host.currentIndex - 2
        guard let currentPair = host.currentPagePair(),
          let targetPair = host.pagePair(at: newIndex) else { return }

        print("🎮 Control animation begin - target \(newIndex), \(newIndex + 1)")

        guard let currentLeftSnapshot = currentPair.left.view.snapshotView(afterScreenUpdates: true),
            let currentRightSnapshot = currentPair.right.view.snapshotView(afterScreenUpdates: true),
            let targetLeftSnapshot = targetPair.left.view.snapshotView(afterScreenUpdates: true),
            let targetRightSnapshot = targetPair.right.view.snapshotView(afterScreenUpdates: true) else {
            print("❌ Snapshot generation failed.")
            return
        }

        currentLeftSnapshot.frame = host.leftPageContainer.bounds
        currentRightSnapshot.frame = host.rightPageContainer.bounds
        targetLeftSnapshot.frame = host.leftPageContainer.bounds
        targetRightSnapshot.frame = host.rightPageContainer.bounds

        host.leftPageContainer.subviews.forEach { $0.removeFromSuperview() }
        host.rightPageContainer.subviews.forEach { $0.removeFromSuperview() }
        if direction == .nextPage {
            host.leftPageContainer.addSubview(currentLeftSnapshot)
            host.rightPageContainer.addSubview(targetRightSnapshot)
        } else {
            host.leftPageContainer.addSubview(targetLeftSnapshot)
            host.rightPageContainer.addSubview(currentRightSnapshot)
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

        let front = direction == .nextPage ? currentRightSnapshot : currentLeftSnapshot
        let back = direction == .nextPage ? targetLeftSnapshot : targetRightSnapshot
        backSnapshot = back
        frontSnapshot = front
        front.frame = container.bounds
        back.frame = container.bounds
        back.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0)
        back.isHidden = true
        front.isHidden = false
        container.addSubview(back)
        container.addSubview(front)

        state = direction == .nextPage ? .flippingToNext : .flippingToLast
    }

    func update(direction: PageTurnDirection, progress: CGFloat) {
        guard let container = container else { return }

        var t = CATransform3DIdentity
        t.m34 = -1.0 / 1500
        container.layer.transform = CATransform3DRotate(t, progress * .pi, 0, 1, 0)

        if let last = lastProgressForTesting {
            if format(last) != format(progress) {
                print("🎮 Control animation update - progress \(format(progress))")
                lastProgressForTesting = progress
            }
        } else {
            print("🎮 Control animation update - progress \(format(progress))")
            lastProgressForTesting = progress
        }

        frontSnapshot?.isHidden = abs(progress) >= 0.5
        backSnapshot?.isHidden = abs(progress) < 0.5
        host?.updateProgressOffset(direction: direction, progress: abs(progress))

        state = direction == .nextPage ? .flippingToNext : .flippingToLast
    }

    func complete(direction: PageTurnDirection, progress: CGFloat) {
        print("🎮 Control animation complete.")
        let duration: TimeInterval = 0.4
        let steps = 30
        let interval = duration / Double(steps)
        let target: CGFloat =  progress >= 0 ? 1.0 : -1.0
        let delta = target - progress
        var predictedProgress: [CGFloat] = []

        for i in 1...steps {
            // Ease-out 曲线（模拟减速滑动）: p = 1 - (1 - t)^2
            let t = CGFloat(i) / CGFloat(steps)
            let easedT = 1 - pow(1 - t, 2)
            let interpolated = progress + delta * easedT
            predictedProgress.append(interpolated)
        }

        var i = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if i >= predictedProgress.count {
                timer.invalidate()
                self.host?.goToPagePair(to: direction == .nextPage ? self.host!.currentIndex + 2 : self.host!.currentIndex - 2)
                self.cleanup()
                return
            }

            let p = predictedProgress[i]
            self.update(direction: direction, progress: p)

            if abs(p) >= 0.5 {
                self.frontSnapshot?.isHidden = true
                self.backSnapshot?.isHidden = false
            }

            i += 1
        }
    }

    func cancel(direction: PageTurnDirection, progress: CGFloat) {
        guard let host = host else { return }
        if abs(progress) < 0.002 {
            print("🎮 Control animation cancel (progress < 0.002).")
            host.goToPagePair(to: host.currentIndex)
            self.cleanup()
            return
        }

        print("🎮 Control animation cancel.")
        let duration: TimeInterval = 0.4
        let steps = 30
        let interval = duration / Double(steps)
        let delta = -progress
        var predictedProgress: [CGFloat] = []
        
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let easedT = 1 - pow(1 - t, 2)  // ease-out curve
            let interpolated = progress + delta * easedT
            predictedProgress.append(interpolated)
        }

        var i = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if i >= predictedProgress.count {
                timer.invalidate()
                host.goToPagePair(to: host.currentIndex)
                self.cleanup()
                return
            }

            let p = predictedProgress[i]
            self.update(direction: direction, progress: p)

            if abs(p) < 0.5 {
                self.frontSnapshot?.isHidden = false
                self.backSnapshot?.isHidden = true
            }

            i += 1
        }
    }

    func cleanup() {
        print("🧹 Clean all animations.")
        animator?.stopAnimation(true)
        animator = nil
        container?.removeFromSuperview()
        frontSnapshot?.removeFromSuperview()
        backSnapshot?.removeFromSuperview()
        container = nil
        frontSnapshot = nil
        backSnapshot = nil
        lastProgressForTesting = nil
        state = .idle
    }
}
