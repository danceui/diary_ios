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
                    .padding(.top, 10)
                    .padding(.trailing, 30)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // 避免键盘顶起
    }

    struct ToolButtonView: View {
        let tool: Tool
        let isSelected: Bool
        let color: Color?
        let action: () -> Void

        @State private var isPressed = false

        var body: some View {
            ZStack {
                // 手势监听包裹图层
                Group {
                    if tool == .monoline || tool == .pen {
                        Image(tool.iconName)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: tool.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 30, height: 30)
                .foregroundColor(color ?? (isSelected ? .blue : .gray))
                .padding(7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
            }
            .contentShape(Rectangle()) // 保证整个区域可点击
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        action() // ✅ 点击松开后才触发点击动作
                    }
            )
        }
    }
    
    struct DrawingToolBar: View {
        let notebookSpreadViewController: NotebookSpreadViewController
        @State private var selectedTool: Tool = ToolManager.shared.currentTool

        var body: some View {
            VStack(spacing: 24) {
                // 工具选择区
                ToolSelectionView(selectedTool: $selectedTool)
                    .frame(height: 160) // 固定工具选择区高度
                // 分割线
                Divider()
                    .frame(width: 24)
                    .padding(.top, 8)
                // 样式预设区
                if selectedTool.supportColor || selectedTool.supportWidth {
                    StylePresetView(selectedTool: selectedTool)
                        .frame(height: 120)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial) // 半透明磨砂效果
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        struct ToolSelectionView: View {
            @Binding var selectedTool: Tool

            var body: some View {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(allTools, id: \.self) { tool in
                            ToolButtonView(
                                tool: tool,
                                isSelected: selectedTool == tool,
                                color: ToolManager.shared.style(for: tool)?.color?.toColor()
                            ) {
                                selectedTool = tool
                                ToolManager.shared.currentTool = tool
                            }
                        }
                    }
                }
            }
        }

        struct StylePresetView: View {
            let selectedTool: Tool

            var body: some View {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(selectedTool.presetStyles, id: \.self) { style in
                            ToolButtonView(
                                tool: selectedTool,
                                isSelected: false,
                                color: style.color?.toColor()
                            ) {
                                ToolManager.shared.setStyle(
                                    for: selectedTool,
                                    color: style.color,
                                    width: style.width,
                                    opacity: style.opacity
                                )
                            }
                        }
                    }
                }
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