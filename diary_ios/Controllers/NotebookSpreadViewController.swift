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
            applyStackEffect() 
        }
    }
    

    func addNewPagePair(initialData: Data? = nil) {
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
        print("Insert page pair #\(currentIndex), #\(currentIndex + 1).")
        applyStackEffect() 
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

    private func applyStackEffect() {
        for (index, page) in pages.enumerated() {
            if index == currentIndex || index == currentIndex + 1 {
                page.view.layer.transform = CATransform3DIdentity
            } else {
                // 偏移方向（左页向左偏移，右页向右偏移）
                let isLeftSide = index % 2 == 0
                let depthOffset: CGFloat = 10.0 // 页面厚度感
                let xOffset: CGFloat = isLeftSide ? -depthOffset : depthOffset
                let zOffset: CGFloat = -CGFloat(abs(currentIndex - index)) * 5.0

                var transform = CATransform3DIdentity
                transform.m34 = -1.0 / 500.0 // 透视效果
                transform = CATransform3DTranslate(transform, xOffset, 0, zOffset)

                page.view.layer.transform = transform
            }
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
            self?.informPageState(index)
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

extension NotebookSpreadViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? NotebookPageViewController,
              let index = pages.firstIndex(of: page), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? NotebookPageViewController,
              let index = pages.firstIndex(of: page), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllersBefore viewControllers: [UIViewController]) -> [UIViewController]? {
        guard let page = viewControllers.first as? NotebookPageViewController,
            let index = pages.firstIndex(of: page) else { return nil }
        let newIndex = index - 2
        guard newIndex >= 0 else { return nil }
        return [pages[newIndex], pages[newIndex + 1]]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllersAfter viewControllers: [UIViewController]) -> [UIViewController]? {
        guard let page = viewControllers.first as? NotebookPageViewController,
            let index = pages.firstIndex(of: page) else { return nil }
        let newIndex = index + 2
        guard newIndex + 1 < pages.count else { return nil }
        return [pages[newIndex], pages[newIndex + 1]]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        return .mid
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                        didFinishAnimating finished: Bool,
                        previousViewControllers: [UIViewController],
                        transitionCompleted completed: Bool) {
        guard completed,
            let newLeftPage = viewControllers?.first as? NotebookPageViewController,
            let index = pages.firstIndex(of: newLeftPage) else { return }
        currentIndex = index
        informPageState(index)
        print("Flipped to page pair #\(currentIndex), #\(currentIndex + 1).")
        applyStackEffect() 
    } 
}
