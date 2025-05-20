import UIKit
import PencilKit

@available(iOS 16.0, *)
class NotebookViewController: UIViewController {

    // MARK: - Properties
    private var scrollView = UIScrollView()
    private var stackView = UIStackView()
    private var pages: [NotebookPageView] = []
    private let pageSize = CGSize(width: 600, height: 800)  // 可调节大小

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupScrollView()
        addNewPage() // 初始添加一页
    }

    // MARK: - UI Setup
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        stackView.axis = .vertical
        stackView.spacing = 40
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    // MARK: - Page Management
    func addNewPage(initialData: Data? = nil) {
        let index = pages.count
        let pageFrame = CGRect(origin: .zero, size: pageSize)
        let page = NotebookPageView(frame: pageFrame, pageIndex: index, initialData: initialData)
        page.translatesAutoresizingMaskIntoConstraints = false
        page.layer.cornerRadius = 16
        page.clipsToBounds = true
        page.backgroundColor = .white

        pages.append(page)
        stackView.addArrangedSubview(page)

        NSLayoutConstraint.activate([
            page.heightAnchor.constraint(equalToConstant: pageSize.height),
            page.widthAnchor.constraint(equalToConstant: pageSize.width),
        ])
    }

    func page(at index: Int) -> NotebookPageView? {
        guard index >= 0 && index < pages.count else { return nil }
        return pages[index]
    }

    func currentPageCount() -> Int {
        return pages.count
    }

    // MARK: - Exports
    func exportAllDrawings() -> [Data] {
        return pages.map { $0.exportDrawing() }
    }
}
