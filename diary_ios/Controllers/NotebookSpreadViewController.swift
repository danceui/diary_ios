import UIKit

@available(iOS 16.0, *)
class NotebookSpreadViewController: UIPageViewController {
    private var pages: [NotebookPageViewController] = []
    private var currentIndex: Int = 0
    
    init() {
        // 设置页面间的间距
        let options: [UIPageViewController.OptionsKey: Any] = [
            .spineLocation: UIPageViewController.SpineLocation.mid.rawValue,
            .interPageSpacing: 20.0 // 页面间距
        ]

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
    }
    
    private func setupPageController() {
        dataSource = self
        delegate = self
        isDoubleSided = true
        view.backgroundColor = UIColor(red: 0.76, green: 0.88, blue: 0.77, alpha: 0.5) // 浅绿色
        view.layer.shadowColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1).cgColor // 深灰色
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10.0
        view.layer.shadowOpacity = 0.8
    }
    
    private func setupInitialPages() {
        if pages.isEmpty {
            let blankCover = NotebookPageViewController(pageIndex: 0, role: .empty) // 空页
            let coverPage = NotebookPageViewController(pageIndex: 1, role: .cover)
            let backPage = NotebookPageViewController(pageIndex: 2, role: .back)
            let blankBack = NotebookPageViewController(pageIndex: 3, role: .empty) // 空页
            pages.append(blankCover)
            for page in [coverPage, backPage] {
                pages.append(page)
                page.view.backgroundColor = UIColor(red: 0.83, green: 0.77, blue: 0.98, alpha: 1) // 浅紫色
                page.view.layer.borderColor = UIColor.lightGray.cgColor
                page.view.layer.borderWidth = 0.5
                page.view.layer.shadowColor = UIColor.lightGray.cgColor
                page.view.layer.shadowOffset = CGSize(width: -2, height: 0)
                page.view.layer.shadowRadius = 5
                page.view.layer.shadowOpacity = 0.2
            }
            pages.append(blankBack)
            currentIndex = 0
            setViewControllers(at: currentIndex, direction: .forward, animated: false)
        }
    }
    
    func addNewPagePair(initialData: Data? = nil) {
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
        print("Insert page pair #\(currentIndex), #\(currentIndex + 1).")
        setViewControllers(at: currentIndex, direction: .forward, animated: true)
    }

    func getPageCount() -> Int {
        return pages.count
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

    func setViewControllers(at index: Int,
                                direction: UIPageViewController.NavigationDirection, 
                                animated: Bool, 
                                completion: ((Bool) -> Void)? = nil) {
        guard index >= 0, index + 1 < pages.count else {
            print("Invalid page index: \(index)")
            return
        }

        let leftPage = pages[index]
        let rightPage = pages[index + 1]
        print("setViewControllers at \(index) and \(index + 1).")
        // 禁用交互以防动画过程中用户再次触发翻页
        self.view.isUserInteractionEnabled = false
        // 使用系统翻页动画
        super.setViewControllers([leftPage, rightPage], direction: direction, animated: animated) { [weak self] finished in
            completion?(finished)
            self?.view.isUserInteractionEnabled = true
            self?.currentIndex = index
            self?.updatePageShadows()
            self?.syncPageState(index)
        }
    }

    private func syncPageState(_ index: Int) {
        print("syncPageState at \(index).")
        currentIndex = index
        updatePageShadows()

        if index == 0 {
            NotificationCenter.default.post(name: .notebookPageIsCover, object: nil)
        } else if index + 1 == pages.count - 1 {
            NotificationCenter.default.post(name: .notebookPageIsBack, object: nil)
        } else {
            NotificationCenter.default.post(name: .notebookPageIsNormal, object: nil)
        }
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

extension NotebookSpreadViewController: UIPageViewControllerDataSource {
    // 告诉 UIPageViewController 在当前页面之前显示哪个视图控制器
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? NotebookPageViewController,
              let index = pages.firstIndex(of: page),
              index > 0 else {
            return nil
        }
        return pages[index - 1]
    }

    // 告诉 UIPageViewController 在当前页面之后显示哪个视图控制器
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? NotebookPageViewController,
              let index = pages.firstIndex(of: page),
              index < pages.count - 1 else {
            return nil
        }
        return pages[index + 1]
    }

    // 设置页面翻转的方向
    func pageViewController(_ pageViewController: UIPageViewController,
                            spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        return .mid
    }

    // 告诉 UIPageViewController 双页模式时在当前页面之前显示哪些视图控制器
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllersBefore viewControllers: [UIViewController]) -> [UIViewController]? {
        guard let page = viewControllers.first as? NotebookPageViewController,
            let index = pages.firstIndex(of: page) else {
            return nil
        }
        let newIndex = index - 2
        guard newIndex >= 0 else { return nil }
        return [pages[newIndex], pages[newIndex + 1]]
    }

    // 告诉 UIPageViewController 双页模式时在当前页面之后显示哪些视图控制器
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllersAfter viewControllers: [UIViewController]) -> [UIViewController]? {
        guard let page = viewControllers.first as? NotebookPageViewController,
            let index = pages.firstIndex(of: page) else {
            return nil
        }
        let newIndex = index + 2
        guard newIndex + 1 < pages.count else { return nil }
        return [pages[newIndex], pages[newIndex + 1]]
    }
}

extension NotebookSpreadViewController: UIPageViewControllerDelegate {
    // 告诉 UIPageViewController 在翻页动画完成后需要执行的操作
    func pageViewController(_ pageViewController: UIPageViewController,
                        didFinishAnimating finished: Bool,
                        previousViewControllers: [UIViewController],
                        transitionCompleted completed: Bool) {
        guard completed,
            let newLeftPage = viewControllers?.first as? NotebookPageViewController,
            let index = pages.firstIndex(of: newLeftPage)
        else { return }
        currentIndex = index
        print("pageViewController finished. Go to page pair #\(currentIndex), #\(currentIndex + 1).")
        updatePageShadows()
        syncPageState(index)
    } 
}