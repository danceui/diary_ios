import UIKit

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    private var pages: [NotebookPageView] = []
    private var currentIndex: Int = -1
    
    // 笔记本样式配置
    private let pageBackgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 0.50) // 浅紫色
    private let pageControllerBackgroundColor = UIColor(red: 0.76, green: 0.88, blue: 0.77, alpha: 0.50) // 浅绿色
    private let spineShadowColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.5).cgColor // 深灰色
    private let spineShadowWidth: CGFloat = 10.0
    
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageController()
        setupInitialPages()
    }
    
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
        if currentIndex == -1 {
            currentIndex = 0
            setViewControllersForCurrentIndex(animated: false)
        }
        print("Add new page pair.")
    }

    // func getPage(at index: Int) -> NotebookPageView? {
    //     guard index >= 0 && index < pages.count else { return nil }
    //     return pages[index]
    // }

    func getPageCount() -> Int {
        return pages.count
    }

    func goToNextPage(animated: Bool = true) {
        guard let nextPair = self.pageViewController(self, viewControllersAfter: self.viewControllers ?? []) else { return }
        print("Go to next pair.")
        setViewControllers(nextPair, direction: .forward, animated: animated)
    }

    func goToPrevPage(animated: Bool = true) {
        guard let prevPair = self.pageViewController(self, viewControllersBefore: self.viewControllers ?? []) else { return }
        print("Go to previous pair.")
        setViewControllers(prevPair, direction: .reverse, animated: animated)
    }

    // MARK: - Navigation Helpers
    private func setViewControllersForCurrentIndex(animated: Bool, direction: UIPageViewController.NavigationDirection = .forward) {
        guard currentIndex >= 0, currentIndex + 1 < pages.count else { return }
        let leftPage = pages[currentIndex]
        let rightPage = pages[currentIndex + 1]
        setViewControllers([leftPage, rightPage], direction: direction, animated: animated) { [weak self] _ in
            self?.updatePageShadows()
        }
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

    // MARK: - 单页配置 (已注释/返回nil)
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil // or a placeholder
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nil // or a placeholder
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        // 横屏时也保持双页模式
        return .mid
    }
    
    // MARK: - 双页
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
        updatePageShadows()
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
            
            // 更新当前索引和阴影
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