import SwiftUI

@available(iOS 16.0, *)
struct NotebookViewContainer: UIViewControllerRepresentable {
    let controller: NotebookSpreadViewController

    func makeUIViewController(context: Context) -> NotebookZoomableSpreadView {
        return NotebookZoomableSpreadView(notebookVC: controller)
    }

    func updateUIViewController(_ uiViewController: NotebookZoomableSpreadView, context: Context) {
        // 不需要更新
    }
}