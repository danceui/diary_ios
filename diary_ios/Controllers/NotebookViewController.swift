import UIKit
import PencilKit
import RiveRuntime

@available(iOS 16.0, *)
class NotebookViewController: UIViewController {
    
    // MARK: - UI & State
    private var pageViewController: UIPageViewController!
    private var pages: [NotebookPageView] = []
    private var currentPageIndex: Int = 0
    private var animator: FlipAnimator!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupPageViewController()
        animator = FlipAnimator(container: view)
        if pages.isEmpty {
            addNewPage()
        }
    }

    // MARK: - Setup
    private func setupPageViewController() {
        let options: [UIPageViewController.OptionsKey: Any] = [
            .spineLocation: UIPageViewController.SpineLocation.min.rawValue
        ]
        pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: options
        )
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.view.backgroundColor = .clear

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
        let newPage = NotebookPageView(pageIndex: pages.count, initialData: initialData)
        pages.append(newPage)
        scrollToPage(index: pages.count - 1, animated: pages.count > 1)
    }

    func getPage(at index: Int) -> NotebookPageView? {
        return pages[safe: index]
    }

    func getPageCount() -> Int {
        return pages.count
    }

    // MARK: - Navigation
    func scrollToPage(index: Int, animated: Bool) {
        guard pages.indices.contains(index) else { return }

        let direction: UIPageViewController.NavigationDirection = index > currentPageIndex ? .forward : .reverse
        pageViewController.setViewControllers(
            [pages[index]],
            direction: direction,
            animated: animated
        ) { [weak self] _ in
            guard let self = self,
                  let currentVC = self.pageViewController.viewControllers?.first as? NotebookPageView,
                  let newIndex = self.pages.firstIndex(of: currentVC) else { return }
            self.currentPageIndex = newIndex
        }
    }

    func goToNextPage() {
        let nextIndex = currentPageIndex + 1
        guard nextIndex < pages.count else { return }

        animator.playFlip(direction: "flipRight") {
            self.scrollToPage(index: nextIndex, animated: false)
        }
    }

    func goToPrevPage() {
        let prevIndex = currentPageIndex - 1
        guard prevIndex >= 0 else { return }

        animator.playFlip(direction: "flipLeft") {
            self.scrollToPage(index: prevIndex, animated: false)
        }
    }

    // MARK: - Export
    func exportAllDrawings() -> [Data] {
        return pages.map { $0.exportDrawing() }
    }

    // MARK: - Undo / Redo
    func undo() {
        pages[safe: currentPageIndex]?.undo()
    }

    func redo() {
        pages[safe: currentPageIndex]?.redo()
    }
}

// MARK: - PageViewController Data Source & Delegate
@available(iOS 16.0, *)
extension NotebookViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
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

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        if completed,
           let currentVC = pageViewController.viewControllers?.first as? NotebookPageView,
           let index = pages.firstIndex(of: currentVC) {
            currentPageIndex = index
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        return .min
    }
}

// MARK: - Safe Array Access Extension
private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
