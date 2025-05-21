import UIKit

@available(iOS 16.0, *)
class NotebookPageSpreadViewController: UIViewController {
    let contentView: NotebookPageView

    init(pageIndex: Int, initialData: Data?) {
        self.contentView = NotebookPageView(pageIndex: pageIndex, initialData: initialData)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(contentView)
        view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.didMove(toParent: self)

        NSLayoutConstraint.activate([
            contentView.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.96),
            contentView.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let spine = UIView()
        spine.backgroundColor = .gray.withAlphaComponent(0.3)
        spine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spine)

        NSLayoutConstraint.activate([
            spine.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spine.widthAnchor.constraint(equalToConstant: 2),
            spine.topAnchor.constraint(equalTo: view.topAnchor),
            spine.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func exportDrawing() -> Data {
        return contentView.exportDrawing()
    }

    func undo() {
        contentView.undo()
    }

    func redo() {
        contentView.redo()
    }
}