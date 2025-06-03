import UIKit
class FlipAnimatorController {
    private weak var host: NotebookSpreadViewController?
    private var animator: UIViewPropertyAnimator?
    private var state: AnimationState = .idle
    private var container: UIView?
    private var frontSnapshot: UIView?
    private var backSnapshot: UIView?
    private var lastProgressForTesting: CGFloat?

    private var pendingFlips: [PageTurnDirection] = []

    init(host: NotebookSpreadViewController) {
        self.host = host
    }

    func begin(direction: PageTurnDirection) {
        guard let host = host else { return }
        // 只有 idle 状态才允许从头搭建视图
        guard state == .idle else {
            // 如果不在闲置状态，就将请求入队，稍后自动触发
            print("⏰ Gesture began. Animation ongoing, enqueue \(direction).", terminator: " ")
            pendingFlips.append(direction)
            return
        }

        state = .manualDragging
        let newIndex = direction == .nextPage ? host.currentIndex + 2 : host.currentIndex - 2
        print("🔘 Begin animation: target \(newIndex), \(newIndex + 1).", terminator: " ")

        cleanupViews()
        guard let currentPair = host.currentPagePair(),
          let targetPair = host.pagePair(at: newIndex) else {
            return
        }

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
    }

    func update(direction: PageTurnDirection, progress: CGFloat) {
        guard let container = container else { return }
        guard state == .manualDragging || state == .manualRemaining else { 
            print("❌ Cannot update animation due to auto flip.")
            return 
        }

        var t = CATransform3DIdentity
        t.m34 = -1.0 / 1500
        container.layer.transform = CATransform3DRotate(t, progress * .pi, 0, 1, 0)

        if let last = lastProgressForTesting {
            if format(last) != format(progress) {
                print("🔘 Update animation: progress \(format(progress)).")
                lastProgressForTesting = progress
            }
        } else {
            print("🔘 Update animation: progress \(format(progress)).")
            lastProgressForTesting = progress
        }

        frontSnapshot?.isHidden = abs(progress) >= 0.5
        backSnapshot?.isHidden = abs(progress) < 0.5
        host?.updateProgressOffset(direction: direction, progress: abs(progress))
    }

    func complete(direction: PageTurnDirection, progress: CGFloat) {
        // 在 manualDragging 或 autoAnimating 阶段，都允许进入“补间”逻辑
        guard state != .idle else { return }

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
                print("🔘 Complete animation.", terminator: " ")
                self.cleanupViews()
                self.cleanupAnimations()
                self.host?.goToPagePair(to: direction == .nextPage ? self.host!.currentIndex + 2 : self.host!.currentIndex - 2)
                return
            }

            let p = predictedProgress[i]
            print("🔘 Complete called update.", terminator: " ")
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
        guard state != .idle else { return }
        if abs(progress) < 0.002 {
            print("🔘 Cancel animation (progress < 0.002).")
            host.goToPagePair(to: host.currentIndex)
            self.cleanupViews()
            self.cleanupAnimations()
            return
        }

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
                print("🔘 Cancel animation.", terminator: " ")
                self.cleanupViews()
                self.cleanupAnimations()
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

    func addPageAnimation(){
        guard state == .idle else { return }
        print("🔘 Add page animation.")
        begin(direction: .nextPage)
        // 由于 begin() 会把 state 设为 .manualDragging，这里要立刻再覆盖成 autoAnimating
        state = .autoAnimating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.complete(direction: .nextPage, progress: -0.1)
        }
    }

    private func cleanupViews() {
        print("🧹 Clean views.")
        animator?.stopAnimation(true)
        animator = nil
        container?.removeFromSuperview()
        frontSnapshot?.removeFromSuperview()
        backSnapshot?.removeFromSuperview()
        container = nil
        frontSnapshot = nil
        backSnapshot = nil
        lastProgressForTesting = nil
    }

    func cleanupAnimations() {
        print("🧹 Animation reset and dequeue.")
        animator?.stopAnimation(true)
        animator = nil
        state = .idle

        if let nextFlip = pendingFlips.first {
            pendingFlips.removeFirst()
            print("⏰ Next flip from queue: \(nextFlip)")
            begin(direction: nextFlip)
            // 由于 begin() 会把 state 设为 .manualDragging，这里要立刻再覆盖成 autoAnimating
            state = .autoAnimating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.complete(direction: nextFlip, progress: nextFlip == .nextPage ? -0.1 : 0.1)
            }
        }
    }
}