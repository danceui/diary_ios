import SwiftUI

@available(iOS 16.0, *)
struct NotebookViewContainer: UIViewControllerRepresentable {
    let viewController: NotebookSpreadViewController

    func makeUIViewController(context: Context) -> NotebookSpreadViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: NotebookSpreadViewController, context: Context) {
        // 无需更新
    }
}