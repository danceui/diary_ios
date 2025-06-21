import UIKit
protocol NotebookSpreadViewControllerDelegate: AnyObject {
    func currentContentWidth() -> CGFloat
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIViewController {
    private var flipController: FlipAnimatorController!
    private var lockedDirection: PageTurnDirection?
    private var lastProgressForTesting: CGFloat?
    
    private let baseOffset = StackConstants.baseOffset
    private let progressThreshold = FlipConstants.progressThreshold
    private let velocityThreshold = FlipConstants.velocityThreshold
    private let pageCornerRadius = PageConstants.pageCornerRadius
    
    var pages: [NotebookPageViewController] = []
    var pageCount: Int {pages.count}
    var currentIndex: Int = 2

    var pageContainers: [UIView] = []
    var containerCount: Int = 2
    var XOffsets: [CGFloat] = []
    var fromYOffsets: [CGFloat] = []
    var toYOffsets: [CGFloat] = []

    weak var pageDelegate: NotebookSpreadViewControllerDelegate?
    var onProgressChanged: ((CGFloat) -> Void)?

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        flipController = FlipAnimatorController(host: self)
        setupInitialPages()
        setupGestureRecognizers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePageContainers()
    }

    // MARK: - Setup
    private func setupInitialPages() {
        pages = [
            NotebookPageViewController(role: .empty),
            NotebookPageViewController(role: .cover),
            NotebookPageViewController(role: .normal),
            NotebookPageViewController(role: .normal),
            NotebookPageViewController(role: .back),
            NotebookPageViewController(role: .empty)
        ]
    }

    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }

    // MARK: - 更新PageContainers
    private func updatePageContainers() {
        // 清空 pageContainers
        pageContainers.forEach { $0.removeFromSuperview() }
        pageContainers.removeAll()

        // 重新计算 pageContainers
        containerCount = (pageCount - 2) / 2
        guard containerCount > 0 else {
            print("❌ Container count = 0.")
            return 
        }

        // 根据 currentIndex 确定要展开的 pageContainer
        let offsetIndex: Int = min(max(0, currentIndex / 2 - 1), containerCount - 1)
        guard offsetIndex >= 0 && offsetIndex <= containerCount - 1 else {
            print("❌ Offset index \(offsetIndex) invalid.")
            return 
        }

        XOffsets = computeXOffsets()
        let offsetsY = computeYOffsets(pageIndex: currentIndex)

        var baseX: CGFloat
        var pageIndex: Int
        
        // 确定每个 pageContainer 的位置和内容
        print("   📐 PageContainers originX: [", terminator: " ")
        for i in 0...containerCount - 1 {
            // 确定这个容器的位置
            let thisContainer = UIView()
            baseX = i <= offsetIndex ? 0 : view.bounds.width / 2
            if i == 0, currentIndex == 0 {
                baseX = view.bounds.width / 2
            } else if i == containerCount - 1, currentIndex == pageCount - 2 {
                baseX = 0
            }
            let originX = XOffsets[i] * baseOffset + baseX
            let originY = offsetsY[i]
            thisContainer.frame = CGRect(x: originX, y: originY, width: view.bounds.width / 2, height: view.bounds.height)

            // 确定这个容器的内容
            pageIndex = i <= offsetIndex ? (i + 1) * 2 : (i + 1) * 2 - 1
            if i == 0, currentIndex == 0 {
                pageIndex = 1
            } else if i == containerCount - 1, currentIndex == pageCount - 2 {
                pageIndex = pageCount - 2
            }
            let thisPage = pages[pageIndex]
            thisPage.view.frame = thisContainer.bounds
            thisContainer.addSubview(thisPage.view)
            print("\(originX)", terminator: " ")
            pageContainers.append(thisContainer)
        }
        print("].")

        // 按视图顺序添加视图
        for i in 0...offsetIndex {
            view.addSubview(pageContainers[i])
        }
        for i in stride(from: containerCount - 1, through: offsetIndex + 1, by: -1) where offsetIndex + 1 <= containerCount - 1 {
            view.addSubview(pageContainers[i])
        }
        // 特殊处理封面和背页
        if currentIndex == 0 {
            view.addSubview(pageContainers[0])
        }
        else if currentIndex == pageCount - 2 {
            view.addSubview(pageContainers.last!)
        }
    }

    // MARK: - 手势处理
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
            if abs(velocity.x) > velocityThreshold || abs(progress) > progressThreshold {
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

    // MARK: - 页面管理
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
        let leftPage = NotebookPageViewController(initialData: initialData)
        let rightPage = NotebookPageViewController(initialData: initialData)
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
    }

    // MARK: - 随progress更新的函数
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

    func computeYOffsets(pageIndex i: Int) -> [CGFloat] {
        let centerIndex = min(max(0, i / 2 - 1), containerCount - 1)
        var offsets = Array(repeating: CGFloat(0), count: containerCount)
        for i in 0..<containerCount {
            let depth = i <= centerIndex ? (centerIndex - i) : (i - centerIndex - 1)
            offsets[i] = CGFloat(depth) * baseOffset
        }
        return offsets
    }
    
    func computeXOffsets() -> [CGFloat] {
        guard containerCount > 0 else { return [] }
        var offsets = Array(repeating: CGFloat(0), count: containerCount)
        offsets[0] = CGFloat(1 - containerCount) / 2.0
        for i in 1..<containerCount {
            offsets[i] = offsets[i - 1] + 1
        }
        return offsets
    }

    func updateStackTransforms(progress: CGFloat, shouldPrint: Bool) {
        guard fromYOffsets.count == toYOffsets.count else { return }
        let easedProgress = easeInOutCubic(abs(progress))
        if shouldPrint { print("   📐 PageContainers originY: [", terminator: " ")}
        for (i, container) in pageContainers.enumerated() {
            guard i < fromYOffsets.count else { continue }
            let fromY = fromYOffsets[i]
            let toY = toYOffsets[i]
            let dy = (toY - fromY) * easedProgress
            if shouldPrint { print("\(format(fromY + dy))", terminator: " ")}
            container.transform = CGAffineTransform(translationX: 0, y: dy)
        }
        if shouldPrint { print("].")}
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
