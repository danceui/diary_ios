import UIKit

protocol NotebookSpreadViewControllerDelegate: AnyObject {
    func notebookSpreadViewController(_ controller: NotebookSpreadViewController, didUpdatePageRole role: PageRole)
}

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIPageViewController {
    private var pages: [NotebookPageViewController] = []
    private var currentIndex: Int = 0
    weak var pageDelegate: NotebookSpreadViewControllerDelegate?
    
    init() {
        // 设置页面间的间距
        let options: [UIPageViewController.OptionsKey: Any] = [
            .spineLocation: UIPageViewController.SpineLocation.mid.rawValue,
        ]

        super.init(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: options)
        isDoubleSided = true
    }

    required init?(coder: NSCoder) {
        let options: [UIPageViewController.OptionsKey: Any] = [
            .spineLocation: UIPageViewController.SpineLocation.mid.rawValue,
        ]
        
        super.init(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: options)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageController()
        setupInitialPages()
    }
    
    private func setupPageController() {
        dataSource = self
        delegate = self
        isDoubleSided = true
        // 阴影（轻微悬浮感）
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 2, height: 1)
        view.layer.shadowRadius = 5
    }
    
    private func setupInitialPages() {
        if pages.isEmpty {
            pages = [
                NotebookPageViewController(pageIndex: 0, role: .empty),
                NotebookPageViewController(pageIndex: 1, role: .cover),
                NotebookPageViewController(pageIndex: 2, role: .back),
                NotebookPageViewController(pageIndex: 3, role: .empty)
            ]
            setupCoverAndBackAppearance()
            currentIndex = 0
            setViewControllers(at: currentIndex, direction: .forward, animated: false)
        }
    }
    

    func addNewPagePair(initialData: Data? = nil) {
        // 不允许在最后一页之后添加页面
        guard currentIndex + 2 < pages.count else {
            print("Cannot add new page pair at the end.")
            return
        }

        let insertIndex = currentIndex + 2
        let leftPage = NotebookPageViewController(pageIndex: pages.count, initialData: initialData)
        let rightPage = NotebookPageViewController(pageIndex: pages.count + 1, initialData: initialData)

        for page in [leftPage, rightPage] {
            page.view.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1) // 浅紫色
            page.view.layer.borderColor = UIColor.lightGray.cgColor
            page.view.layer.borderWidth = 0.5
            page.view.layer.shadowColor = UIColor.lightGray.cgColor
            page.view.layer.shadowOffset = CGSize(width: -2, height: 0)
            page.view.layer.shadowRadius = 5
            page.view.layer.shadowOpacity = 0.2
        }
        pages.insert(contentsOf: [leftPage, rightPage], at: insertIndex)
        currentIndex = insertIndex
        setViewControllers(at: currentIndex, direction: .forward, animated: true)
        addPageEdgeEffect(
            to: leftPage.view,
            pageIndex: currentIndex,
            pageCount: pages.count,
            isLeftPage: true
        )
        addPageEdgeEffect(
            to: rightPage.view,
            pageIndex: currentIndex + 1,
            pageCount: pages.count,
            isLeftPage: false
        )
        print("Insert page pair #\(currentIndex), #\(currentIndex + 1).")
    }

    func getPageCount() -> Int {
        return pages.count
    }
    
    // MARK: - Notebook Appearance
    private func setupCoverAndBackAppearance(){
        let coverPage = pages[1]
        coverPage.view.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1)
        let backPage = pages[2]
        backPage.view.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1)
    }

    private func updatePageShadows() {
        pages.enumerated().forEach { index, page in
            let isCurrent = (index == currentIndex || index == currentIndex + 1)
            
            UIView.animate(withDuration: 0.3) {
                page.view.layer.shadowOpacity = isCurrent ? 0.1 : 0.3
                page.view.layer.shadowOffset = isCurrent ? CGSize(width: -2, height: 0) : CGSize(width: -5, height: 2)
                page.view.layer.shadowRadius = isCurrent ? 5 : 8
            }
        }
    }

    func addPageEdgeEffect(to view: UIView, pageIndex: Int, pageCount: Int, isLeftPage: Bool) {
        // 可书写页数
        let edgeCount = (pageCount - 4) / 2
        let leftStripeCount = isLeftPage ? pageIndex / 2 : (pageIndex - 1) / 2
        let rightStripeCount = edgeCount - leftStripeCount

        // 添加条纹
        if isLeftPage {
            addStripes(to: view, stripeCount: leftStripeCount, isLeftPage: true)
        } else {
            addStripes(to: view, stripeCount: rightStripeCount, isLeftPage: false)
        }
        // // 配置参数
        // let maxStripes = 6
        // let stripeSpacing: CGFloat = 2.0
        // let stripeWidth: CGFloat = 15.0
        // let verticalInset: CGFloat = 8.0

        // // 计算线性位置比例 (0.0 - 1.0)
        // let positionRatio = isLeftPage
        //     ? CGFloat(pageIndex) / CGFloat(max(pageCount - 1, 1))
        //     : 1.0 - CGFloat(pageIndex) / CGFloat(max(pageCount - 1, 1))

        // print("Position ratio for page \(pageIndex): \(positionRatio)")
        // // 线性映射条纹数量
        // let stripeCount = Int(positionRatio * CGFloat(maxStripes))
    }

    func addStripes(to view: UIView, stripeCount: Int, isLeftPage: Bool) {
        // 清除旧的效果
        view.subviews.filter { $0.tag == 9999 }.forEach { $0.removeFromSuperview() }
        guard stripeCount > 0 else { return }
        
        let stripeWidth: CGFloat = 15.0
        let stripeSpacing: CGFloat = 2.0
        let verticalInset: CGFloat = 8.0

        if isLeftPage {
            for i in 0..<stripeCount {
                let stripe = UIView()
                stripe.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1)
                stripe.layer.cornerRadius = 2
                stripe.layer.borderColor = UIColor.black.cgColor
                stripe.layer.borderWidth = 1
                
                let xPosition = -CGFloat(i) * stripeSpacing
                stripe.frame = CGRect(x: xPosition, y: verticalInset, width: stripeWidth, height: view.bounds.height - verticalInset * 2)
                stripe.tag = 9999 // 用于标记条纹视图
                
                view.insertSubview(stripe, at: 0) // 添加到最底层
            }
        } else {

        }
    }

    func setViewControllers(at index: Int,
                                direction: UIPageViewController.NavigationDirection, 
                                animated: Bool, 
                                completion: ((Bool) -> Void)? = nil) {
        guard index >= 0, index + 1 < pages.count else { return }
        let leftPage = pages[index]
        let rightPage = pages[index + 1]

        self.view.isUserInteractionEnabled = false
        print("Setting view controllers #\(index).")
        super.setViewControllers([leftPage, rightPage], direction: direction, animated: animated) { [weak self] finished in
            completion?(finished)
            self?.view.isUserInteractionEnabled = true
            self?.currentIndex = index
            self?.updatePageShadows()
            self?.syncPageState(index)
        }
    }

    private func syncPageState(_ index: Int) {
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
        // 同时撤销左右两页的操作
        if currentIndex < pages.count {
            pages[currentIndex].undo()
        }
        if currentIndex + 1 < pages.count {
            pages[currentIndex + 1].undo()
        }
    }

    func redo() {
        // 同时重做左右两页的操作
        if currentIndex < pages.count {
            pages[currentIndex].redo()
        }
        if currentIndex + 1 < pages.count {
            pages[currentIndex + 1].redo()
        }
    }
}

