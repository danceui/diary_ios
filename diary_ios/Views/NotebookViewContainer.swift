import SwiftUI

@available(iOS 16.0, *)
// NotebookPageViewContainer 是 “SwiftUI 外壳 + UIKit 内核” 的桥接件
// 创建时把你的容器 VC 搭起来
// 更新时目前不做同步，因此若日后要根据 SwiftUI 状态切页/缩放/替换内容，请把逻辑补到 updateUIViewController 或用 .id(...) 强制重建。
struct NotebookPageViewContainer: UIViewControllerRepresentable {
    let notebookSpreadViewController: NotebookSpreadViewController
    
    // SwiftUI 首次需要这个视图时调用
    func makeUIViewController(context: Context) -> NotebookZoomableViewController {
        return NotebookZoomableViewController(notebookSpreadViewController: notebookSpreadViewController)
    }

    // 当 SwiftUI 的状态导致视图需要刷新时调用
    func updateUIViewController(_ uiViewController: NotebookZoomableViewController, context: Context) {
        // 不需要更新
    }
}
