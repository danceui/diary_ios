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
        addNewPage()
    }

    // MARK: - Setup Page View Controller
    private func setupPageViewController() {
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
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
        scrollToPage(index: index, animated: true)
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
        currentPageIndex = index
        pageViewController.setViewControllers([pages[index]], direction: direction, animated: animated, completion: nil)
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

    // MARK: - Page View Controller Data Source
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let current = viewController as? NotebookPageView,
              let index = pages.firstIndex(of: current),
              index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let current = viewController as? NotebookPageView,
              let index = pages.firstIndex(of: current),
              index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }
}
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
