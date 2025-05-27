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
    private var panDirection: PageTurnDirection = .nextPage

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
        let progress = min(max(translation.x * 2 / view.bounds.width, -1), 1)
        
        switch gesture.state {
        case .changed:
            if flipContainer == nil {
                panStartIndex = currentIndex
                panDirection = translation.x < 0 ? .nextPage : .lastPage
                beginPageFlip(direction: panDirection)
            }
            updatePageFlip(progress: progress)
        case .ended, .cancelled:
            completeInteractivePageFlip(progress: progress)
        default:
            break
        }
    }

    private func beginPageFlip(direction: PageTurnDirection) {
        guard !isAnimating else {
            print("⚠️ Already animating")
            return
        }

        let newIndex = direction == .nextPage ? currentIndex + 2 : currentIndex - 2
        guard newIndex >= 0, newIndex + 1 < pages.count else {
            print("❌ Invalid target index: \(newIndex)")
            return
        }

        isAnimating = true
        flipContainer?.removeFromSuperview()

        let flippingPage: NotebookPageViewController
        let nextPage: NotebookPageViewController
        let containerFrame: CGRect
        let anchorPoint: CGPoint
        let containerX: CGFloat

        if direction == .nextPage {
            print("📌 Pan first updating. ➡️ Flipping to next page pair at index: \(newIndex)")
            flippingPage = pages[currentIndex + 1]
            nextPage = pages[newIndex]
            containerFrame = CGRect(x: view.bounds.width / 2, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
            anchorPoint = CGPoint(x: 0, y: 0.5)
            containerX = view.bounds.width / 2
        } else {
            print("📌 Pan first updating. ⬅️ Flipping to last page pair at index: \(newIndex)")
            flippingPage = pages[currentIndex]
            nextPage = pages[newIndex + 1]
            containerFrame = CGRect(x: 0, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
            anchorPoint = CGPoint(x: 1, y: 0.5)
            containerX = view.bounds.width / 2
        }

        let container = UIView(frame: containerFrame)
        container.layer.anchorPoint = anchorPoint
        container.layer.position = CGPoint(x: containerX, y: view.bounds.height / 2)
        container.clipsToBounds = true

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 1500
        container.layer.transform = transform

        view.addSubview(container)
        self.flipContainer = container

        guard let front = flippingPage.view.snapshotView(afterScreenUpdates: true),
            let back = nextPage.view.snapshotView(afterScreenUpdates: true) else {
            print("❌ SnapshotView creation failed")
            return
        }

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

    private func updatePageFlip(progress: CGFloat) {
        guard let flipContainer = flipContainer else {
            print("⚠️ flipContainer is nil")
            return
        }

        let angle = progress * .pi
        print("📌 Pan changed. 📐 Rotating progress \(progress), angle: \(angle).")

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 1500
        flipContainer.layer.transform = CATransform3DRotate(transform, angle, 0, 1, 0)
        
        if progress > 0.5 {
            frontSnapshot?.isHidden = true
            backSnapshot?.isHidden = false
            print("▪️ Show backSnapshot, hide frontSnapshot.")
        } else {
            frontSnapshot?.isHidden = false
            backSnapshot?.isHidden = true
            print("🔸 Show frontSnapshot, hide backSnapshot.")
        }
    }

    private func completeInteractivePageFlip(progress: CGFloat) {
        guard let flipContainer = flipContainer else {
            print("⚠️ flipContainer is nil on complete")
            return
        }

        let shouldFlip = abs(progress) > 0.5
        let direction = panDirection
        let targetIndex = direction == .nextPage ? currentIndex + 2 : currentIndex - 2

        print("🏁 completeInteractivePageFlip: shouldFlip=\(shouldFlip), targetIndex=\(targetIndex)")

        UIView.animate(withDuration: 0.3, animations: {
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 1000
            let angle: CGFloat = shouldFlip ? .pi : 0
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
