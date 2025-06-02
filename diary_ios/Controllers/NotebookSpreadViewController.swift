import UIKit

protocol NotebookSpreadViewControllerDelegate: AnyObject {
    func currentContentWidth() -> CGFloat
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIViewController {
    private var pages: [NotebookPageViewController] = []
    private var currentIndex: Int = 0
    private var flipState: FlipState = .idle
    private var lastProgress: CGFloat?

    private var leftPageContainer = UIView()
    private var rightPageContainer = UIView()

    weak var pageDelegate: NotebookSpreadViewControllerDelegate?
    var onProgressChanged: ((CGFloat) -> Void)?

    private var flipContainer: UIView?
    private var frontSnapshot: UIView?
    private var backSnapshot: UIView?
    private var flipAnimator: UIViewPropertyAnimator?

    private enum FlipState {
        case idle
        case flippingToNext
        case flippingToLast

        var direction: PageTurnDirection? {
            switch self {
            case .flippingToNext: return .nextPage
            case .flippingToLast: return .lastPage
            case .idle: return nil
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageContainers()
        setupInitialPages()
        setupGestureRecognizers()
    }

    // MARK: - Setup
    private func setupPageContainers() {
        leftPageContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
        rightPageContainer.frame = CGRect(x: view.bounds.width / 2, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
        view.addSubview(leftPageContainer)
        view.addSubview(rightPageContainer)
    }

    private func setupInitialPages() {
        pages = [
            NotebookPageViewController(pageIndex: 0, role: .empty),
            NotebookPageViewController(pageIndex: 1, role: .cover),
            NotebookPageViewController(pageIndex: 2, role: .normal),
            NotebookPageViewController(pageIndex: 3, role: .normal),
            NotebookPageViewController(pageIndex: 4, role: .back),
            NotebookPageViewController(pageIndex: 5, role: .empty)
        ]
        goToPagePair(to: 0)
    }

    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }

    // MARK: - Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let progress = min(max(translation.x * 2 / view.bounds.width, -1), 1)
        let direction: PageTurnDirection = translation.x < 0 ? .nextPage : .lastPage

        switch gesture.state {
        case .changed:
            // 不允许 progress 正负号变化
            if let l = lastProgress, (l > 0 && progress < 0) || (l < 0 && progress > 0) { 
                print("❌ Progress sign changed. Cancel Flip.")
                cancelFlipAnimation(direction: l > 0 ? .nextPage : .lastPage, progress: 0)
                return 
            }
            lastProgress = progress

            if flipState == .idle {
                print("🚩 Begin page flip - \(direction)")
                beginPageFlip(direction: direction)
                flipState = direction == .nextPage ? .flippingToNext : .flippingToLast
            }
            print("🚩 Update page flip - progress \(format(progress))")
            updatePageFlip(direction: direction, progress: progress)
        case .ended, .cancelled:
            lastProgress = nil
            if abs(velocity.x) > 800 || abs(progress) > 0.5 {
                print("🚩 Complete page flip - progress \(format(progress))")
                completeFlipAnimation(direction: direction, progress: progress)
            } else {
                print("🚩 Cancel page flip - progress \(format(progress))")
                cancelFlipAnimation(direction: direction, progress: progress)
            }
        default:
            break
        }
    }

    // MARK: - Page Flip Animation
    private func beginPageFlip(direction: PageTurnDirection) {
        let newIndex = direction == .nextPage ? currentIndex + 2 : currentIndex - 2
        guard newIndex >= 0, newIndex + 1 < pages.count else {
            print("❌ Invalid target index: \(newIndex)")
            return
        }

        // 强制清理旧状态
        flipAnimator?.stopAnimation(true)
        flipAnimator = nil
        flipContainer?.removeFromSuperview()
        flipContainer = nil
        flipState = direction == .nextPage ? .flippingToNext : .flippingToLast
        // print("📌 Pan began. Flipping to page pair \(newIndex), \(newIndex + 1)")

        // 获取翻页前后的页面
        let flippingPage = (direction == .nextPage) ? pages[currentIndex + 1] : pages[currentIndex]
        let nextPage = (direction == .nextPage) ? pages[newIndex] : pages[newIndex + 1]

        let container = UIView(frame: CGRect(x: direction == .nextPage ? view.bounds.width / 2 : 0, y: 0, width: view.bounds.width / 2, height: view.bounds.height))
        container.layer.anchorPoint = CGPoint(x: direction == .nextPage ? 0 : 1, y: 0.5)
        container.layer.position = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        container.clipsToBounds = true
        container.layer.transform.m34 = -1.0 / 1500

        view.addSubview(container)
        self.flipContainer = container

        // 生成翻页视图截图
        guard let front = flippingPage.view.snapshotView(afterScreenUpdates: true),
            let back = nextPage.view.snapshotView(afterScreenUpdates: true) else { return }

        front.frame = container.bounds
        back.frame = container.bounds
        back.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0)
        container.addSubview(back)
        container.addSubview(front)

        backSnapshot = back
        frontSnapshot = front
        back.isHidden = true
        front.isHidden = false
    }

    private func updatePageFlip(direction: PageTurnDirection, progress: CGFloat) {
        guard let flipContainer = flipContainer else {
            print("⚠️ flipContainer is nil")
            return
        }

        // 预加载左右页
        if direction == .nextPage {
            if currentIndex + 3 < pages.count {
                let preloadRight = pages[currentIndex + 3]
                preloadRight.view.frame = rightPageContainer.bounds
                rightPageContainer.subviews.forEach { $0.removeFromSuperview() }
                rightPageContainer.addSubview(preloadRight.view)
            }
        } else {
            if currentIndex - 2 >= 0 {
                let preloadLeft = pages[currentIndex - 2]
                preloadLeft.view.frame = leftPageContainer.bounds
                leftPageContainer.subviews.forEach { $0.removeFromSuperview() }
                leftPageContainer.addSubview(preloadLeft.view)
            }
        }

        var t = CATransform3DIdentity
        t.m34 = -1.0 / 1500
        let angle = progress * .pi
        flipContainer.layer.transform = CATransform3DRotate(t, angle, 0, 1, 0)
        // print(String(format: "📌 Pan changed. 📐 Rotating progress: %.1f, angle: %.1f.", progress, angle))
        
        if abs(progress) < 0.5 {
            frontSnapshot?.isHidden = false
            backSnapshot?.isHidden = true
            // print("🔸 Show frontSnapshot, hide backSnapshot.")
        } else {
            frontSnapshot?.isHidden = true
            backSnapshot?.isHidden = false
            // print("▪️ Show backSnapshot, hide frontSnapshot.")
        }

        updateProgressOffset(direction: direction, progress: abs(progress))
    }

    private func updateProgressOffset(direction: PageTurnDirection, progress: CGFloat) {
        print(String(format: "🔥 Page flip progress: %.1f", progress), terminator: ", ")
        let width = pageDelegate?.currentContentWidth() ?? 0 
        var offset: CGFloat = 0
        let easedProgress = easeInOutCubic(progress)

        if currentIndex == 2 && direction == .lastPage {
            offset = -width / 4 * easedProgress
        } else if currentIndex + 4 == pages.count && direction == .nextPage {
            offset = width / 4 * easedProgress
        } else if currentIndex == 0 && direction == .nextPage {
            offset = -width / 4 * (1 - easedProgress)
        } else if currentIndex == pages.count - 2 && direction == .lastPage {
            offset = width / 4 * (1 - easedProgress)
        }
        onProgressChanged?(offset)
    }

    // MARK: - Animation Completion
    private func completeFlipAnimation(direction: PageTurnDirection,
                                    progress: CGFloat) {
        guard let flipContainer = flipContainer else { return }

        let remainingProgress = 1 - abs(progress)
        let targetIndex = direction == .nextPage ? currentIndex + 2 : currentIndex - 2

        // 停止上一个动画
        flipAnimator?.stopAnimation(true)

        // 创建动画器
        flipAnimator = UIViewPropertyAnimator(duration: 0.3 + remainingProgress * 0.2, curve: .easeOut) {
            var t = CATransform3DIdentity
            t.m34 = -1.0 / 1000
            flipContainer.layer.transform = CATransform3DRotate(t, .pi, 0, 1, 0)
            self.frontSnapshot?.isHidden = true
            self.backSnapshot?.isHidden = false
            self.updateProgressOffset(direction: direction, progress: 1.0)
        }

        flipAnimator?.addCompletion { _ in
            self.goToPagePair(to: targetIndex)
            self.flipContainer?.removeFromSuperview()
            self.flipContainer = nil
            self.flipAnimator = nil
            self.flipState = .idle
        }

        flipAnimator?.startAnimation()
    }

    private func cancelFlipAnimation(direction: PageTurnDirection,
                                    progress: CGFloat) {
        guard let flipContainer = flipContainer else { return }
        flipAnimator?.stopAnimation(true)

        flipAnimator = UIViewPropertyAnimator(duration: 0.2 + 0.2 * abs(progress), curve: .easeOut) {
            var t = CATransform3DIdentity
            t.m34 = -1.0 / 1500
            flipContainer.layer.transform = CATransform3DRotate(t, 0, 0, 1, 0)
            self.updateProgressOffset(direction: direction, progress: 0.0)
            self.frontSnapshot?.isHidden = false
            self.backSnapshot?.isHidden = true
        }

        flipAnimator?.addCompletion { _ in
            self.goToPagePair(to: self.currentIndex)
            self.flipContainer?.removeFromSuperview()
            self.flipContainer = nil
            self.flipAnimator = nil
            self.flipState = .idle
        }

        flipAnimator?.startAnimation()
    }

    // MARK: - Page Navigation
    func addNewPagePair(initialData: Data? = nil) {
        guard currentIndex + 2 < pages.count else {
            print("❌ Cannot add new page pair at the end.")
            return
        }

        let insertIndex = currentIndex + 2
        let leftPage = NotebookPageViewController(pageIndex: insertIndex, initialData: initialData)
        let rightPage = NotebookPageViewController(pageIndex: insertIndex + 1, initialData: initialData)
        pages.insert(contentsOf: [leftPage, rightPage], at: insertIndex)
        print("📄 Insert page pair at \(insertIndex).")
        autoPageFlip(to: .nextPage)
    }

    private func goToPagePair(to index: Int) {
        guard index >= 0 && index < pages.count - 1 else {
            print("❌ Index out of bounds: \(index)")
            return
        }
        print("▶️ Go to page pair \(index), \(index + 1)")

        let leftPage = pages[index]
        let rightPage = pages[index + 1]

        leftPageContainer.subviews.forEach { $0.removeFromSuperview() }
        rightPageContainer.subviews.forEach { $0.removeFromSuperview() }

        leftPage.view.frame = leftPageContainer.bounds
        rightPage.view.frame = rightPageContainer.bounds

        leftPageContainer.addSubview(leftPage.view)
        rightPageContainer.addSubview(rightPage.view)

        currentIndex = index
        applyPageShadows()
    }

    func autoPageFlip(to direction: PageTurnDirection = .nextPage) {
        beginPageFlip(direction: direction)
        flipAnimator?.stopAnimation(true)

        // 提前显示未来的左右页
        if direction == .nextPage {
            if currentIndex + 3 < pages.count {
                let preloadRight = pages[currentIndex + 3]
                preloadRight.view.frame = rightPageContainer.bounds
                rightPageContainer.subviews.forEach { $0.removeFromSuperview() }
                rightPageContainer.addSubview(preloadRight.view)
            }
        } else {
            if currentIndex - 2 >= 0 {
                let preloadLeft = pages[currentIndex - 2]
                preloadLeft.view.frame = leftPageContainer.bounds
                leftPageContainer.subviews.forEach { $0.removeFromSuperview() }
                leftPageContainer.addSubview(preloadLeft.view)
            }
        }
        self.backSnapshot?.isHidden = false
        self.frontSnapshot?.isHidden = true

        flipAnimator = UIViewPropertyAnimator(duration: 0.6, curve: .easeInOut) {
            var t = CATransform3DIdentity
            t.m34 = -1.0 / 1500
            self.flipContainer?.layer.transform = CATransform3DRotate(t, .pi, 0, 1, 0)
            self.frontSnapshot?.isHidden = true
            self.backSnapshot?.isHidden = false
            self.updateProgressOffset(direction: direction, progress: 1.0)
        }

        flipAnimator?.addCompletion { _ in
            self.goToPagePair(to: self.currentIndex + 2)
            self.flipContainer?.removeFromSuperview()
            self.flipContainer = nil
            self.flipAnimator = nil
            self.flipState = .idle
        }

        flipAnimator?.startAnimation()
    }
    
    // MARK: - Appearance
    private func applyPageShadows() {
        pages.enumerated().forEach { index, page in
            page.view.layer.shadowColor = UIColor.black.cgColor
            page.view.layer.shadowOpacity = 0.3
            page.view.layer.shadowRadius = 5
            page.view.layer.shadowOffset = CGSize(width: 0, height: 1)

            if index == currentIndex {
                page.view.layer.shadowPath = UIBezierPath(rect: CGRect(
                    x: page.view.bounds.width - 10,
                    y: 0,
                    width: 10,
                    height: page.view.bounds.height
                )).cgPath
            } else if index == currentIndex + 1 {
                page.view.layer.shadowPath = UIBezierPath(rect: CGRect(
                    x: 0,
                    y: 0,
                    width: 10,
                    height: page.view.bounds.height
                )).cgPath
            } else {
                page.view.layer.shadowPath = nil
            }
        }
    }

    func exportAllDrawings() -> [Data] {
        return pages.map { $0.exportDrawing() }
    }

    func undo() {
        print("↩️ Undo at index: \(currentIndex)")
        if currentIndex < pages.count {
            pages[currentIndex].undo()
        }
        if currentIndex + 1 < pages.count {
            pages[currentIndex + 1].undo()
        }
    }

    func redo() {
        print("↪️ Redo at index: \(currentIndex)")
        if currentIndex < pages.count {
            pages[currentIndex].redo()
        }
        if currentIndex + 1 < pages.count {
            pages[currentIndex + 1].redo()
        }
    }
}
