import UIKit

protocol NotebookSpreadViewControllerDelegate: AnyObject {
    func notebookSpreadViewController(_ controller: NotebookSpreadViewController, didUpdatePageRole role: PageRole)
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIViewController {
    private var pages: [NotebookPageViewController] = []
    private var currentIndex: Int = 0
    private var leftPageContainer = UIView()
    private var rightPageContainer = UIView()
    weak var pageDelegate: NotebookSpreadViewControllerDelegate?
    private var isAnimating = false

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
            NotebookPageViewController(pageIndex: 0, role: .cover),
            NotebookPageViewController(pageIndex: 1, role: .normal),
            NotebookPageViewController(pageIndex: 2, role: .normal),
            NotebookPageViewController(pageIndex: 3, role: .back),
        ]
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
            flipToNextPage()
        } else if gesture.direction == .right {
            flipToPreviousPage()
        }
    }

    func addNewPagePair(initialData: Data? = nil) {
        let leftPage = NotebookPageViewController(pageIndex: pages.count, initialData: initialData)
        let rightPage = NotebookPageViewController(pageIndex: pages.count + 1, initialData: initialData)
        pages.insert(contentsOf: [leftPage, rightPage], at: pages.count - 1) // Insert before back
        goToPagePair(at: pages.count - 3)
    }

    func getPageCount() -> Int {
        return pages.count
    }

    // 向前翻页（向右翻）
    func flipToNextPage() {
        guard currentIndex + 2 < pages.count, !isAnimating else { return }
        isAnimating = true
        
        let currentRightPage = pages[currentIndex + 1]
        let nextLeftPage = pages[currentIndex + 2]
        
        // 设置初始状态
        nextLeftPage.view.frame = rightPageContainer.bounds
        nextLeftPage.view.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        nextLeftPage.view.layer.position = CGPoint(x: rightPageContainer.bounds.minX, y: rightPageContainer.bounds.midY)
        nextLeftPage.view.layer.transform = CATransform3DMakeRotation(.pi / 2, 0, 1, 0)
        rightPageContainer.addSubview(nextLeftPage.view)
        
        // 创建翻页动画
        UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseInOut, animations: {
            // 当前右页翻过去
            currentRightPage.view.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            currentRightPage.view.layer.position = CGPoint(x: self.rightPageContainer.bounds.minX, y: self.rightPageContainer.bounds.midY)
            currentRightPage.view.layer.transform = CATransform3DMakeRotation(-.pi / 2, 0, 1, 0)
            
            // 新左页翻过来
            nextLeftPage.view.layer.transform = CATransform3DIdentity
        }) { _ in
            currentRightPage.view.removeFromSuperview()
            currentRightPage.view.layer.transform = CATransform3DIdentity
            self.currentIndex += 2
            self.goToPagePair(at: self.currentIndex)
            self.isAnimating = false
        }
    }
    
    // 更新goToPagePair方法
    private func goToPagePair(at index: Int) {
        guard index >= 0, index + 1 < pages.count else { return }
        
        let leftPage = pages[index]
        let rightPage = pages[index + 1]
        
        // 重置所有变换
        leftPage.view.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        leftPage.view.layer.position = CGPoint(x: leftPageContainer.bounds.midX, y: leftPageContainer.bounds.midY)
        leftPage.view.layer.transform = CATransform3DIdentity
        
        rightPage.view.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        rightPage.view.layer.position = CGPoint(x: rightPageContainer.bounds.midX, y: rightPageContainer.bounds.midY)
        rightPage.view.layer.transform = CATransform3DIdentity
        
        leftPageContainer.subviews.forEach { $0.removeFromSuperview() }
        rightPageContainer.subviews.forEach { $0.removeFromSuperview() }
        
        leftPage.view.frame = leftPageContainer.bounds
        rightPage.view.frame = rightPageContainer.bounds
        
        leftPageContainer.addSubview(leftPage.view)
        rightPageContainer.addSubview(rightPage.view)
        
        currentIndex = index
        informPageState(index)
        applyPageShadows()
    }
    
    // 添加页面阴影增强立体感
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
    // 向后翻页（向左翻）
    func flipToPreviousPage() {
        guard currentIndex - 2 >= 0, !isAnimating else { return }
        isAnimating = true
        
        let currentLeftPage = pages[currentIndex]
        let previousRightPage = pages[currentIndex - 1]
        
        // 设置初始状态
        previousRightPage.view.frame = leftPageContainer.bounds
        previousRightPage.view.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        previousRightPage.view.layer.position = CGPoint(x: leftPageContainer.bounds.maxX, y: leftPageContainer.bounds.midY)
        previousRightPage.view.layer.transform = CATransform3DMakeRotation(-.pi / 2, 0, 1, 0)
        leftPageContainer.addSubview(previousRightPage.view)
        
        // 创建翻页动画
        UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseInOut, animations: {
            // 当前左页翻过去
            currentLeftPage.view.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
            currentLeftPage.view.layer.position = CGPoint(x: self.leftPageContainer.bounds.maxX, y: self.leftPageContainer.bounds.midY)
            currentLeftPage.view.layer.transform = CATransform3DMakeRotation(.pi / 2, 0, 1, 0)
            
            // 前一右页翻过来
            previousRightPage.view.layer.transform = CATransform3DIdentity
        }) { _ in
            currentLeftPage.view.removeFromSuperview()
            currentLeftPage.view.layer.transform = CATransform3DIdentity
            self.currentIndex -= 2
            self.goToPagePair(at: self.currentIndex)
            self.isAnimating = false
        }
    }

    private func informPageState(_ index: Int) {
        let role: PageRole 
        if index == 0 {
            role = .cover
        } else if index + 1 == pages.count - 1 {
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
