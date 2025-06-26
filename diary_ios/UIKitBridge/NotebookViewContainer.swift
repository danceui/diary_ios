import SwiftUI

@available(iOS 16.0, *)
struct NotebookViewContainer: UIViewControllerRepresentable {
    let notebookSpreadVC: notebookSpreadViewController
    
    func makeUIViewController(context: Context) -> NotebookZoomableViewController {
        return NotebookZoomableViewController(notebookSpreadViewController: notebookSpreadVC)
    }

    func updateUIViewController(_ uiViewController: NotebookZoomableViewController, context: Context) {
        // 不需要更新
    }
}
