import UIKit

protocol NotebookSpreadViewControllerDelegate: AnyObject {
    func currentContentWidth() -> CGFloat
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIViewController {
    private var pages: [NotebookPageViewController] = []
    private var offsets: [CGFloat] = []
    private var flipController: FlipAnimatorController!
    private var lockedDirection: PageTurnDirection?
    private var lastProgressForTesting: CGFloat?
    
    var currentIndex: Int = 0
    var pagesContainer = UIView()

    weak var pageDelegate: NotebookSpreadViewControllerDelegate?
    var onProgressChanged: ((CGFloat) -> Void)?

    // MARK: - Constants
    private let baseOffset: CGFloat = 5

    override func viewDidLoad() {
        super.viewDidLoad()
        flipController = FlipAnimatorController(host: self)
        setupPageContainers()
        setupInitialPages()
        setupGestureRecognizers()
    }

    // MARK: - Setup
    private func setupPageContainers() {
        pagesContainer.frame = view.bounds
        pagesContainer.backgroundColor = .clear
        view.addSubview(pagesContainer)
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
        updatePagesContainer()
        goToPagePair(to: 2)
    }

    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }

    // MARK: - Layout & Visibility
    private func updatePagesContainer() {
        print("📖 Update pages container...")

        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        // 更新书页接缝处的位移
        let offsetCount = max((pages.count - 2) / 2, 0)
        offsets = Array(repeating: 0, count: offsetCount)
        offsets[0] = CGFloat(1 - offsetCount) / 2.0
        for i in 1..<offsetCount {
            offsets[i] = offsets[i - 1] + 1
        }
        print("📖 New offsets: \(offsets)")

        // 结合当前页码判断
        pagesContainer.subviews.forEach { $0.removeFromSuperview() }
        if currentIndex == 0 || currentIndex == pages.count - 2 { return }
        let offsetIndex: Int = currentIndex / 2 - 1
        for i in offsets.indices {
            let thisPageContainer = UIView()
            // 确定每页的容器位置
            if i <= offsetIndex {
                // thisPageContainer.frame = CGRect(x: offsets[i] * baseOffset, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
                thisPageContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
                let thisLeftPageIndex: Int = (i + 1) * 2
                let thisLeftPage = pages[thisLeftPageIndex]
                print("📖 Offset index: \(i). Add left page \(thisLeftPageIndex).", terminator: " ")
                thisPageContainer.addSubview(thisLeftPage.view)
                addChild(thisLeftPage)
                thisLeftPage.didMove(toParent: self)
            }
            else {
                // thisPageContainer.frame = CGRect(x: view.bounds.width / 2 + offsets[i] * baseOffset, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
                thisPageContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
                let thisRightPageIndex: Int = (i + 1) * 2 - 1
                let thisRightPage = pages[thisRightPageIndex]
                print("📖 Offset index: \(i). Add right page \(thisRightPageIndex).", terminator: " ")
                thisPageContainer.addSubview(thisRightPage.view)
                addChild(thisRightPage)
                thisRightPage.didMove(toParent: self)
            }
            if thisPageContainer.superview == nil {
                pagesContainer.addSubview(thisPageContainer)
            }
            print("OffsetX: \(thisPageContainer.bounds.minX)")
        }
    }

    // MARK: - Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let progress = min(max(translation.x * 2 / view.bounds.width, -1), 1)
        let direction: PageTurnDirection = translation.x < 0 ? .nextPage : .lastPage

