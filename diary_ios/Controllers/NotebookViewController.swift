import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    // MARK: - Properties
    private var pages: [NotebookPageView] = []
    private var currentPageIndex: Int = 0


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        if pages.isEmpty {
            addNewPage()
        } else {
            scrollToPage(index: currentPageIndex, animated: false)
        }
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
        let newPage = pages[index]
        let oldPage = children.first
        addChild(newPage)
        newPage.view.frame = view.bounds
        if let oldPage = oldPage, animated {
            let direction: UIView.AnimationOptions = index > currentPageIndex
                ? .transitionFlipFromRight
                : .transitionFlipFromLeft

            transition(from: oldPage, to: newPage, duration: 0.5, options: [direction, .showHideTransitionViews]) { 
                newPage.didMove(toParent: self)
                oldPage.willMove(toParent: nil)
                oldPage.removeFromParent()
                self.currentPageIndex = index
            }
        } else {
            view.addSubview(newPage.view)
            newPage.didMove(toParent: self)
            currentPageIndex = index
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

    // 控制翻页起始点
    func pageViewController(_ pageViewController: UIPageViewController, 
                          spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        return .min
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
