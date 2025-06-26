import UIKit
class FlipAnimatorController {
    private weak var host: NotebookSpreadViewController?
    private var animator: UIViewPropertyAnimator?
    private var state: AnimationState = .idle
    
    // MARK: - 翻页相关属性
    private var flipContainer: UIView?
    private var containerPositionX: CGFloat = 0
    private var containerOffset: CGFloat = 0
    private var frontSnapshot: UIView?
    private var backSnapshot: UIView?
    private var frontOverlay: UIView?
    private var backOverlay: UIView?
    private var pageShadow: UIView?
    private var lastProgressForTesting: CGFloat?
    
    private let defaultCornerRadius = PageConstants.pageCornerRadius
    private let pageShadowRadius = PageConstants.shadowRadius
    private let leftMaskedCorners = PageConstants.leftMaskedCorners
    private let rightMaskedCorners = PageConstants.rightMaskedCorners
    private let pageShadowOpacity = PageConstants.shadowOpacity

    private let baseVelocity = FlipConstants.baseVelocity
    private let baseDuration = FlipConstants.baseDuration
    private let progressThreshold = FlipConstants.progressThreshold
    private let minSpeedFactor = FlipConstants.minSpeedFactor
    private let maxSpeedFactor = FlipConstants.maxSpeedFactor

    private let lightAngle = FlipConstants.lightAngle
    private let transformm34 = FlipConstants.transformm34
    private let baseOffset = StackConstants.baseOffset
    private let largerOverlayAlpha = FlipConstants.largerOverlayAlpha
    private let smallerOverlayAlpha = FlipConstants.smallerOverlayAlpha
    private let shadowOffset = FlipConstants.shadowOffset
    private let shadowOpacity = FlipConstants.shadowOpacity
    private let shadowRadius = FlipConstants.shadowRadius
    private let shadowInset = FlipConstants.shadowInset

    private var pendingFlips: [FlipRequest] = []
    var isAnimating: Bool { return state != .idle }

    init(host: NotebookSpreadViewController) {
        self.host = host
    }

    // MARK: - 动画开始
    func begin(direction: PageTurnDirection, type: AnimationType) {
        guard let host = host else { return }
        guard state == .idle else {
            print("⏰ Begin with type \(type) but state is \(state). Enqueue.")
            pendingFlips.append(.init(direction: direction, type: .auto))
            return
        }
        cleanupViews()
        
        let targetIndex = direction == .nextPage ? host.currentIndex + 2 : host.currentIndex - 2
        guard host.currentIndex >= 0, host.currentIndex <= host.pageCount - 2, targetIndex >= 0, targetIndex <= host.pageCount - 2 else {
            print("❌ Page index invalid. Current index \(host.currentIndex). Target index \(targetIndex)")
            state = .idle
            return
        }
        host.fromYOffsets = host.computeYOffsets(pageIndex: host.currentIndex)
        host.toYOffsets = host.computeYOffsets(pageIndex: targetIndex)
        host.fromXOffsets = host.computeXOffsets(pageIndex: host.currentIndex)
        host.toXOffsets = host.computeXOffsets(pageIndex: targetIndex)
        containerOffset = computeContainerOffset(direction: direction, targetIndex: targetIndex)

        // 生成前后快照
        print("📸 Create snapshots.")
        let currentLeftView = host.pages[host.currentIndex]
        let currentRightView = host.pages[host.currentIndex + 1]
        let targetLeftView = host.pages[targetIndex]
        let targetRightView = host.pages[targetIndex + 1]
        guard let frontSnapshot = direction == .nextPage ? currentRightView.snapshotView(afterScreenUpdates: true) : currentLeftView.snapshotView(afterScreenUpdates: true),
            let backSnapshot = direction == .nextPage ? targetLeftView.snapshotView(afterScreenUpdates: true) : targetRightView.snapshotView(afterScreenUpdates: true) else {
            print("❌ Snapshot generation failed.")
            state = .idle
            return
        }
        self.frontSnapshot = frontSnapshot
        self.backSnapshot = backSnapshot

        // 隐藏即将被旋转的 pageContainer, 这一步必须在snapshot后面
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
        guard let flipContainer = createFlipContainer(for: direction, offsetIndex: offsetIndex, frontSnapshot: frontSnapshot, backSnapshot: backSnapshot) else {
            print("❌ FlipContainer setup failed.")
            state = .idle
            return
        }
        host.view.addSubview(flipContainer)
        setupPageShadow(for: direction == .nextPage ? targetRightView : currentRightView, direction: direction)

        self.flipContainer = flipContainer
        state = (type == .manual) ? .manualFlipping : .autoFlipping
    }

