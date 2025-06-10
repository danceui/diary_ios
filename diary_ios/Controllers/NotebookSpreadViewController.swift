import UIKit

protocol NotebookSpreadViewControllerDelegate: AnyObject {
    func currentContentWidth() -> CGFloat
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIViewController {
    private var flipController: FlipAnimatorController!
    private var lockedDirection: PageTurnDirection?
    private var lastProgressForTesting: CGFloat?
    
    var pages: [NotebookPageViewController] = []
    var currentIndex: Int = 2

    var pageContainers: [UIView] = []
    var containerCount: Int = 2
    var offsets: [CGFloat] = []

    weak var pageDelegate: NotebookSpreadViewControllerDelegate?
    var onProgressChanged: ((CGFloat) -> Void)?

    // MARK: - Constants
    private let baseOffset: CGFloat = 5

    override func viewDidLoad() {
        super.viewDidLoad()
        flipController = FlipAnimatorController(host: self)
        setupInitialPages()
        updatePageContainers()
        setupGestureRecognizers()
    }

    // MARK: - Setup
    private func setupInitialPages() {
        pages = [
            NotebookPageViewController(pageIndex: 0, role: .empty),
            NotebookPageViewController(pageIndex: 1, role: .cover),
            NotebookPageViewController(pageIndex: 2, role: .normal),
            NotebookPageViewController(pageIndex: 3, role: .normal),
            NotebookPageViewController(pageIndex: 4, role: .back),
            NotebookPageViewController(pageIndex: 5, role: .empty)
        ]
    }

    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }

    private func updatePageContainers() {
        pageContainers.forEach { $0.removeFromSuperview() }
        pageContainers.removeAll()
        containerCount = (pageCount - 2) / 2
        guard containerCount > 0 else {
            print("❌ Container count = 0.")
            return 
        }

        // 计算纸张偏移量
        offsets = Array(repeating: 0, count: containerCount)
        offsets[0] = CGFloat(1 - containerCount) / 2.0
        for i in 1..<containerCount { offsets[i] = offsets[i - 1] + 1 }
        print("📖 New offsets: \(offsets)")

        // 确定要展开的容器
        let offsetIndex: Int = min(max(0, currentIndex / 2 - 1), containerCount - 1)
        guard offsetIndex >= 0 && offsetIndex <= containerCount - 1 else {
            print("❌ Offset index \(offsetIndex) invalid.")
            return 
        }
        
        // 确定每个容器的位置和内容
        for i in 0...containerCount - 1 {
            let thisContainer = UIView()
            let thisPageIndex = i <= offsetIndex ? (i + 1) * 2 : (i + 1) * 2 - 1
            let baseX = i <= offsetIndex ? 0 : view.bounds.width / 2
            let originX = offsets[i] * baseOffset + baseX
            thisContainer.frame = CGRect(x: originX, y:0, width: view.bounds.width / 2, height: view.bounds.height)
            let thisPage = pages[thisPageIndex]
            thisPage.view.frame = thisContainer.bounds
            thisContainer.addSubview(thisPage.view)
            print("📖 Offset index \(i). Contain \(i <= offsetIndex ? "left" : "right") page \(thisPageIndex). Origin X: \(originX).")
            pageContainers.append(thisContainer)
        }

        // 按视图顺序添加视图
        // 特殊处理封面和背页
        if currentIndex == 0 {
            let thisContainer = pageContainers[1]
            let thisPage = pages[1]
            thisContainer.subviews.forEach { $0.removeFromSuperview() }
            thisPage.view.frame = thisContainer.bounds
            thisContainer.addSubview(thisPage.view)
            view.addSubview(thisContainer)
        }
        else if currentIndex == pageCount - 2 {
            let thisContainer = pageContainers.last!
            let thisPage = pages[pageCount - 2]
            thisContainer.subviews.forEach { $0.removeFromSuperview() }
            thisPage.view.frame = thisContainer.bounds
            thisContainer.addSubview(thisPage.view)
            view.addSubview(thisContainer)
        }
        else {
            for i in 0...offsetIndex {
                view.addSubview(pageContainers[i])
            }
            let range = offsetIndex + 1...containerCount - 1
            for i in range.reversed() {
                view.addSubview(pageContainers[i])
            }
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
        updatePageContainers()
        print("📄 Add page pair \(insertIndex), \(insertIndex + 1).")
        flipController.autoFlip(direction: .nextPage)
    }

    func goToPagePair(to index: Int) {
        guard index >= 0 && index < pages.count - 1 else {
            print("❌ Index out of bounds: \(index).")
            return
        }
        print("▶️ Go to page pair \(index), \(index + 1).")
        currentIndex = index
        updatePageContainers()
        applyPageShadows()
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

    // MARK: - Interfaces
    var pageCount: Int {pages.count}
}