        switch gesture.state {
        case .changed:
            if lockedDirection == nil {
                lockedDirection = direction
                print("✋ Begin page flip: progress \(format(progress)).")
                flipController.begin(direction: direction, type: .manual)
            } else if direction != lockedDirection {
                print("✋ Cancel page flip: Progress sign reversed.")
                flipController.cancel(direction: direction, progress: direction == .nextPage ? -0.001 : 0.001, type: .manual, velocity: 1000)
                return
            }

            if let last = lastProgressForTesting {
                if format(last) != format(progress) {
                    print("✋ Update page flip: progress \(format(progress)).")
                    lastProgressForTesting = progress
                }
            } else {
                print("✋ Update page flip: progress \(format(progress)).")
                lastProgressForTesting = progress
            }

            flipController.update(direction: direction, progress: progress, type: .manual)
        case .ended, .cancelled:
            lockedDirection = nil
            if abs(velocity.x) > 800 || abs(progress) > 0.5 {
                print("✋ Complete page flip - progress \(format(progress)).")
                flipController.complete(direction: direction, progress: progress, type: .manual, velocity: velocity.x)
            } else {
                print("✋ Cancel page flip - progress \(format(progress)).")
                flipController.cancel(direction: direction, progress: progress, type: .manual, velocity: velocity.x)
            }
        default:
            break
        }
    }

    // MARK: - Page Management
    func addNewPagePair(initialData: Data? = nil) {
        if flipController.isAnimating {
            print("❌ Cannot add page during animation.")
            return
        }

        guard currentIndex + 2 < pages.count else {
            print("❌ Cannot add page at the end.")
            return
        }

        let insertIndex = currentIndex + 2
        let leftPage = NotebookPageViewController(pageIndex: insertIndex, initialData: initialData)
        let rightPage = NotebookPageViewController(pageIndex: insertIndex + 1, initialData: initialData)

        pages.insert(contentsOf: [leftPage, rightPage], at: insertIndex)
        updatePagesContainer()
        print("📄 Add page pair \(insertIndex), \(insertIndex + 1).")
        flipController.autoFlip(direction: .nextPage)
    }

    func goToPagePair(to index: Int) {
        guard index >= 0 && index < pages.count - 1 else {
            print("❌ Index out of bounds: \(index).")
            return
        }

        currentIndex = index
        updatePagesContainer()

        let leftPage = pages[index]
        let rightPage = pages[index + 1]
        pagesContainer.bringSubviewToFront(leftPage.view)
        pagesContainer.bringSubviewToFront(rightPage.view)
        print("▶️ Go to page pair \(index), \(index + 1).")

        applyPageShadows()
        applyPageStackStyle()
    }

    func updateProgressOffset(direction: PageTurnDirection, progress: CGFloat) {
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

    // MARK: - Appearance
    private func applyPageShadows() {
        print("✏️ Apply page shadows.")
        for (index, page) in pages.enumerated() {
            page.view.layer.shadowColor = UIColor.black.cgColor
            page.view.layer.shadowOpacity = 0.3
            page.view.layer.shadowRadius = 5
            page.view.layer.shadowOffset = CGSize(width: 0, height: 1)

            if index == currentIndex {
                // 左页阴影靠右侧 10px
                page.view.layer.shadowPath = UIBezierPath(
                    rect: CGRect(
                        x: page.view.bounds.width - 10,
                        y: 0,
                        width: 10,
                        height: page.view.bounds.height
                    )
                ).cgPath
            } else if index == currentIndex + 1 {
                // 右页阴影靠左侧 10px
                page.view.layer.shadowPath = UIBezierPath(
                    rect: CGRect(
                        x: 0,
                        y: 0,
                        width: 10,
                        height: page.view.bounds.height
                    )
                ).cgPath
            } else {
                page.view.layer.shadowPath = nil
            }
        }
    }

    private func applyPageStackStyle() {
        print("✏️ Apply page stack style.")
        for (index, page) in pages.enumerated() {
            let delta = CGFloat(index - currentIndex)
            // 根据 delta 计算微小的 anchorPoint 偏移和绕 Y 轴旋转角度
            let anchorShift = max(-0.02, min(0.02, delta * 0.005))
            let rotationAngle = delta * 0.015
            let zPos = -abs(delta)

            // 左页：anchorX 基本在 1.0，右页：anchorX 基本在 0.0；再加上微小偏移
            let isLeftPage = (index % 2 == 0)
            let baseAnchorX: CGFloat = isLeftPage ? 1.0 : 0.0
            let newAnchorX = baseAnchorX + anchorShift
            page.view.layer.anchorPoint = CGPoint(x: newAnchorX, y: 0.5)

            // anchorPoint 改了以后，要把 position 拉回 frame 的中心，否则会“漂移”
            page.view.layer.position = CGPoint(
                x: page.view.frame.midX,
                y: page.view.frame.midY
            )

            // 3D 透视：如果在 setupPageContainers() 里没有设置 sublayerTransform 的 m34，
            // 可以在这里单独针对每个页面设置一下
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 1500
            page.view.layer.transform = CATransform3DRotate(transform, rotationAngle, 0, 1, 0)

            // zPosition 决定渲染的层级：delta 越小，zPosition 越高
            page.view.layer.zPosition = zPos
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

    // MARK: - Interfaces
    var totalPages: Int {pages.count}
    func currentPagePair() -> (left: NotebookPageViewController, right: NotebookPageViewController)? {
        guard currentIndex >= 0, currentIndex + 1 < pages.count else { return nil }
        print("☕️ Return current page pair \(currentIndex), \(currentIndex + 1).", terminator: " ")
        return (pages[currentIndex], pages[currentIndex + 1])
    }

    func pagePair(at index: Int) -> (left: NotebookPageViewController, right: NotebookPageViewController)? {
        guard index >= 0, index + 1 < pages.count else { return nil }
        print("☕️ Return page pair \(index), \(index + 1).")
        return (pages[index], pages[index + 1])
    }
}