    // MARK: - 动画更新
    func update(direction: PageTurnDirection, progress: CGFloat, type: AnimationType, messageForTesting: String = "") {
        guard let flipContainer = flipContainer else { return }
        guard (type == .manual && state == .manualFlipping) || (type == .auto && state == .autoFlipping) else {
            print(messageForTesting + "❌ Cannot update this animation [type: \(type), state: \(state)].")
            return
        }
        
        var t = CATransform3DIdentity
        t.m34 = transformm34
        flipContainer.layer.transform = CATransform3DRotate(t, progress * .pi, 0, 1, 0)
        flipContainer.layer.position.x = containerPositionX + progress * containerOffset

        // 更新快照的投影
        guard let shadow = self.pageShadow else {
            print("❌ Page shadow not found.")
            state = .idle
            return
        }
        let shadowProgress = direction == .nextPage ? abs(progress) : 1 - abs(progress)
        let shadowWidth = computeShadowWidth(shadowProgress: shadowProgress, lightAngle: lightAngle, containerWidth: flipContainer.bounds.width)
        shadow.frame = CGRect(x: 0, y: 0, width: shadowWidth, height: shadow.bounds.height)
        updatePageShadow(for: shadow)

        // 更新快照的阴影层和可见性
        frontOverlay?.alpha = computeOverlayAlpha(alphaProgress: abs(progress), overlayAlpha: direction == .nextPage ? smallerOverlayAlpha : largerOverlayAlpha)
        backOverlay?.alpha = computeOverlayAlpha(alphaProgress: 1 - abs(progress), overlayAlpha: direction == .nextPage ? largerOverlayAlpha : smallerOverlayAlpha)
        frontSnapshot?.isHidden = abs(progress) >= progressThreshold
        backSnapshot?.isHidden = abs(progress) < progressThreshold
        host?.updateProgressOffset(direction: direction, progress: abs(progress))

        // 打印调试信息
        var hostShouldPrint: Bool = false
        if let last = lastProgressForTesting {
            if format(last) != format(progress) {
                print(messageForTesting + "🔘 Update animation [state: \(state), type: \(type), progress \(format(progress))].")
                // print("   💡 ShadowWidth: \(format(shadowWidth/flipContainer.bounds.width)), OverlayAlpha: [\(format(frontOverlay!.alpha)), \(format(backOverlay!.alpha))].")
                lastProgressForTesting = progress
                hostShouldPrint = true
            }
        } else {
            print(messageForTesting + "🔘 Update animation [state: \(state), type: \(type), progress \(format(progress))].")
            // print("   💡 ShadowWidth: \(format(shadowWidth/flipContainer.bounds.width)), OverlayAlpha: [\(format(frontOverlay!.alpha)), \(format(backOverlay!.alpha))].")
            lastProgressForTesting = progress
            hostShouldPrint = true
        }
        host?.updateStackTransforms(progress: abs(progress))
    }

