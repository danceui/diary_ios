import SwiftUI

@available(iOS 16.0, *)
struct NotebookViewContainer: UIViewControllerRepresentable {
    let viewController: NotebookViewController

    func makeUIViewController(context: Context) -> NotebookViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: NotebookViewController, context: Context) {
        // 无需更新
    }
}