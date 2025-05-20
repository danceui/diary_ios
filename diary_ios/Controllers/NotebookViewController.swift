import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    // MARK: - Properties
    private var pageViewController: UIPageViewController!
    private var pages: [NotebookPageView] = []
    private var currentPageIndex: Int = 0
    private let spineWidth: CGFloat = 12
    private var shadowView: UIView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotebookAppearance()
        setupPageViewController()
        if pages.isEmpty {
            addNewPage()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shadowView?.frame = view.bounds
        shadowView?.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
    }

    // MARK: - Appearance
    private func setupNotebookAppearance() {
        view.backgroundColor = .yellow.withAlphaComponent(0.1)
        let spineShadow = CALayer()
        spineShadow.frame = CGRect(x: view.bounds.midX - spineWidth / 2, y: 0, width: spineWidth, height: view.bounds.height)
        spineShadow.backgroundColor = UIColor.clear.cgColor
        spineShadow.shadowColor = UIColor.black.cgColor
        spineShadow.shadowOffset = .zero
        spineShadow.shadowRadius = 8
        spineShadow.shadowOpacity = 0.2
        view.layer.addSublayer(spineShadow)
    }

    // MARK: - Page View Controller Setup
    private func setupPageViewController() {
        let options: [UIPageViewController.OptionsKey: Any] = [
            .spineLocation: UIPageViewController.SpineLocation.min.rawValue,
            .interPageSpacing: 20
        ]

        pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: options
        )
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.view.backgroundColor = .clear
        addPageShadowEffects()

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

    private func addPageShadowEffects() {
        let shadow = UIView()
        shadow.isUserInteractionEnabled = false
        shadow.layer.shadowColor = UIColor.black.cgColor
        shadow.layer.shadowOffset = .zero
        shadow.layer.shadowRadius = 10
        shadow.layer.shadowOpacity = 0.15
        view.insertSubview(shadow, aboveSubview: pageViewController.view)
        shadowView = shadow
    }

    // MARK: - Page Management
    func addNewPage(initialData: Data? = nil) {
        let index = pages.count
        let page = NotebookPageView(pageIndex: index, initialData: initialData)
        pages.append(page)
        scrollToPage(index: index, animated: pages.count > 1)
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
        let targetPage = pages[index]
        currentPageIndex = index
        pageViewController.setViewControllers([targetPage], direction: direction, animated: animated) { [weak self] _ in
            self?.updateSpineAppearance()
            self?.preloadAdjacentPages()
        }
    }

    func goToNextPage() {
        scrollToPage(index: min(currentPageIndex + 1, pages.count - 1), animated: true)
    }

    func goToPrevPage() {
        scrollToPage(index: max(currentPageIndex - 1, 0), animated: true)
    }

    // MARK: - Export
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
    func pageViewController(_ pvc: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
        guard let current = vc as? NotebookPageView, let index = pages.firstIndex(of: current), index > 0 else {
            return nil
        }
        return pages[index - 1]
    }

    func pageViewController(_ pvc: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
        guard let current = vc as? NotebookPageView, let index = pages.firstIndex(of: current), index < pages.count - 1 else {
            return nil
        }
        return pages[index + 1]
    }

    func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let currentVC = pageViewController.viewControllers?.first as? NotebookPageView, let newIndex = pages.firstIndex(of: currentVC) else {
            return
        }
        currentPageIndex = newIndex
        updateSpineAppearance()
        preloadAdjacentPages()
    }

    private func updateSpineAppearance() {
        pages.enumerated().forEach { index, page in
            page.updateSpineStyle(isCurrentPage: index == currentPageIndex)
        }
    }

    private func preloadAdjacentPages() {
        [currentPageIndex - 1, currentPageIndex + 1].forEach {
            guard let page = pages[safe: $0] else { return }
            _ = page.view
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}