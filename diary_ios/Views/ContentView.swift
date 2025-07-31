import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct ContentView: View {
    private let notebookSpreadViewController = NotebookSpreadViewController()

    var body: some View {
        ZStack(alignment: .topLeading) {
            NotebookViewContainer(notebookSpreadViewController: notebookSpreadViewController).ignoresSafeArea()
            // 左侧工具栏
            VStack {
                Spacer()
                DrawingToolBar(notebookSpreadViewController: notebookSpreadViewController)
                    .padding(.leading, 30)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading) 
            // 右上角功能按钮栏
            VStack {
                FunctionToolBar(notebookSpreadViewController: notebookSpreadViewController)
                    .padding(.top, 40)
                    .padding(.trailing, 30)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // 避免键盘顶起
    }

    struct DrawingToolBar: View {
        let notebookSpreadViewController: NotebookSpreadViewController
        @State private var selectedTool: Tool = ToolManager.shared.currentTool

        var body: some View {
            VStack(spacing: 24) {
                // 工具选择区
                toolButton(icon: "pencil.tip", tool: .pen)
                toolButton(icon: "paintbrush.pointed.fill", tool: .highlighter)
                toolButton(icon: "eraser.fill", tool: .eraser)
                toolButton(icon: "sparkles", tool: .sticker)
                toolButton(icon: "lasso", tool: .lasso)
                // 分割线
                Divider()
                    .frame(width: 24)
                    .padding(.top, 8)
                // 工具样式区
                if selectedTool == .pen || selectedTool == .highlighter {
                    VStack(spacing: 12) {
                        ForEach(presetStyles(for: selectedTool), id: \.self) { style in
                            Button(action: {
                                ToolManager.shared.applyStyle(tool: selectedTool, color: style.color, width: style.width)
                            }) {
                                Circle()
                                    .fill(style.color)
                                    .frame(width: CGFloat(style.width), height: CGFloat(style.width))
                                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 1))
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(12)
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
        
        func presetStyles(for tool: Tool) -> [ToolStylePreset] {
            // 你可以根据需求添加更多样式组合
            if tool == .pen {
                return [
                    ToolStylePreset(color: .black, width: 6),
                    ToolStylePreset(color: .blue, width: 4),
                    ToolStylePreset(color: .red, width: 8)
                ]
            } else if tool == .highlighter {
                return [
                    ToolStylePreset(color: .yellow.opacity(0.5), width: 12),
                    ToolStylePreset(color: .green.opacity(0.5), width: 10),
                    ToolStylePreset(color: .orange.opacity(0.5), width: 14)
                ]
            }
            return []
        }
    }

    struct FunctionToolBar: View {
        let notebookSpreadViewController: NotebookSpreadViewController

        var body: some View {
            HStack(spacing: 20) {
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
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}