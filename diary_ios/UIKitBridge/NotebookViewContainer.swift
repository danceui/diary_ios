import SwiftUI

@available(iOS 16.0, *)
struct NotebookViewContainer: UIViewControllerRepresentable {
    let notebookSpreadVC: NotebookSpreadViewController
    var width: CGFloat = 900  // 默认值
    var height: CGFloat = 600  // 默认值
    var borderColor: Color = .red // 边框颜色

    func makeUIViewController(context: Context) -> NotebookZoomableViewController {
        return NotebookZoomableViewController(notebookSpreadVC: notebookSpreadVC)
    }

    func updateUIViewController(_ uiViewController: NotebookZoomableViewController, context: Context) {
        // 不需要更新
    }
}

extension NotebookViewContainer {
    var body: some View {
        self
            .frame(width: width, height: height)
            .clipped()
            .border(borderColor)
    }
}