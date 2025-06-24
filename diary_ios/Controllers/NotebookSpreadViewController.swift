import UIKit
protocol NotebookSpreadLayoutDelegate: AnyObject {
    func currentSpreadContentSize() -> CGSize
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIViewController {
    private var flipController: FlipAnimatorController!
    private var lockedDirection: PageTurnDirection?
    private var lastProgressForTesting: CGFloat?
    
    private let baseOffset = StackConstants.baseOffset
    private let progressThreshold = FlipConstants.progressThreshold
    private let velocityThreshold = FlipConstants.velocityThreshold

    private let pageShadowRadius = PageConstants.shadowRadius
    private let pageShadowOpacity = PageConstants.shadowOpacity
    private let pageShadowCornerRadius = PageConstants.pageCornerRadius
    
    var pages: [NotebookPageViewController] = []
    var pageCount: Int {pages.count}
    var currentIndex: Int = 2

    var pageContainers: [UIView] = []
    var containerCount: Int = 2
    var fromXOffsets: [CGFloat] = []
    var toXOffsets: [CGFloat] = []
    var fromYOffsets: [CGFloat] = []
    var toYOffsets: [CGFloat] = []

    weak var layoutDelegate: NotebookSpreadLayoutDelegate?
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

        // 重新计算 pageContainers 数量
        containerCount = (pageCount - 2) / 2
        guard containerCount > 0 else {
            print("❌ Container count = 0.")
            return 
        }

        // 根据 currentIndex 确定要展开的 pageContainer
        let offsetIndex: Int = min(max(0, currentIndex / 2 - 1), containerCount - 1)
        let xOffsets = computeXOffsets(pageIndex: currentIndex)
        let yOffsets = computeYOffsets(pageIndex: currentIndex)
        var baseX: CGFloat
        var pageIndex: Int
        
        // 确定每个 pageContainer 的位置和内容
        print("📐 PageContainers offsets: [", terminator: " ")
        for i in 0...containerCount - 1 {
            // 确定这个容器的位置
            let thisContainer = UIView()

            baseX = i <= offsetIndex ? 0 : view.bounds.width / 2
            if i == 0, currentIndex == 0 { baseX = view.bounds.width / 2 } // 封面容器在屏幕右侧
            else if i == containerCount - 1, currentIndex == pageCount - 2 { baseX = 0 } // 背页容器在屏幕左侧

            let originX = xOffsets[i] + baseX
            let originY = yOffsets[i]
            thisContainer.frame = CGRect(x: originX, y: originY, width: view.bounds.width / 2, height: view.bounds.height)

            thisContainer.layer.masksToBounds = false // 允许阴影
            thisContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
            thisContainer.layer.shadowColor = UIColor.black.cgColor
            thisContainer.layer.shadowOpacity = pageShadowOpacity
            thisContainer.layer.shadowRadius = pageShadowRadius

            // 确定这个容器的内容
            pageIndex = i <= offsetIndex ? (i + 1) * 2 : (i + 1) * 2 - 1
            if i == 0, currentIndex == 0 { pageIndex = 1 }
            else if  i == containerCount - 1, currentIndex == pageCount - 2 { pageIndex = pageCount - 2 }

            let thisPage = pages[pageIndex]
            thisPage.view.frame = thisContainer.bounds
            thisContainer.addSubview(thisPage.view)
            addEdgeShadow(to: thisPage.view)
            if i == offsetIndex { print("🏷️(\(format(xOffsets[i])), \(format(yOffsets[i])))", terminator: " ") }
            else { print("(\(format(xOffsets[i])), \(format(yOffsets[i])))", terminator: " ") }
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

    // MARK: - 计算 containers 偏移量
    func computeYOffsets(pageIndex: Int) -> [CGFloat] {
        let offsetIndex = min(max(0, pageIndex / 2 - 1), containerCount - 1)
        var offsets = Array(repeating: CGFloat(0), count: containerCount)
        if pageIndex == 0 || pageIndex == pageCount - 2 {
            return offsets
        }

        let leftCenter = offsetIndex
        let rightCenter = offsetIndex + 1
        offsets[leftCenter] = 0
        offsets[rightCenter] = 0
        for i in 0..<leftCenter { offsets[i] = computeYDecay(leftCenter - i) }
        for i in (rightCenter + 1)..<containerCount { offsets[i] = computeYDecay(i - rightCenter) }
        return offsets
    }

    func computeXOffsets(pageIndex: Int) -> [CGFloat] {
        let offsetIndex = min(max(0, pageIndex / 2 - 1), containerCount - 1)
        var offsets = Array(repeating: CGFloat(0), count: containerCount)
        if pageIndex == 0 || pageIndex == pageCount - 2 {
            return offsets
        }

        offsets[offsetIndex] = 0
        for i in 0..<offsetIndex { offsets[i] = -computeXDecay(offsetIndex - i) }
        for i in (offsetIndex + 1)..<containerCount { offsets[i] = computeXDecay(i - offsetIndex) }
        return offsets
    }

    // MARK: - 随 progress 更新位置
    func updateProgressOffset(direction: PageTurnDirection, progress: CGFloat) {
        let contentSize = layoutDelegate?.currentSpreadContentSize() ?? .zero
        let width = contentSize.width
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

    func updateStackTransforms(progress: CGFloat) {
        guard fromYOffsets.count == toYOffsets.count, fromXOffsets.count == toXOffsets.count else { return }
        let easedProgress = easeInOutCubic(abs(progress))
        for (i, container) in pageContainers.enumerated() {
            let fromY = fromYOffsets[i]
            let toY = toYOffsets[i]
            let dy = (toY - fromY) * easedProgress
            let fromX = fromXOffsets[i]
            let toX = toXOffsets[i]
            let dx = (toX - fromX) * easedProgress
            container.transform = CGAffineTransform(translationX: dx, y: dy)
        }
    }

    // MARK: - container 阴影
    func addEdgeShadow(to view: UIView) {
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