extension NotebookSpreadViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    // 告诉 UIPageViewController 在当前页面之前显示哪个视图控制器
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? NotebookPageViewController,
              let index = pages.firstIndex(of: page), index > 0 else { return nil }
        return pages[index - 1]
    }

    // 告诉 UIPageViewController 在当前页面之后显示哪个视图控制器
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? NotebookPageViewController,
              let index = pages.firstIndex(of: page), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }

    // 告诉 UIPageViewController 双页模式时在当前页面之前显示哪些视图控制器
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllersBefore viewControllers: [UIViewController]) -> [UIViewController]? {
        guard let page = viewControllers.first as? NotebookPageViewController,
            let index = pages.firstIndex(of: page) else { return nil }
        let newIndex = index - 2
        guard newIndex >= 0 else { return nil }
        return [pages[newIndex], pages[newIndex + 1]]
    }

    // 告诉 UIPageViewController 双页模式时在当前页面之后显示哪些视图控制器
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllersAfter viewControllers: [UIViewController]) -> [UIViewController]? {
        guard let page = viewControllers.first as? NotebookPageViewController,
            let index = pages.firstIndex(of: page) else { return nil }
        let newIndex = index + 2
        guard newIndex + 1 < pages.count else { return nil }
        return [pages[newIndex], pages[newIndex + 1]]
    }

    // 设置页面翻转的方向
    func pageViewController(_ pageViewController: UIPageViewController,
                            spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        return .mid
    }
    
    // 告诉 UIPageViewController 在翻页动画完成后需要执行的操作
    func pageViewController(_ pageViewController: UIPageViewController,
                        didFinishAnimating finished: Bool,
                        previousViewControllers: [UIViewController],
                        transitionCompleted completed: Bool) {
        guard completed,
            let newLeftPage = viewControllers?.first as? NotebookPageViewController,
            let index = pages.firstIndex(of: newLeftPage) else { return }
        currentIndex = index
        print("Flipped to page pair #\(currentIndex), #\(currentIndex + 1).")
        syncPageState(index)
        updatePageShadows()
    } 
}
