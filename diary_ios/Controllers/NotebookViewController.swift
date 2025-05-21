import UIKit

@available(iOS 16.0, *)
class NotebookViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    private var pages: [NotebookPageView] = []
    private var currentIndex: Int = 0
    
    // 笔记本样式配置
    private let pageBackgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0) // 米黄色纸张
    private let spineShadowColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.5).cgColor
    private let spineShadowWidth: CGFloat = 10.0
    
    init() {
        // 设置页面间的间距
        let options: [UIPageViewController.OptionsKey: Any] = [
            .spineLocation: UIPageViewController.SpineLocation.mid.rawValue,
            .interPageSpacing: 20.0 // 页面间距
        ]
        
        // 使用双页模式（spineLocation: .mid）和页面间距
        super.init(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: options)
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
        view.backgroundColor = .systemGray6
        isDoubleSided = true
        
        // 设置书脊阴影效果
        view.layer.shadowColor = spineShadowColor
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = spineShadowWidth
        view.layer.shadowOpacity = 0.5
    }
    
    private func setupInitialPages() {
        if pages.isEmpty {
            addNewPage()
            addNewPage() // 一开始显示双页
        }
        setViewControllersForCurrentIndex(animated: false)
    }

    // MARK: - Page Management
    func addNewPage(initialData: Data? = nil) {
        let page = NotebookPageView(pageIndex: pages.count, initialData: initialData)
        page.view.backgroundColor = pageBackgroundColor
        page.view.layer.borderColor = UIColor.lightGray.cgColor
        page.view.layer.borderWidth = 0.5
        page.view.layer.shadowColor = UIColor.black.cgColor
        page.view.layer.shadowOffset = CGSize(width: -2, height: 0)
        page.view.layer.shadowRadius = 5
        page.view.layer.shadowOpacity = 0.2
        pages.append(page)
    }

    func getPage(at index: Int) -> NotebookPageView? {
        guard index >= 0 && index < pages.count else { return nil }
        return pages[index]
    }

    func getPageCount() -> Int {
        return pages.count
    }
    
    func goToPage(index: Int, animated: Bool = true) {
        guard index >= 0 && index < pages.count - 1 else { return }
        
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        currentIndex = index
        setViewControllersForCurrentIndex(animated: animated, direction: direction)
    }

    // MARK: - Navigation Helpers
    private func setViewControllersForCurrentIndex(animated: Bool, direction: UIPageViewController.NavigationDirection = .forward) {
        guard currentIndex + 1 < pages.count else { return }
        
        let leftPage = pages[currentIndex]
        let rightPage = pages[currentIndex + 1]
        setViewControllers([leftPage, rightPage], direction: direction, animated: animated) { [weak self] _ in
            self?.updatePageShadows()
        }
    }
    
    private func updatePageShadows() {
        // 更新页面阴影效果，增强立体感
        pages.enumerated().forEach { index, page in
            if index == currentIndex || index == currentIndex + 1 {
                // 当前可见页面阴影较弱
                page.view.layer.shadowOpacity = 0.1
            } else {
                // 其他页面阴影较强，模拟堆叠效果
                page.view.layer.shadowOpacity = 0.3
            }
        }
    }

    // MARK: - Data Source
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? NotebookPageView,
              let index = pages.firstIndex(of: page) else {
            return nil
        }
        
        // 双页模式，每次翻两页
        if index == 0 {
            return nil // 已经到第一页
        } else if index == 1 {
            return pages[0] // 特殊处理第二页返回第一页
        } else {
            return pages[index - 2]
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? NotebookPageView,
              let index = pages.firstIndex(of: page) else {
            return nil
        }
        
        // 双页模式，每次翻两页
        if index + 2 >= pages.count {
            return nil // 已经到最后一页
        } else {
            return pages[index + 2]
        }
    }

    // MARK: - 双页配置
    func pageViewController(_ pageViewController: UIPageViewController,
                            spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        // 横屏时也保持双页模式
        return .mid
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                        viewControllerBefore viewController: UIViewController) -> [UIViewController]? {
        guard let page = viewController as? NotebookPageView,
            let index = pages.firstIndex(of: page) else {
            return nil
        }

        let newIndex = index - 2
        guard newIndex >= 0 else { return nil }

        let left = pages[newIndex]
        let right = pages[newIndex + 1]
        return [left, right].compactMap { $0 }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> [UIViewController]? {
        guard let page = viewController as? NotebookPageView,
            let index = pages.firstIndex(of: page) else {
            return nil
        }

        let newIndex = index + 2
        guard newIndex < pages.count else { return nil }

        let left = pages[newIndex]
        let right = pages[newIndex + 1]
        return [left, right].compactMap { $0 }
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
    
    // MARK: - 页面翻转动画定制
    override func setViewControllers(_ viewControllers: [UIViewController]?, 
                                   direction: UIPageViewController.NavigationDirection, 
                                   animated: Bool, 
                                   completion: ((Bool) -> Void)? = nil) {
        if animated {
            // 自定义翻页动画曲线
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
                super.setViewControllers(viewControllers, direction: direction, animated: false, completion: completion)
            })
        } else {
            super.setViewControllers(viewControllers, direction: direction, animated: false, completion: completion)
        }
    }
}