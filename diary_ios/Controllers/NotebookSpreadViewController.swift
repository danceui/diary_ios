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
    private var panStartIndex: Int = 0
    private var panDirection: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageContainers()
        setupInitialPages()
        setupGestureRecognizers()
    }

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
            NotebookPageViewController(pageIndex: 4, role: .normal),
            NotebookPageViewController(pageIndex: 5, role: .normal),
            NotebookPageViewController(pageIndex: 6, role: .back),
            NotebookPageViewController(pageIndex: 7, role: .empty)
        ]
        goToPagePair(at: 4)
    }

    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let percent = translation.x / view.bounds.width
        let limitedProgress = min(max(percent, -1), 1)

        switch gesture.state {
        case .began:
            panStartIndex = currentIndex
            panDirection = translation.x < 0 ? -1 : 1 // 左滑是负方向，右滑是正方向
            beginInteractivePageFlip(direction: panDirection)
        case .changed:
            updateInteractivePageFlip(progress: limitedProgress)
        case .ended, .cancelled:
            completeInteractivePageFlip(progress: limitedProgress)
        default:
            break
        }
    }

    private func beginInteractivePageFlip(direction: Int) {
        guard !isAnimating else {
            print("⚠️ Already animating")
            return
        }

        let index = direction == 1 ? currentIndex + 2 : currentIndex - 2
        guard index >= 0, index + 1 < pages.count else {
            print("❌ Invalid target index: \(index)")
            return
        }

        isAnimating = true
        flipContainer?.removeFromSuperview()

        let currentRightPage = pages[currentIndex + 1]
        let nextLeftPage = pages[index]

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 500

        // Flip from book center
        let containerWidth = view.bounds.width / 2
        let container = UIView(frame: CGRect(x: view.bounds.width / 2, y: 0, width: containerWidth, height: view.bounds.height))
        container.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        container.layer.position = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        container.layer.transform = transform
        container.clipsToBounds = true
        view.addSubview(container)
        flipContainer = container

        guard let back = nextLeftPage.view.snapshotView(afterScreenUpdates: true),
              let front = currentRightPage.view.snapshotView(afterScreenUpdates: true) else {
            print("❌ SnapshotView creation failed")
            return
        }

        back.frame = container.bounds
        back.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0)
        container.addSubview(back)
        backSnapshot = back

        front.frame = container.bounds
        container.addSubview(front)
        frontSnapshot = front

        print("✅ beginInteractivePageFlip succeeded for direction: \(direction)")
    }

    private func updateInteractivePageFlip(progress: CGFloat) {
        guard let flipContainer = flipContainer else {
            print("⚠️ flipContainer is nil")
            return
        }

        let angle = abs(progress * .pi)
        print("📐 Rotating flipContainer to angle: \(angle) radians")

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 1000
        flipContainer.layer.transform = CATransform3DRotate(transform, angle, 0, 1, 0)

        frontSnapshot?.isHidden = abs(progress) > 0.5
    }

    private func completeInteractivePageFlip(progress: CGFloat) {
        guard let flipContainer = flipContainer else {
            print("⚠️ flipContainer is nil on complete")
            return
        }

        let shouldFlip = abs(progress) > 0.5
        let direction = panDirection
        let targetIndex = panStartIndex + direction * 2

        print("🏁 completeInteractivePageFlip: shouldFlip=\(shouldFlip), targetIndex=\(targetIndex)")

        UIView.animate(withDuration: 0.3, animations: {
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 1000
            let angle: CGFloat = shouldFlip ? -CGFloat(direction) * .pi : 0
            flipContainer.layer.transform = CATransform3DRotate(transform, angle, 0, 1, 0)
        }, completion: { _ in
            if shouldFlip {
                self.goToPagePair(at: targetIndex)
            }
            self.flipContainer?.removeFromSuperview()
            self.flipContainer = nil
            self.isAnimating = false
        })
    }

    private func goToPagePair(at index: Int) {
        guard index >= 0 && index < pages.count - 1 else {
            print("❌ Index out of bounds: \(index)")
            return
        }
        print("➡️ Navigating to page pair at index: \(index)")

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
