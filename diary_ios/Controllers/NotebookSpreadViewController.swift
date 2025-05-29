import UIKit

protocol NotebookSpreadViewControllerDelegate: AnyObject {
    func notebookSpreadViewController(_ controller: NotebookSpreadViewController, didUpdatePageRole role: PageRole)
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIViewController {
    private var pages: [NotebookPageViewController] = []
    private var currentIndex: Int = 0
    private var isAnimating = false

    private var leftPageContainer = UIView()
    private var rightPageContainer = UIView()

    weak var pageDelegate: NotebookSpreadViewControllerDelegate?

    private var flipContainer: UIView?
    private var frontSnapshot: UIView?
    private var backSnapshot: UIView?

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
        let progress = min(max(translation.x * 2 / view.bounds.width, -1), 1)

        switch gesture.state {
        case .changed:
            if flipContainer == nil {
                beginPageFlip(direction: translation.x < 0 ? .nextPage : .lastPage)
            }
            updatePageFlip(direction: translation.x < 0 ? .nextPage : .lastPage, progress: progress)
        case .ended, .cancelled:
            completePageFlip(direction: translation.x < 0 ? .nextPage : .lastPage, progress: progress)
        default:
            break
        }
    }

    private func beginPageFlip(direction: PageTurnDirection) {
        guard !isAnimating else { return }

        let newIndex = direction == .nextPage ? currentIndex + 2 : currentIndex - 2
        guard newIndex >= 0, newIndex + 1 < pages.count else {
            print("❌ Invalid target index: \(newIndex)")
            return
        }

        isAnimating = true
        flipContainer?.removeFromSuperview()
        print("📌 Pan began. Flipping to page pair \(newIndex), \(newIndex + 1)")

        // 获取翻页前后的页面
        let flippingPage: NotebookPageViewController = (direction == .nextPage) ? pages[currentIndex + 1] : pages[currentIndex]
        let nextPage: NotebookPageViewController = (direction == .nextPage) ? pages[newIndex] : pages[newIndex + 1]

        let container = UIView(frame: CGRect(x: direction == .nextPage ? view.bounds.width / 2 : 0, y: 0, width: view.bounds.width / 2, height: view.bounds.height))
        container.layer.anchorPoint = CGPoint(x: direction == .nextPage ? 0 : 1, y: 0.5)
        container.layer.position = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        container.clipsToBounds = true

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 1500
        container.layer.transform = transform

        view.addSubview(container)
        self.flipContainer = container

        // 生成翻页视图截图
        guard let front = flippingPage.view.snapshotView(afterScreenUpdates: true),
            let back = nextPage.view.snapshotView(afterScreenUpdates: true) else { return }

        back.frame = container.bounds
        back.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0)
        front.frame = container.bounds

        container.addSubview(back)
        container.addSubview(front)

        self.backSnapshot = back
        self.frontSnapshot = front
        back.isHidden = true
        front.isHidden = false
    }

    private func updatePageFlip(direction: PageTurnDirection, progress: CGFloat) {
        guard let flipContainer = flipContainer else {
            print("⚠️ flipContainer is nil")
            return
        }

        // 提前显示未来的左右页
        if direction == .nextPage {
            let preloadRight = pages[currentIndex + 3]
            preloadRight.view.frame = rightPageContainer.bounds
            rightPageContainer.subviews.forEach { $0.removeFromSuperview() }
            rightPageContainer.addSubview(preloadRight.view)
        } else {
            let preloadLeft = pages[currentIndex - 2]
            preloadLeft.view.frame = leftPageContainer.bounds
            leftPageContainer.subviews.forEach { $0.removeFromSuperview() }
            leftPageContainer.addSubview(preloadLeft.view)
        }

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 1500
        let angle = progress * .pi
        flipContainer.layer.transform = CATransform3DRotate(transform, angle, 0, 1, 0)
        // print(String(format: "📌 Pan changed. 📐 Rotating progress: %.1f, angle: %.1f.", progress, angle))
        
        if abs(progress) > 0.5 {
            frontSnapshot?.isHidden = true
            backSnapshot?.isHidden = false
            // print("▪️ Show backSnapshot, hide frontSnapshot.")
        } else {
            frontSnapshot?.isHidden = false
            backSnapshot?.isHidden = true
            // print("🔸 Show frontSnapshot, hide backSnapshot.")
        }
    }

    private func completePageFlip(direction: PageTurnDirection, progress: CGFloat) {
        guard let flipContainer = flipContainer else {
            print("⚠️ flipContainer is nil on complete")
            return
        }

        let shouldFlip = abs(progress) > 0.5
        let targetIndex = direction == .nextPage ? currentIndex + 2 : currentIndex - 2

        UIView.animate(withDuration: 0.3, animations: {
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 1000
            let angle: CGFloat = shouldFlip ? .pi : 0
            flipContainer.layer.transform = CATransform3DRotate(transform, angle, 0, 1, 0)
        }, completion: { _ in
            print("📌 Pan completed.", terminator:" ")
            if shouldFlip {
                self.goToPagePair(to: targetIndex)
            } else {
                self.goToPagePair(to: self.currentIndex)
            }
            self.flipContainer?.removeFromSuperview()
            self.flipContainer = nil
            self.isAnimating = false
        })
    }

    // MARK: - Page Navigation
    func addNewPagePair(initialData: Data? = nil) {
        // 不允许在最后一页之后添加页面
        guard currentIndex + 2 < pages.count else {
            print("❌ Cannot add new page pair at the end.")
            return
        }

        let insertIndex = currentIndex + 2
        let leftPage = NotebookPageViewController(pageIndex: insertIndex, initialData: initialData)
        let rightPage = NotebookPageViewController(pageIndex: insertIndex + 1, initialData: initialData)
        pages.insert(contentsOf: [leftPage, rightPage], at: insertIndex)
        let label = UILabel()
        label.text = "这是一个测试文本"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18)
        label.sizeToFit()
        label.center = CGPoint(x: leftPage.view.bounds.midX, y: leftPage.view.bounds.midY)

        leftPage.view.addSubview(label)

        print("📄 Insert page pair at \(insertIndex).")
        animatePageFlip(to: .nextPage)
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
        notifyPageState(index)
    }

    func animatePageFlip(to direction: PageTurnDirection) {
        guard !isAnimating else { return }

        beginPageFlip(direction: direction)

        // 模拟从 0 到 1 的翻页过程
        let animationDuration: TimeInterval = 0.6
        let frameRate: TimeInterval = 1.0 / 60.0
        let totalFrames = Int(animationDuration / frameRate)
        var currentFrame = 0

        Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { timer in
            currentFrame += 1
            let progress = -CGFloat(currentFrame) / CGFloat(totalFrames)

            // 从 0 到 ±1，决定方向
            let flippedProgress = direction == .nextPage ? progress : -progress
            self.updatePageFlip(direction: direction, progress: flippedProgress)

            if currentFrame >= totalFrames {
                timer.invalidate()
                self.completePageFlip(direction: .nextPage, progress: flippedProgress)
            }
        }
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

    private func notifyPageState(_ index: Int) {
        let role: PageRole
        if index == 0 {
            role = .cover
        } else if index == pages.count - 2 {
            role = .back
        } else {
            role = .normal
        }
        print("📢 Page role updated: \(role)")
        pageDelegate?.notebookSpreadViewController(self, didUpdatePageRole: role)
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
