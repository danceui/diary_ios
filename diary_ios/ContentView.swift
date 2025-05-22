import SwiftUI

@available(iOS 16.0, *)
struct ContentView: View {
    // 保存控制器引用，用于按钮调用
    private let notebookVC = NotebookSpreadViewController()

    var body: some View {
        VStack(spacing: 0) {
            NotebookViewContainer(viewController: notebookVC)
                .edgesIgnoringSafeArea(.all)

            Divider()

            ToolBarView(notebookVC: notebookVC)
        }
    }
}

@available(iOS 16.0, *)
struct ToolBarView: View {
    let notebookVC: NotebookSpreadViewController

    var body: some View {
        HStack {
            Button("⬅ Prev") {
               notebookVC.goToPrevPage()
            }

            Button("Undo") {
               notebookVC.undo()
            }

            Button("Redo") {
               notebookVC.redo()
            }

            Button("Add Page") {
                notebookVC.addNewPagePair()
            }

            Button("➡ Next") {
               notebookVC.goToNextPage()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
}
