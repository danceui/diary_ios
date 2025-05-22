import UIKit

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    private var pages: [NotebookPageView] = []
    private var currentIndex: Int = 0
    
    // 笔记本样式配置
    private let pageBackgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1) // 浅紫色
    private let pageControllerBackgroundColor = UIColor(red: 0.76, green: 0.88, blue: 0.77, alpha: 0.5) // 浅绿色
    private let spineShadowColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1).cgColor // 深灰色
    private let spineShadowWidth: CGFloat = 10.0

    // 添加手势识别器
    private var edgeSwipeGestureRecognizer: UIScreenEdgePanGestureRecognizer!
    private var leftEdgeSwipeGestureRecognizer: UIScreenEdgePanGestureRecognizer!
    
    init() {
        // 设置页面间的间距
        let options: [UIPageViewController.OptionsKey: Any] = [
            .spineLocation: UIPageViewController.SpineLocation.mid.rawValue,
            .interPageSpacing: 20.0 // 页面间距
        ]
        
        // 使用双页模式（spineLocation: .mid）和页面间距
        super.init(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: options)
        isDoubleSided = true
    }

    required init?(coder: NSCoder) {
        let options: [UIPageViewController.OptionsKey: Any] = [
            .spineLocation: UIPageViewController.SpineLocation.mid.rawValue,
            .interPageSpacing: 20.0 // 页面间距
        ]
        
        super.init(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: options)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageController()
        setupInitialPages()
        setupGestureRecognizers()
    }
    
    // MARK: - Setup PageController
    private func setupPageController() {
        dataSource = self
        delegate = self
        view.backgroundColor = pageControllerBackgroundColor
        isDoubleSided = true
        
        // 设置书脊阴影效果
        view.layer.shadowColor = spineShadowColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = spineShadowWidth
        view.layer.shadowOpacity = 0.8
    }
    
    private func setupInitialPages() {
        if pages.isEmpty {
            addNewPagePair()
        }
        setViewControllersForCurrentIndex(animated: false)
    }

    // MARK: - Setup GestureRecognizers
    private func setupGestureRecognizers() {
        // 移除默认手势识别器（如果需要）
        for gesture in gestureRecognizers {
            if let edgeGesture = gesture as? UIScreenEdgePanGestureRecognizer {
                view.removeGestureRecognizer(edgeGesture)
            }
        }
        // 添加右侧边缘滑动手势（下一页）
        edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleRightEdgeSwipe(_:)))
        edgeSwipeGestureRecognizer.edges = .right //只识别屏幕右侧边缘的滑动
        view.addGestureRecognizer(edgeSwipeGestureRecognizer)
        
        // 添加左侧边缘滑动手势（上一页）
        leftEdgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleLeftEdgeSwipe(_:)))
        leftEdgeSwipeGestureRecognizer.edges = .left
        view.addGestureRecognizer(leftEdgeSwipeGestureRecognizer)
    }
    
    @objc private func handleRightEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .ended {
            goToNextPage(animated: true)
        }
    }
    
    @objc private func handleLeftEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .ended {
            goToPrevPage(animated: true)
        }
    }
    
    // MARK: - Page Management
    func addNewPagePair(initialData: Data? = nil) {
        let leftPage = NotebookPageView(pageIndex: pages.count, initialData: initialData)
        let rightPage = NotebookPageView(pageIndex: pages.count + 1, initialData: initialData)

        for page in [leftPage, rightPage] {
            page.view.backgroundColor = pageBackgroundColor // 浅紫色
            page.view.layer.borderColor = UIColor.lightGray.cgColor
            page.view.layer.borderWidth = 0.5
            // page.view.layer.shadowColor = UIColor.lightGray.cgColor
            page.view.layer.shadowOffset = CGSize(width: -2, height: 0)
            page.view.layer.shadowRadius = 5
            page.view.layer.shadowOpacity = 0.2
            pages.append(page)
        }
        currentIndex = pages.count - 2 // 指向新左页的索引
        setViewControllersForCurrentIndex(animated: true, direction: .forward)
        print("Add new page #\(currentIndex), #\(currentIndex + 1).")
    }

    func getPageCount() -> Int {
        return pages.count
    }

    func goToNextPage(animated: Bool = true) {
        guard let nextPair = self.pageViewController(self, viewControllersAfter: self.viewControllers ?? []) else { return }
        print("Go to next page pair.")
        setViewControllers(nextPair, direction: .forward, animated: animated)
    }

    func goToPrevPage(animated: Bool = true) {
        guard let prevPair = self.pageViewController(self, viewControllersBefore: self.viewControllers ?? []) else { return }
        print("Go to previous page pair.")
        setViewControllers(prevPair, direction: .reverse, animated: animated)
    }

    // MARK: - Navigation Helpers
    private func setViewControllersForCurrentIndex(animated: Bool, direction: UIPageViewController.NavigationDirection = .forward) {
        guard currentIndex >= 0, currentIndex + 1 < pages.count else { return }
        let leftPage = pages[currentIndex]
        let rightPage = pages[currentIndex + 1]
        setViewControllers([leftPage, rightPage], direction: direction, animated: animated)
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

    // MARK: - 单页配置
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        // 单页模式实现（虽然你使用双页模式，但最好实现这个方法）
        guard let page = viewController as? NotebookPageView,
              let index = pages.firstIndex(of: page),
              index > 0 else {
            return nil
        }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // 单页模式实现
        guard let page = viewController as? NotebookPageView,
              let index = pages.firstIndex(of: page),
              index < pages.count - 1 else {
            return nil
        }
        return pages[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        return .mid
    }

    // MARK: - 双页模式
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllersBefore viewControllers: [UIViewController]) -> [UIViewController]? {
        // 尝试获取当前显示的第一个视图控制器，将其转换为自定义的 NotebookPageView 类型
        guard let page = viewControllers.first as? NotebookPageView,
            // 在 pages 数组中查找这个页面的索引
            let index = pages.firstIndex(of: page) else {
            return nil
        }
        // 计算新的索引
        let newIndex = index - 2
        guard newIndex >= 0 else { return nil }
        return [pages[newIndex], pages[newIndex + 1]]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllersAfter viewControllers: [UIViewController]) -> [UIViewController]? {
        // 尝试获取当前显示的第一个视图控制器，将其转换为自定义的 NotebookPageView 类型
        guard let page = viewControllers.first as? NotebookPageView,
            // 在 pages 数组中查找这个页面的索引
            let index = pages.firstIndex(of: page) else {
            return nil
        }

        // 计算新的索引
        let newIndex = index + 2
        guard newIndex + 1 < pages.count else { return nil }
        return [pages[newIndex], pages[newIndex + 1]]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                        didFinishAnimating finished: Bool,
                        previousViewControllers: [UIViewController],
                        transitionCompleted completed: Bool) {
        guard completed,
            let newLeftPage = viewControllers?.first as? NotebookPageView,
            let index = pages.firstIndex(of: newLeftPage)
        else { return }
        currentIndex = index
    }

    // MARK: - 页面翻转动画定制
    override func setViewControllers(_ viewControllers: [UIViewController]?, 
                                direction: UIPageViewController.NavigationDirection, 
                                animated: Bool, 
                                completion: ((Bool) -> Void)? = nil) {
        guard let viewControllers = viewControllers else {
            super.setViewControllers(nil, direction: direction, animated: false, completion: completion)
            return
        }
        // 禁用交互以防动画过程中用户再次触发翻页
        self.view.isUserInteractionEnabled = false
        // 使用系统翻页动画
        super.setViewControllers(viewControllers, direction: direction, animated: animated) { [weak self] finished in
            completion?(finished)
            self?.view.isUserInteractionEnabled = true
            if let newLeftPage = viewControllers.first as? NotebookPageView,
            let index = self?.pages.firstIndex(of: newLeftPage) {
                self?.currentIndex = index
                self?.updatePageShadows()
            }
        }
    }

    // MARK: - Exports
    func exportAllDrawings() -> [Data] {
        return pages.map { $0.exportDrawing() }
    }

    // MARK: - Undo/Redo
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