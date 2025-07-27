import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct ContentView: View {
    private let notebookSpreadViewController = NotebookSpreadViewController()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                NotebookViewContainer(notebookSpreadViewController: notebookSpreadViewController).ignoresSafeArea()
            }
            ToolBarView(notebookSpreadViewController: notebookSpreadViewController)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // 避免键盘顶起
    }

    @available(iOS 16.0, *)
    struct ToolBarView: View {
        let notebookSpreadViewController: NotebookSpreadViewController
        @State private var selectedTool: Tool = ToolManager.shared.currentTool

        var body: some View {
            HStack(spacing: 24) {
                toolButton(icon: "pencil.tip", tool: .pen)
                toolButton(icon: "paintbrush.pointed.fill", tool: .highlighter)
                toolButton(icon: "eraser.fill", tool: .eraser)
                toolButton(icon: "sparkles", tool: .sticker)
                toolButton(icon: "lasso", tool: .lasso)

                Divider().frame(height: 24)

                Button(action: {
                    notebookSpreadViewController.undo()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                }

                Button(action: {
                    notebookSpreadViewController.redo()
                }) {
                    Image(systemName: "arrow.uturn.forward")
                }

                Button(action: {
                    notebookSpreadViewController.addNewPagePair()
                }) {
                    Image(systemName: "plus.square.on.square")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial) // 半透明磨砂效果
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }

        func toolButton(icon: String, tool: Tool) -> some View {
            Button(action: {
                selectedTool = tool
                ToolManager.shared.currentTool = tool
            }) {
                Image(systemName: icon)
                    .foregroundColor(selectedTool == tool ? .accentColor : .primary)
                    .font(.system(size: 18, weight: .medium))
            }
        }
    }
}