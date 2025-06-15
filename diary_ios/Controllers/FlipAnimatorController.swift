import UIKit
class FlipAnimatorController {
    private weak var host: NotebookSpreadViewController?
    private var animator: UIViewPropertyAnimator?
    private var state: AnimationState = .idle
    
    private var container: UIView?
    private var frontSnapshot: UIView?
    private var backSnapshot: UIView?
    private var frontThicknessLayer: CALayer?
    private var backThicknessLayer: CALayer?
    private var lastProgressForTesting: CGFloat?
    
    private let baseVelocity = FlipConstants.baseVelocity
    private let baseDuration = FlipConstants.baseDuration
    private let progressThreshold = FlipConstants.progressThreshold
    private let velocityThreshold = FlipConstants.velocityThreshold
    private let minSpeedFactor = FlipConstants.minSpeedFactor
    private let maxSpeedFactor  = FlipConstants.maxSpeedFactor
    private let epsilon = FlipConstants.epsilon
    private let thicknessScaleSensitivity = FlipConstants.thicknessScaleSensitivity

    private var pendingFlips: [FlipRequest] = []
    private let easing: EasingFunction = .sineEaseOut
    var isAnimating: Bool { return state != .idle }

    init(host: NotebookSpreadViewController) {
        self.host = host
    }

    // MARK: - 动画开始、更新、结束
    func begin(direction: PageTurnDirection, type: AnimationType) {
        guard let host = host else { return }
        
        guard state == .idle else {
            print("⏰ Begin with type \(type) but state is \(state). Enqueue.")
            pendingFlips.append(.init(direction: direction, type: .auto))
            return
        }
        cleanupViews()
        
        let targetIndex = direction == .nextPage ? host.currentIndex + 2 : host.currentIndex - 2
        guard host.currentIndex >= 0, host.currentIndex <= host.pageCount - 2, 
                targetIndex >= 0, targetIndex <= host.pageCount - 2 else {
            print("❌ Page index invalid. Current index \(host.currentIndex). Target index \(targetIndex)")
            state = .idle
            return
        }
        host.fromYOffsets = host.computeYOffsets(pageIndex: host.currentIndex) ?? []
        host.toYOffsets = host.computeYOffsets(pageIndex: targetIndex) ?? []
        guard let currentLeftSnapshot = host.pages[host.currentIndex].view.snapshotView(afterScreenUpdates: true),
            let currentRightSnapshot = host.pages[host.currentIndex + 1].view.snapshotView(afterScreenUpdates: true),
            let targetLeftSnapshot = host.pages[targetIndex].view.snapshotView(afterScreenUpdates: true),
            let targetRightSnapshot = host.pages[targetIndex + 1].view.snapshotView(afterScreenUpdates: true) else {
            print("❌ Snapshot generation failed.")
            state = .idle
            return
        }

        // 隐藏即将旋转的 pageContainer view
        let offsetIndex = min(max(host.currentIndex / 2 - 1, 0), host.containerCount - 1)
        var offsetIndexToRemove: Int
        if direction == .nextPage {
            if host.currentIndex == 0 {
                offsetIndexToRemove = 0
            } else {
                offsetIndexToRemove = offsetIndex + 1
            }
        } else {
            if host.currentIndex == host.pageCount - 2 {
                offsetIndexToRemove = host.containerCount - 1
            } else {
                offsetIndexToRemove = offsetIndex
            }
        }
        host.pageContainers[offsetIndexToRemove].subviews.forEach { $0.removeFromSuperview() }
        print("🔘 Begin animation [state: \(state), type: \(type), remove pageContainer \(offsetIndexToRemove)].")

        // 创建临时 conatiner 用来翻转
        let container = UIView()
        let containerFrame = host.pageContainers[direction == .nextPage ? offsetIndex + 1 : offsetIndex].frame
        container.bounds = CGRect(origin: .zero, size: containerFrame.size)
        container.layer.anchorPoint = CGPoint(x: direction == .nextPage ? 0 : 1, y: 0.5)
        container.layer.position = CGPoint(x: direction == .nextPage ? containerFrame.origin.x : containerFrame.origin.x + containerFrame.width, 
                                            y: containerFrame.origin.y + containerFrame.midY)
        container.clipsToBounds = true
        container.layer.transform.m34 = -1.0 / 1500

        // 给 container 添加页面快照
        let frontSnapshot = direction == .nextPage ? currentRightSnapshot : currentLeftSnapshot
        let backSnapshot = direction == .nextPage ? targetLeftSnapshot : targetRightSnapshot
        frontSnapshot.frame = container.bounds
        backSnapshot.frame = container.bounds
        backSnapshot.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0)
        backSnapshot.isHidden = true
        frontSnapshot.isHidden = false

