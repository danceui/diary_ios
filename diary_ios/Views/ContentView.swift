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
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        toolButton(icon: "pencil.tip", tool: .pen)
                        toolButton(icon: "paintbrush.pointed.fill", tool: .highlighter)
                        toolButton(icon: "eraser.fill", tool: .eraser)
                        toolButton(icon: "sparkles", tool: .sticker)
                        toolButton(icon: "lasso", tool: .lasso)
                    }
                }
                .frame(height: 160) // 固定工具选择区高度
                // 分割线
                Divider()
                    .frame(width: 24)
                    .padding(.top, 8)
                // 样式预设区：仅支持样式的工具显示
                if selectedTool.supportColor || selectedTool.supportWidth {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(presetStyles(for: selectedTool), id: \.self) { style in
                                let fillColor = style.color?.toColor() ?? .gray
                                let size = CGFloat(style.width ?? 8)
                                Button(action: {
                                    ToolManager.shared.setStyle(
                                        for: selectedTool,
                                        color: style.color,
                                        width: style.width,
                                        opacity: style.opacity
                                    )
                                }) {
                                    Circle()
                                        .fill(fillColor)
                                        .frame(width: size, height: size)
                                        .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 1))
                                }
                            }
                        }
                    }
                    .frame(height: 120) // 固定样式区高度
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

        func presetStyles(for tool: Tool) -> [ToolStyle] {
            switch tool {
            case .pen:
                return [
                    ToolStyle(color: UIColor.black, width: 4, opacity: 1.0),
                    ToolStyle(color: UIColor.blue, width: 6, opacity: 1.0),
                    ToolStyle(color: UIColor.red, width: 3, opacity: 1.0)
                ]
            case .highlighter:
                return [
                    ToolStyle(color: UIColor.yellow.withAlphaComponent(0.5), width: 10, opacity: 0.5),
                    ToolStyle(color: UIColor.green.withAlphaComponent(0.5), width: 12, opacity: 0.4),
                    ToolStyle(color: UIColor.orange.withAlphaComponent(0.5), width: 14, opacity: 0.6)
                ]
            default:
                return []
            }
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