    // MARK: - 动画完成、取消
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
            let easedT = sineEaseOut(t)
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
            let easedT = sineEaseOut(t)
            let interpolated = progress + delta * easedT
            predictedProgress.append(interpolated)
        }

        var i = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if i >= predictedProgress.count {
                timer.invalidate()
                host.goToPagePair(to: host.currentIndex)
                print("🔘 Cancel animation.")
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

    // MARK: - 创建翻页容器
    private func createFlipContainer(for direction: PageTurnDirection, offsetIndex: Int, frontSnapshot: UIView, backSnapshot: UIView) -> UIView? {
        guard let host = host else { return nil }
        let containerSize = CGSize(width: host.view.bounds.width / 2, height: host.view.bounds.height)
        
        // 内层容器：负责内容和圆角裁剪
        let container = UIView(frame: CGRect(origin: .zero, size: containerSize))
        container.layer.cornerRadius = defaultCornerRadius
        container.layer.maskedCorners = direction == .nextPage ? rightMaskedCorners : leftMaskedCorners
        container.layer.masksToBounds = true
        configureSnapshot(for: container, snapshot: frontSnapshot, isFront: true)
        configureSnapshot(for: container, snapshot: backSnapshot, isFront: false)
        container.addSubview(frontSnapshot)
        container.addSubview(backSnapshot)

        // 外层容器：负责阴影和变换
        let containerShadow = UIView(frame: CGRect(origin: .zero, size: containerSize))
        let originX = computeContainerOriginX(direction: direction, offsetIndex: offsetIndex, containerSize: containerSize)
        containerShadow.layer.anchorPoint = CGPoint(x: direction == .nextPage ? 0 : 1, y: 0.5)
        containerShadow.layer.position = CGPoint(x: direction == .nextPage ? originX : originX + containerSize.width, y: containerSize.height / 2)
        containerShadow.layer.transform.m34 = transformm34
        containerPositionX = containerShadow.layer.position.x
        print("   📐 FlipContainer originX: \(format(containerShadow.frame.origin.x)), future offset: \(format(containerOffset)).")

        containerShadow.layer.masksToBounds = false
        containerShadow.layer.shadowOffset = CGSize(width: 0, height: 0)
        containerShadow.layer.shadowColor = UIColor.black.cgColor
        containerShadow.layer.shadowOpacity = pageShadowOpacity
        containerShadow.layer.shadowRadius = pageShadowRadius

        containerShadow.addSubview(container)
        return containerShadow
    }

    // MARK: - 配置快照属性
    private func configureSnapshot(for container: UIView, snapshot: UIView, isFront: Bool){
        snapshot.frame = container.bounds
        snapshot.isHidden = isFront ? false : true
        snapshot.layer.transform = isFront ? CATransform3DIdentity : CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0)
        snapshot.layer.masksToBounds = true

        // 快照的阴影和圆角
        let overlay = UIView(frame: snapshot.bounds)
        overlay.isUserInteractionEnabled = false
        overlay.backgroundColor = UIColor.black
        overlay.alpha = 0

        snapshot.addSubview(overlay)
        if isFront { self.frontOverlay = overlay }
        else { self.backOverlay = overlay }
    }

    // MARK: - 计算容器位置和偏移
    private func computeContainerOriginX(direction: PageTurnDirection, offsetIndex: Int, containerSize: CGSize) -> CGFloat {
        guard let host = host else { return 0 }
        var originX: CGFloat = 0
        
        if host.currentIndex == 0 {
            originX = containerSize.width
        } else {
            originX = direction == .nextPage ? computeXDecay(1) + containerSize.width : 0
        } 
        return originX
    }

    private func computeContainerOffset(direction: PageTurnDirection, targetIndex: Int) -> CGFloat {
        guard let host = host else { return 0 }
        var containerOffset: CGFloat = 0

        if host.currentIndex == 0 || targetIndex == 0 {
            containerOffset = 0
        } else {
            containerOffset = computeXDecay(1)
        }
        return containerOffset
    }

    // MARK: - 翻页时快照的投影
    private func setupPageShadow(for targetView: UIView, direction: PageTurnDirection) {
        let shadow = UIView(frame: targetView.bounds)
        shadow.isUserInteractionEnabled = false
        shadow.backgroundColor = .clear
        shadow.layer.cornerRadius = defaultCornerRadius
        shadow.layer.masksToBounds = false
        shadow.layer.shadowColor = UIColor.black.cgColor
        shadow.layer.shadowOffset = CGSize(width: shadowOffset, height: shadowOffset)

        targetView.addSubview(shadow)
        self.pageShadow = shadow
    }

    private func updatePageShadow(for shadow: UIView) {
        shadow.layer.shadowOpacity = shadowOpacity
        shadow.layer.shadowRadius = shadowRadius
        guard let insetRect = insetRectSafe(from: shadow.bounds, inset: shadowInset) else {
            print("❌ Invalid shadow bounds.")
            return
        }
        let path = UIBezierPath(roundedRect: insetRect, cornerRadius: defaultCornerRadius)
        shadow.layer.shadowPath = path.cgPath
    }

    // MARK: - 清理函数
    private func cleanupViews() {
        print("   🧹 Cleanup views.")
        animator?.stopAnimation(true)
        animator = nil
        flipContainer?.removeFromSuperview()
        frontSnapshot?.removeFromSuperview()
        backSnapshot?.removeFromSuperview()
        flipContainer = nil
        frontSnapshot = nil
        backSnapshot = nil
        frontOverlay = nil
        backOverlay = nil
        pageShadow?.removeFromSuperview()
        pageShadow = nil
        lastProgressForTesting = nil
    }

    func cleanupAnimations() {
        print("   🧹 Cleanup animations [state was \(state)].")
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
