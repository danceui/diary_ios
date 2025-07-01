import SwiftUI

@available(iOS 16.0, *)
struct NotebookViewContainer: UIViewControllerRepresentable {
    let notebookSpreadViewController: NotebookSpreadViewController
    
    func makeUIViewController(context: Context) -> NotebookZoomableViewController {
        return NotebookZoomableViewController(notebookSpreadViewController: notebookSpreadViewController)
    }

    func updateUIViewController(_ uiViewController: NotebookZoomableViewController, context: Context) {
        // 不需要更新
    }
}
