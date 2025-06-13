import UIKit

protocol NotebookSpreadViewControllerDelegate: AnyObject {
    func currentContentWidth() -> CGFloat
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIViewController {
    private var flipController: FlipAnimatorController!
    private var lockedDirection: PageTurnDirection?
    private var lastProgressForTesting: CGFloat?
    private var centerBindingEdge: UIView?
    private var bottomBindingBar: CAShapeLayer?
    
    private let baseOffset = StackConstants.baseOffset
    private let progressThreshold = FlipConstants.progressThreshold
    private let velocityThreshold = FlipConstants.velocityThreshold
    
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

    // MARK: - PageContainer Management
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
        print("   📐 OriginX: [", terminator: " ")
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
        addCenterBindingEdge()
        addBottomBindingBar()
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

    // MARK: - Progress Related Functions
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
        if shouldPrint { print("   📐 OriginY: [", terminator: " ")}
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

    // MARK: - Notebook Appearance
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

    private func addCenterBindingEdge() {
        print("📖 Add binding edge.")
        // 先移除旧的装订视图
        centerBindingEdge?.removeFromSuperview()

        let bindingWidth: CGFloat = 12
        let contentHeight = view.bounds.height
        let contentWidth = view.bounds.width
        let x = contentWidth / 2 - bindingWidth / 2

        let bindingView = UIView(frame: CGRect(x: x, y: 0, width: bindingWidth, height: contentHeight))
        bindingView.backgroundColor = UIColor.darkGray

        // 添加圆角 + 阴影提升质感
        bindingView.layer.cornerRadius = bindingWidth / 2
        bindingView.layer.shadowColor = UIColor.black.cgColor
        bindingView.layer.shadowOpacity = 0.15
        bindingView.layer.shadowRadius = 2
        bindingView.layer.shadowOffset = CGSize(width: 0, height: 2)

        // 可选：金属渐变层
        let gradient = CAGradientLayer()
        gradient.frame = bindingView.bounds
        gradient.colors = [
            UIColor(white: 0.25, alpha: 1).cgColor,
            UIColor(white: 0.4, alpha: 1).cgColor,
            UIColor(white: 0.25, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        bindingView.layer.insertSublayer(gradient, at: 0)

        view.addSubview(bindingView)
        centerBindingEdge = bindingView
    }
private func addBottomBindingBar() {
    bottomBindingBar?.removeFromSuperlayer()

    guard !pageContainers.isEmpty else { return }

    let path = UIBezierPath()
    let barHeight: CGFloat = 10

    // 左下角点序列（从前到后）
    let leftPoints: [CGPoint] = pageContainers.map {
        view.convert(CGPoint(x: $0.frame.minX, y: $0.frame.maxY), from: $0.superview)
    }

    // 右下角点序列（从后到前）
    let rightPoints: [CGPoint] = pageContainers.reversed().map {
        view.convert(CGPoint(x: $0.frame.maxX, y: $0.frame.maxY), from: $0.superview)
    }

    // 开始绘制路径：从第一个左下角点开始
    if let start = leftPoints.first {
        path.move(to: CGPoint(x: start.x, y: start.y))
    }

    // 连到所有左下角点
    for point in leftPoints.dropFirst() {
        path.addLine(to: point)
    }

    // 连到所有右下角点（形成闭合区域）
    for point in rightPoints {
        path.addLine(to: point)
    }

    path.close()

    let shape = CAShapeLayer()
    shape.path = path.cgPath
    shape.fillColor = UIColor.darkGray.cgColor
    shape.shadowColor = UIColor.black.cgColor
    shape.shadowOpacity = 0.15
    shape.shadowOffset = CGSize(width: 0, height: -1)
    shape.shadowRadius = 2

    view.layer.addSublayer(shape)
    bottomBindingBar = shape
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
