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

    // MARK: - Flip Animation
    private func performPageFlipAnimation(to index: Int) {
        guard index >= 2, index + 1 < pages.count else { return }
        guard !isAnimating else { return }
        isAnimating = true

        let currentRightPage = pages[index - 1]
        let nextLeftPage = pages[index]
        let nextRightPage = pages[index + 1]

        // 添加透视变换
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 1000

        // 创建翻页容器
        let flipContainer = UIView(frame: rightPageContainer.frame)
        flipContainer.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        flipContainer.layer.position = CGPoint(x: rightPageContainer.frame.minX, y: rightPageContainer.frame.midY)
        flipContainer.layer.transform = transform
        view.addSubview(flipContainer)

        // 背面：下一页左页快照（旋转180度）
        let backSnapshot = nextLeftPage.view.snapshotView(afterScreenUpdates: true)!
        backSnapshot.frame = flipContainer.bounds
        backSnapshot.layer.transform = CATransform3DRotate(CATransform3DIdentity, .pi, 0, 1, 0) // 旋转 180 度作为背面
        flipContainer.addSubview(backSnapshot)

        // 正面：当前右页快照
        let frontSnapshot = currentRightPage.view.snapshotView(afterScreenUpdates: true)!
        frontSnapshot.frame = flipContainer.bounds
        flipContainer.addSubview(frontSnapshot)
        
        // 准备右页
        nextRightPage.view.frame = rightPageContainer.bounds
        nextRightPage.view.isHidden = true
        rightPageContainer.subviews.forEach { $0.removeFromSuperview() }
        rightPageContainer.addSubview(nextRightPage.view)
        currentRightPage.view.isHidden = true

        UIView.animateKeyframes(withDuration: 1.0, delay: 0, options: .calculationModeCubic, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                flipContainer.layer.transform = CATransform3DRotate(transform, -.pi/2, 0, 1, 0)
                frontSnapshot.isHidden = true
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6) {
                nextRightPage.view.isHidden = false
                flipContainer.layer.transform = CATransform3DRotate(transform, -.pi, 0, 1, 0)
            }
        }, completion: { _ in
            // 清理工作
            flipContainer.removeFromSuperview()
            currentRightPage.view.isHidden = false
            
            // 替换左页
            self.leftPageContainer.subviews.forEach { $0.removeFromSuperview() }
            nextLeftPage.view.frame = self.leftPageContainer.bounds
            self.leftPageContainer.addSubview(nextLeftPage.view)

            // 更新页面
            self.currentIndex = index
            self.applyPageShadows()
            self.notifyPageState(index)
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
