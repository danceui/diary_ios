import UIKit
protocol NotebookSpreadLayoutDelegate: AnyObject {
    func currentSpreadContentSize() -> CGSize
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIViewController {
    private lazy var flipController = FlipAnimatorController(host: self)
    private var lockedDirection: PageTurnDirection?
    private var spineShadow = UIView()
    
    var pages: [NotebookPageView] = []
    var pageCount: Int {pages.count}
    var currentIndex: Int = 2

    var pageContainers: [UIView] = []
    var containerCount: Int = 2
    var fromXOffsets: [CGFloat] = []
    var toXOffsets: [CGFloat] = []
    var fromYOffsets: [CGFloat] = []
    var toYOffsets: [CGFloat] = []
    var fromShadowOpacities: [Float] = []
    var toShadowOpacities: [Float] = []

    weak var layoutDelegate: NotebookSpreadLayoutDelegate?
    var onProgressChanged: ((CGFloat) -> Void)?

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        printLifeCycleInfo(context: "[\(type(of: self))] 3️⃣ viewDidLoad", for: view)
        setupInitialPages()
        setupGestureRecognizers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        printLifeCycleInfo(context: "[\(type(of: self))] 4️⃣ viewWillAppear", for: view)
        updatePageContainers()
        setupSpineShadow()
    }

    // MARK: - Setup
    private func setupInitialPages() {
        pages = [
            NotebookPageView(role: .empty),
            NotebookPageView(role: .cover, isLeft: false),
            NotebookPageView(role: .normal, isLeft: true),
            NotebookPageView(role: .normal, isLeft: false),
            NotebookPageView(role: .back, isLeft: true),
            NotebookPageView(role: .empty)
        ]
    }

    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }

    private func setupSpineShadow() {
        spineShadow.removeFromSuperview()
        spineShadow.frame = view.bounds
        spineShadow.backgroundColor = .clear
        spineShadow.isUserInteractionEnabled = false
        spineShadow.layer.shadowPath = UIBezierPath(rect: CGRect(x: view.bounds.width / 2, y: 0, width: spineShadowWidth, height: view.bounds.height)).cgPath
        spineShadow.layer.shadowColor = UIColor.black.cgColor
        spineShadow.layer.shadowOffset = .zero
        spineShadow.layer.shadowOpacity = 0
        spineShadow.layer.shadowRadius = pageShadowRadius
        view.insertSubview(spineShadow, at: 0)
    }
    // MARK: - 更新 containers
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
        let opacities = computeShadowOpacities(pageIndex: currentIndex)
        
        print("📐 PageContainers offsets: [", terminator: " ")
        for i in 0...containerCount - 1 {
            // 确定这个容器的位置
            let thisContainer = UIView()

            var baseX: CGFloat = i <= offsetIndex ? 0 : view.bounds.width / 2
            if i == 0, currentIndex == 0 { baseX = view.bounds.width / 2 } // 封面容器在屏幕右侧
            else if i == containerCount - 1, currentIndex == pageCount - 2 { baseX = 0 } // 背页容器在屏幕左侧

            let originX = xOffsets[i] + baseX
            let originY = yOffsets[i]
            thisContainer.layer.shadowOpacity = opacities[i]

            thisContainer.frame = CGRect(x: originX, y: originY, width: view.bounds.width / 2, height: view.bounds.height)
            thisContainer.layer.masksToBounds = false // 允许阴影
            thisContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
            thisContainer.layer.shadowColor = UIColor.black.cgColor
            thisContainer.layer.shadowRadius = pageShadowRadius

            // 确定这个容器的内容
            var pageIndex: Int = i <= offsetIndex ? (i + 1) * 2 : (i + 1) * 2 - 1
            if i == 0, currentIndex == 0 { pageIndex = 1 }
            else if  i == containerCount - 1, currentIndex == pageCount - 2 { pageIndex = pageCount - 2 }

            let thisPage = pages[pageIndex]
            thisContainer.addSubview(thisPage)
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
        guard !flipController.isAnimating else {
            print("❌ Cannot add page during animation.")
            return
        }
        guard currentIndex + 2 < pages.count else {
            print("❌ Cannot add page at the end.")
            return
        }

        let insertIndex = currentIndex + 2
        let leftPage = NotebookPageView(isLeft: true, initialData: initialData)
        let rightPage = NotebookPageView(isLeft: false, initialData: initialData)
        pages.insert(contentsOf: [leftPage, rightPage], at: insertIndex)
        print("📄 Add page pair \(insertIndex), \(insertIndex + 1).")

        updatePageContainers()
        view.layoutIfNeeded()
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

    // MARK: - containers 相关计算
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
        for i in 0..<offsetIndex { offsets[i] = -computeXDecay(offsetIndex - i + 1) + computeXDecay(1)}
        for i in (offsetIndex + 1)..<containerCount { offsets[i] = computeXDecay(i - offsetIndex) }
        return offsets
    }

    func computeShadowOpacities(pageIndex: Int) -> [Float] {
        var opacities = Array(repeating: Float(0), count: containerCount)
        if pageIndex == 0 {
            opacities[0] = pageShadowOpacity
        } else if pageIndex == pageCount - 2 {
            opacities[containerCount - 1] = pageShadowOpacity
        } else {
            opacities = Array(repeating: pageShadowOpacity, count: containerCount)
        }
        return opacities
    }

    // MARK: - 翻页时更新的函数
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
            let fromOpacity = fromShadowOpacities[i]
            let toOpacity = toShadowOpacities[i]
            let opacity = fromOpacity + (toOpacity - fromOpacity) * Float(easedProgress)
            container.layer.shadowOpacity = opacity
        }
        spineShadow.layer.shadowOpacity = computeSpineShadowOpacity(absProgress: abs(progress))
        print("\(spineShadow.layer.shadowOpacity)")
    }

    // MARK: - 生命周期测试函数
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        printLifeCycleInfo(context: "[\(type(of: self))] 6️⃣ viewDidLayoutSubviews", for: view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        printLifeCycleInfo(context: "[\(type(of: self))] 7️⃣ viewDidAppear", for: view)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        printLifeCycleInfo(context: "[\(type(of: self))] 8️⃣ viewWillDisappear", for: view)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        printLifeCycleInfo(context: "[\(type(of: self))] 9️⃣ viewDidDisappear", for: view)
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
    
    // MARK: - 常量
    private let baseOffset = StackConstants.baseOffset
    private let progressThreshold = FlipConstants.progressThreshold
    private let velocityThreshold = FlipConstants.velocityThreshold
    private let pageShadowRadius = PageConstants.pageShadowRadius
    private let pageShadowOpacity = PageConstants.pageShadowOpacity
    private let spineShadowWidth = computeXDecay(1)

    

    // MARK: - 测试用
    private var lastProgressForTesting: CGFloat?
}
