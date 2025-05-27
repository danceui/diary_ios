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
            NotebookPageViewController(pageIndex: 2, role: .back),
            NotebookPageViewController(pageIndex: 3, role: .empty)
        ]
        pages[1].view.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1) // 浅紫色
        pages[2].view.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1) // 浅紫色
        goToPagePair(at: 0)
    }

    private func setupGestureRecognizers() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard !isAnimating else { return }
        
        if gesture.direction == .left {
        performPageFlipAnimation(to: currentIndex + 2)
            // goToPagePair(at: currentIndex + 2)
        } else if gesture.direction == .right {
        performPageFlipAnimation(to: currentIndex - 2)
            // goToPagePair(at: currentIndex - 2)
        }
    }

    // MARK: - Page Navigation
    func addNewPagePair(initialData: Data? = nil) {
        // 不允许在最后一页之后添加页面
        guard currentIndex + 2 < pages.count else {
            print("Cannot add new page pair at the end.")
            return
        }
        let insertIndex = currentIndex + 2
        let leftPage = NotebookPageViewController(pageIndex: pages.count, initialData: initialData)
        let rightPage = NotebookPageViewController(pageIndex: pages.count + 1, initialData: initialData)
        leftPage.view.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1)
        rightPage.view.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1)
        pages.insert(contentsOf: [leftPage, rightPage], at: insertIndex)
        currentIndex = insertIndex
        print("Insert page pair #\(insertIndex), #\(insertIndex + 1).")
        goToPagePair(at: insertIndex)
    }

    func getPageCount() -> Int { return pages.count }
    
    private func goToPagePair(at index: Int) {
        guard index >= 0 && index < pages.count - 1 else {
            print("Index out of bounds: \(index)")
            return
        }
        print("Go to page #\(index), #\(index + 1).")
        let leftPage = pages[index]
        let rightPage = pages[index + 1]
        leftPageContainer.isHidden = false
        rightPageContainer.isHidden = false
        
        [leftPage, rightPage].forEach {
            $0.view.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            $0.view.layer.transform = CATransform3DIdentity
        }
        
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
private func performPageFlipAnimation(to index: Int) {
    guard index >= 2, index + 1 < pages.count else { return }
    guard !isAnimating else { return }
    isAnimating = true

    let currentRightPage = pages[index - 1]
    let nextLeftPage = pages[index]
    let nextRightPage = pages[index + 1]

    // 1. 准备3D透视变换
    var transform = CATransform3DIdentity
    transform.m34 = -1.0 / 500  // 更强的透视效果
    
    // 2. 创建双面容器
    let flipContainer = UIView(frame: rightPageContainer.frame)
    flipContainer.layer.anchorPoint = CGPoint(x: 0, y: 0.5) // 从右侧翻转
    flipContainer.layer.position = CGPoint(x: rightPageContainer.frame.minX, y: rightPageContainer.frame.midY)
    flipContainer.layer.transform = transform
    view.addSubview(flipContainer)

    // 3. 创建正面视图（当前页）
    let frontView = currentRightPage.view.snapshotView(afterScreenUpdates: true)!
    frontView.frame = flipContainer.bounds
    
    // 4. 创建背面视图（下一页）
    let backView = nextLeftPage.view.snapshotView(afterScreenUpdates: true)!
    backView.frame = flipContainer.bounds
    backView.layer.transform = CATransform3DMakeRotation(.pi, 0, 1, 0) // 初始旋转180度
    
    // 5. 构建双面结构
    let container = CALayer()
    container.frame = flipContainer.bounds
    container.isDoubleSided = true
    
    let frontLayer = frontView.layer
    let backLayer = backView.layer
    
    // 设置背面内容
    backLayer.isDoubleSided = true
    backLayer.transform = CATransform3DMakeRotation(.pi, 0, 1, 0)
    
    // 添加到容器
    container.addSublayer(frontLayer)
    container.addSublayer(backLayer)
    flipContainer.layer.addSublayer(container)
    
    // 6. 准备新页面
    nextRightPage.view.frame = rightPageContainer.bounds
    nextRightPage.view.isHidden = true
    rightPageContainer.addSubview(nextRightPage.view)
    currentRightPage.view.isHidden = true

    // 7. 动画执行
    UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: {
        flipContainer.layer.transform = CATransform3DRotate(transform, -.pi, 0, 1, 0)
    }, completion: { _ in
        // 8. 清理工作
        flipContainer.removeFromSuperview()
        currentRightPage.view.isHidden = false
        
        // 9. 更新页面状态
        self.leftPageContainer.subviews.forEach { $0.removeFromSuperview() }
        self.leftPageContainer.addSubview(nextLeftPage.view)
        
        self.currentIndex = index
        self.isAnimating = false
    })
}

    // MARK: - Notebook Appearance
    private func applyPageShadows() {
        pages.enumerated().forEach { index, page in
            page.view.layer.shadowColor = UIColor.black.cgColor
            page.view.layer.shadowOpacity = 0.3
            page.view.layer.shadowRadius = 5
            page.view.layer.shadowOffset = CGSize(width: 0, height: 1)
            
            if index == currentIndex {
                // 左页阴影在右侧
                page.view.layer.shadowPath = UIBezierPath(rect: CGRect(
                    x: page.view.bounds.width - 10,
                    y: 0,
                    width: 10,
                    height: page.view.bounds.height
                )).cgPath
            } else if index == currentIndex + 1 {
                // 右页阴影在左侧
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

    // MARK: - Other Methods
    private func notifyPageState(_ index: Int) {
        let role: PageRole 
        if index == 0 {
            role = .cover
        } else if index == pages.count - 2 {
            role = .back
        } else {
            role = .normal
        }
        pageDelegate?.notebookSpreadViewController(self, didUpdatePageRole: role)
    }

    func exportAllDrawings() -> [Data] {
        return pages.map { $0.exportDrawing() }
    }

    func undo() {
        if currentIndex < pages.count {
            pages[currentIndex].undo()
        }
        if currentIndex + 1 < pages.count {
            pages[currentIndex + 1].undo()
        }
    }

    func redo() {
        if currentIndex < pages.count {
            pages[currentIndex].redo()
        }
        if currentIndex + 1 < pages.count {
            pages[currentIndex + 1].redo()
        }
    }
}