        // 给页面加上厚度
        let frontDepthView = makeDepthView(for: frontSnapshot, isLeftPage: direction == .lastPage)
        let backDepthView = makeDepthView(for: backSnapshot, isLeftPage: direction == .nextPage)
        frontSnapshot.addSubview(frontDepthView)
        backSnapshot.addSubview(backDepthView)

        // 按照视图顺序添加
        host.view.addSubview(container)
        container.addSubview(backSnapshot)
        container.addSubview(frontSnapshot)
        self.backSnapshot = backSnapshot
        self.frontSnapshot = frontSnapshot
        self.frontThicknessLayer = frontThickness
        self.backThicknessLayer = backThickness
        self.container = container

        state = (type == .manual) ? .manualFlipping : .autoFlipping
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

        // 控制页面厚度显示
        let thickness = max(sin(abs(progress) * .pi), epsilon)
        let thicknessScale = 1 + thicknessScaleSensitivity * thickness
        frontThicknessLayer?.transform = CATransform3DMakeScale(thicknessScale, 1, 1)
        backThicknessLayer?.transform = CATransform3DMakeScale(thicknessScale, 1, 1)

        // 输出信息
        var hostShouldPrint: Bool = false
        if let last = lastProgressForTesting {
            if format(last) != format(progress) {
                print(messageForTesting + "🔘 Update animation [state: \(state), type: \(type), progress \(format(progress))].")
                print("   📐 PageThickness scale: \(thicknessScale).")
                lastProgressForTesting = progress
                hostShouldPrint = true
            }
        } else {
            print(messageForTesting + "🔘 Update animation [state: \(state), type: \(type), progress \(format(progress))].")
            print("   📐 PageThickness scale: \(thicknessScale).")
            lastProgressForTesting = progress
            hostShouldPrint = true
        }

        frontSnapshot?.isHidden = abs(progress) >= progressThreshold
        backSnapshot?.isHidden = abs(progress) < progressThreshold
        host?.updateProgressOffset(direction: direction, progress: abs(progress))
        host?.updateStackTransforms(progress: abs(progress), shouldPrint: hostShouldPrint) 
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
                print("🔘 Complete animation [state was \(self.state)].")
                self.host?.goToPagePair(to: direction == .nextPage ? self.host!.currentIndex + 2 : self.host!.currentIndex - 2)
                self.cleanupViews()
                self.cleanupAnimations()
                return
            }
            let p = predictedProgress[i]

            let m = "🔘 Complete called update. "
            self.update(direction: direction, progress: p, type: .auto, messageForTesting: m)

            if abs(p) >= self.progressThreshold {
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

            if abs(p) < self.progressThreshold {
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

    // MARK: - 辅助函数
    private func makeDepthView(for snapshot: UIView, isLeftPage: Bool) -> UIView {
        let depthWidth: CGFloat = 2
        let depthView = UIView()
        depthView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        let height = snapshot.bounds.height
        let x = isLeftPage ? -depthWidth : snapshot.bounds.width
        depthView.frame = CGRect(x: x, y: 0, width: depthWidth, height: height)
        
        // 关键：设置 anchorPoint 和 position 使其在旋转时不变形
        depthView.layer.anchorPoint = CGPoint(x: isLeftPage ? 1 : 0, y: 0.5)
        depthView.layer.position = CGPoint(x: isLeftPage ? 0 : snapshot.bounds.width, y: height / 2)
        
        // 防止 90 度时被裁掉
        depthView.layer.isDoubleSided = true
        return depthView
    }

    // MARK: - 清理
    private func cleanupViews() {
        print("🧹 Cleanup views.")
        animator?.stopAnimation(true)
        animator = nil
        
        container?.removeFromSuperview()
        frontSnapshot?.removeFromSuperview()
        backSnapshot?.removeFromSuperview()
        frontSnapshot = nil
        backSnapshot = nil

        frontThicknessLayer?.removeFromSuperlayer()
        backThicknessLayer?.removeFromSuperlayer()
        frontThicknessLayer = nil
        backThicknessLayer = nil

        container = nil
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
