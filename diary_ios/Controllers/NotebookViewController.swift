import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    // MARK: - Properties
    private var pageViewController: UIPageViewController!
    private var pages: [NotebookPageView] = []
    private var currentPageIndex: Int = 0


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupPageViewController()
        if pages.isEmpty {
            addNewPage()
        }
    }

    // MARK: - Setup PageViewController
    private func setupPageViewController() {
        pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.min.rawValue]
        )
        pageViewController.dataSource = self
        pageViewController.delegate = self

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        pageViewController.didMove(toParent: self)
    }

    // MARK: - Page Management
    func addNewPage(initialData: Data? = nil) {
        let index = pages.count
        let page = NotebookPageView(pageIndex: index, initialData: initialData)
        pages.append(page)
        scrollToPage(index: index, animated: pages.count == 1 ? false : true)
    }

    func getPage(at index: Int) -> NotebookPageView? {
        guard index >= 0 && index < pages.count else { return nil }
        return pages[index]
    }

    func getPageCount() -> Int {
        return pages.count
    }

    // MARK: - Page Navigation
    func scrollToPage(index: Int, animated: Bool) {
        guard index >= 0 && index < pages.count else { return }
        let direction: UIPageViewController.NavigationDirection = index > currentPageIndex ? .forward : .reverse
        pageViewController.setViewControllers(
            [pages[index]],
            direction: direction,
            animated: animated
        ) { [weak self] _ in
            // 在动画完成后安全更新索引
            guard let self = self,
                let currentVC = self.pageViewController.viewControllers?.first as? NotebookPageView,
                let newIndex = self.pages.firstIndex(of: currentVC) else { return }
            self.currentPageIndex = newIndex
        }
    }

    func goToNextPage() {
        scrollToPage(index: min(currentPageIndex + 1, pages.count - 1), animated: true)
    }

    func goToPrevPage() {
        scrollToPage(index: max(currentPageIndex - 1, 0), animated: true)
    }

    // MARK: - Exports
    func exportAllDrawings() -> [Data] {
        return pages.map { $0.exportDrawing() }
    }

    // MARK: - Undo/Redo
    func undo() {
        pages[safe: currentPageIndex]?.undo()
    }

    func redo() {
        pages[safe: currentPageIndex]?.redo()
    }

    // MARK: - PageViewController Data Source
    // 获取前一页
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let current = viewController as? NotebookPageView,
              let index = pages.firstIndex(of: current),
              index > 0 else { return nil }
        return pages[index - 1]
    }

    // 获取后一页
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let current = viewController as? NotebookPageView,
              let index = pages.firstIndex(of: current),
              index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }

    // 页面切换动画完成时调用（处理手势滑动的情况）
    func pageViewController(_ pageViewController: UIPageViewController, 
                           didFinishAnimating finished: Bool,
                           previousViewControllers: [UIViewController], 
                           transitionCompleted completed: Bool) {
        // 只有真正完成了页面切换才更新索引
        if completed,
           let currentVC = pageViewController.viewControllers?.first as? NotebookPageView,
           let currentIndex = pages.firstIndex(of: currentVC) {
            currentPageIndex = currentIndex
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
