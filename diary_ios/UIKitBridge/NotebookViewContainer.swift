import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct NotebookViewContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NotebookViewController {
        return NotebookViewController()
    }

    func updateUIViewController(_ uiViewController: NotebookViewController, context: Context) {
        // 可选：在这里响应 SwiftUI 状态变化
    }
}