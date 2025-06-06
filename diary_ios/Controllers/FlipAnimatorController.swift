import UIKit
class FlipAnimatorController {
    private weak var host: NotebookSpreadViewController?
    private var animator: UIViewPropertyAnimator?
    private var state: AnimationState = .idle
    
    private var container: UIView?
    private var frontSnapshot: UIView?
    private var backSnapshot: UIView?
    private var lastProgressForTesting: CGFloat?

    private var pendingFlips: [FlipRequest] = []
    var isAnimating: Bool { return state != .idle }

    // MARK: - constant paramaters
    private let easing: EasingFunction = .sineEaseOut
    private let baseVelocity: CGFloat = 1000
    private let minSpeedFactor: CGFloat = 1
    private let maxSpeedFactor: CGFloat = 1.5
    private let baseDuration: TimeInterval = 0.4

    init(host: NotebookSpreadViewController) {
        self.host = host
    }

    func begin(direction: PageTurnDirection, type: AnimationType) {
        guard let host = host else { return }
        
        guard state == .idle else {
            print("⏰ Begin with type \(type) but state is \(state). Enqueue.")
            pendingFlips.append(.init(direction: direction, type: .auto))
            return
        }
        print("🔘 Begin animation [state: \(state), type: \(type)].", terminator: " ")
        cleanupViews()
        state = (type == .manual ? .manualFlipping : .autoFlipping)
        
        let newIndex = direction == .nextPage ? host.currentIndex + 2 : host.currentIndex - 2
        guard let currentPair = host.currentPagePair(), let targetPair = host.pagePair(at: newIndex) 
        else {
            state = .idle
            return
        }

        let (frontView, backView): (UIView, UIView) = {
            if direction == .nextPage {
                return (currentPair.right.view, targetPair.left.view)
            } else {
                return (currentPair.left.view, targetPair.right.view)
            }
        }()

        guard let front = frontView.snapshotView(afterScreenUpdates: true), let back = backView.snapshotView(afterScreenUpdates: true)
        else {
            print("❌ Snapshot generation failed.")
            state = .idle
            return
        }

        let pagesContainer = host.pagesContainer
        let frontFrame = host.frameOfSinglePage(at: (direction == .nextPage ? host.currentIndex + 1 : host.currentIndex))
        let backFrame = host.frameOfSinglePage(at: (direction == .nextPage ? newIndex : newIndex + 1))
        front.frame = frontFrame
        back.frame  = backFrame

        pagesContainer.subviews
            .filter { $0.tag == 999 }
            .forEach { $0.removeFromSuperview() }
        let container = UIView(frame: CGRect(x: direction == .nextPage ? host.view.bounds.width / 2 : 0, 
                                                y: 0, 
                                                width: host.view.bounds.width / 2, 
                                                height: host.view.bounds.height))
        container.clipsToBounds = true
        container.tag = 999
        container.layer.anchorPoint = CGPoint(x: direction == .nextPage ? 0 : 1, y: 0.5)
        container.layer.position = CGPoint(x: host.view.bounds.width / 2, y: host.view.bounds.height / 2)
        container.layer.transform.m34 = -1.0 / 1500
        
        pagesContainer.addSubview(container)
        self.container = container
        
        front.frame = container.bounds
        back.frame = container.bounds
        back.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0)
        back.isHidden = true
        front.isHidden = false
        front.tag = 999
        back.tag  = 999
        container.addSubview(back)
        container.addSubview(front)
        self.frontSnapshot = front
        self.backSnapshot  = back
    }

    func update(direction: PageTurnDirection, progress: CGFloat, type: AnimationType, messageForTesting: String = "") {
        guard let container = container else { return }
        guard (type == .manual && state == .manualFlipping) || (type == .auto && state == .autoFlipping) else {
            print(messageForTesting + "❌ Cannot update this animation [type: \(type), state: \(state)].")
            return
        }
        
        var t = CATransform3DIdentity
        t.m34 = -1.0 / 1500
        container.layer.transform = CATransform3DRotate(t, progress * .pi, 0, 1, 0)

        if let last = lastProgressForTesting {
            if format(last) != format(progress) {
                print(messageForTesting + "🔘 Update animation [state: \(state), type: \(type), progress \(format(progress))].")
                lastProgressForTesting = progress
            }
        } else {
            print(messageForTesting + "🔘 Update animation [state: \(state), type: \(type), progress \(format(progress))].")
            lastProgressForTesting = progress
        }

        frontSnapshot?.isHidden = abs(progress) >= 0.5
        backSnapshot?.isHidden = abs(progress) < 0.5
        host?.updateProgressOffset(direction: direction, progress: abs(progress))
    }

    func complete(direction: PageTurnDirection, progress: CGFloat, type: AnimationType, velocity: CGFloat) {
        guard (type == .manual && state == .manualFlipping) || (type == .auto && state == .autoFlipping) else {
            print("❌ Cannot complete this animation [type: \(type), state: \(state)].")
            return
        }
        self.host?.view.transform = .identity
        state = .autoFlipping
        
        let speedFactor = max(minSpeedFactor, min(abs(velocity) / baseVelocity, maxSpeedFactor))
        let duration = baseDuration / speedFactor

        let steps = 30
        let interval = duration / Double(steps)
        let target = progress >= 0 ? 1.0 : -1.0
        let delta = target - progress
        var predictedProgress: [CGFloat] = []

        for i in 1...steps {
            // Ease-out 曲线（模拟减速滑动）: p = 1 - (1 - t)^2
            let t = CGFloat(i) / CGFloat(steps)
            let easedT = easing.apply(t)
            let interpolated = progress + delta * easedT
            predictedProgress.append(interpolated)
        }

        var i = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if i >= predictedProgress.count {
                timer.invalidate()
                print("🔘 Complete animation [state: \(self.state)].")
                self.host?.goToPagePair(to: direction == .nextPage ? self.host!.currentIndex + 2 : self.host!.currentIndex - 2)
                self.cleanupViews()
                self.cleanupAnimations()
                return
            }
            let p = predictedProgress[i]

            let m = "🔘 Complete called update. "
            self.update(direction: direction, progress: p, type: .auto, messageForTesting: m)

            if abs(p) >= 0.5 {
                self.frontSnapshot?.isHidden = true
                self.backSnapshot?.isHidden = false
            }

            i += 1
        }
    }

    func cancel(direction: PageTurnDirection, progress: CGFloat, type: AnimationType, velocity: CGFloat) {
        guard let host = host else { return }
        guard (type == .manual && state == .manualFlipping) || (type == .auto && state == .autoFlipping) else {
            print("❌ Cannot cancel this animation [type: \(type), state: \(state)].")
            return
        }
        self.host?.view.transform = .identity

        if abs(progress) < 0.002 {
            print("🔘 Cancel animation [progress < 0.002].")
            host.goToPagePair(to: host.currentIndex)
            self.cleanupViews()
            self.cleanupAnimations()
            return
        }

        state = .autoFlipping
        let baseDuration: TimeInterval = 0.4
        let speedFactor = max(minSpeedFactor, min(abs(velocity) / baseVelocity, maxSpeedFactor))
        let duration = baseDuration / speedFactor

        let steps = 30
        let interval = duration / Double(steps)
        let delta = -progress
        var predictedProgress: [CGFloat] = []
        
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let easedT = easing.apply(t)
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
            self.update(direction: direction, progress: p, type: .auto)

            if abs(p) < 0.5 {
                self.frontSnapshot?.isHidden = false
                self.backSnapshot?.isHidden = true
            }

            i += 1
        }
    }

    func autoFlip(direction: PageTurnDirection) {
        begin(direction: direction, type: .auto)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.complete(direction: direction, progress: direction == .nextPage ? -0.1 : 0.1, type: .auto, velocity: self.baseVelocity)
        }
    }

    private func cleanupViews() {
        print("🧹 Cleanup views.")
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
        print("🧹 Cleanup animations [state was \(state)].")
        state = .idle

        if let next = pendingFlips.first {
            pendingFlips.removeFirst()
            print("⏰ Next flip [direction: \(next.direction), type: \(next.type)]")
            // 用 dispatch async 确保 goToPagePair 完全更新完毕后再开始动画
            DispatchQueue.main.async {
                switch next.type {
                case .manual:
                    self.begin(direction: next.direction, type: .auto)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.complete(direction: next.direction, progress: next.direction == .nextPage ? -0.1 : 0.1, type: .auto, velocity: self.baseVelocity)
                    }
                case .auto:
                    self.begin(direction: next.direction, type: .auto)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.complete(direction: next.direction, progress: next.direction == .nextPage ? -0.1 : 0.1, type: .auto, velocity: self.baseVelocity)
                    }
                }
            }
        }
    }
}
