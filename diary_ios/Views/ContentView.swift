import SwiftUI
import UIKit

private let toolSelectionHeight = ToolbarConstants.toolSelectionHeight
private let stylePresetHeight = ToolbarConstants.stylePresetHeight
private let leadingPadding = ToolbarConstants.leadingPadding
private let trailingPadding = ToolbarConstants.trailingPadding
private let topPadding = ToolbarConstants.topPadding

private let iconSize = ToolbarConstants.iconSize
private let iconPadding = ToolbarConstants.iconPadding
private let iconSpacing = ToolbarConstants.iconSpacing
private let popoverMaxHeight: CGFloat = stylePresetHeight
private let popoverGap = ToolbarConstants.popoverGap

@available(iOS 16.0, *)
struct ContentView: View {
    private let notebookSpreadViewController = NotebookSpreadViewController()
    @StateObject private var toolManager = ToolManager.shared

    var body: some View {
        ZStack(alignment: .topLeading) {
            NotebookViewContainer(notebookSpreadViewController: notebookSpreadViewController).ignoresSafeArea()
            // 左侧工具栏
            VStack {
                Spacer()
                DrawingToolBar(notebookSpreadViewController: notebookSpreadViewController)
                    .environmentObject(toolManager)
                    .padding(.leading, leadingPadding)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading) 
            // 右上角功能按钮栏
            VStack {
                FunctionToolBar(notebookSpreadViewController: notebookSpreadViewController)
                    .padding(.top, topPadding)
                    .padding(.trailing, trailingPadding)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // 避免键盘顶起
    }

    struct FancyBrushPreview: View {
        let tool: Tool
        let style: ToolStyle
        var body: some View {
            let width = style.width ?? 2.0
            let inset: CGFloat = max(width / 2, 1)
            Canvas { context, size in
                let segments = generatePathSegments(inset: inset, drawingSize: CGSize(width: size.width - inset * 2, height: size.height - inset * 2))
                switch tool {
                case .monoline:
                    drawMonolinePreview(
                        context: context,
                        style: style,
                        segments: segments
                    )
                case .pen:
                    drawPenPreview(
                        context: context,
                        style: style,
                        segments: segments
                    )
                case .highlighter:
                        drawHighlighterPreview(
                            context: context,
                            style: style,
                            segments: segments
                        )
                case .eraser: break
                case .sticker: break
                case .lasso: break
                } 
            }
            .frame(width: iconSize, height: iconSize)
        }
    }

    struct ToolButtonView: View {
        let tool: Tool
        let isSelected: Bool
        let style: ToolStyle?
        let action: () -> Void

        @EnvironmentObject private var toolManager: ToolManager
        @State private var isPressed = false
        @State private var startLocation: CGPoint?

        var body: some View {
            ZStack {
                // 手势监听包裹图层
                Group {
                    if tool == .monoline || tool == .pen || tool == .highlighter, let style {
                        FancyBrushPreview(tool: tool, style: style)
                    } else {
                        Image(systemName: tool.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(style?.color?.toColor() ?? (isSelected ? .blue : .gray))
                .padding(iconPadding)
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
            }
            .contentShape(Rectangle()) // 保证整个区域可点击
            .simultaneousGesture( // 不会阻止 ScrollView 的滚动手势
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if startLocation == nil {
                            startLocation = value.startLocation
                            isPressed = true
                        }
                    }
                    .onEnded { value in
                        isPressed = false
                        if let start = startLocation {
                            let dx = value.location.x - start.x
                            let dy = value.location.y - start.y
                            let distance = dx * dx + dy * dy
                            if distance < 100 { // 判定为点击
                                action()
                            }
                        }
                        startLocation = nil
                    }
            )
        }
    }

    struct DrawingToolBar: View {
        let notebookSpreadViewController: NotebookSpreadViewController
        @State private var selectedTool: Tool = ToolManager.shared.currentTool
        @State private var showStylePresets: Bool = false

        var body: some View {
            HStack(alignment: .top, spacing: popoverGap) {
                // 左侧：工具选择区
                VStack(spacing: iconSpacing) {
                    ToolSelectionView(
                        selectedTool: $selectedTool,
                        showStylePresets: $showStylePresets
                    )
                    .frame(height: toolSelectionHeight)
                }
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                // 右侧：样式预设竖条（仅在需要时显示）
                if showStylePresets {
                    VStack(spacing: iconSpacing) {
                        StylePresetView(selectedTool: selectedTool)
                    }
                    .frame(height: stylePresetHeight)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        
        struct ToolSelectionView: View {
            @Binding var selectedTool: Tool
            @Binding var showStylePresets: Bool
            @EnvironmentObject private var toolManager: ToolManager

            var body: some View {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: iconSpacing) {
                        ForEach(allTools, id: \.self) { tool in
                            ToolButtonView(
                                tool: tool,
                                isSelected: selectedTool == tool,
                                style: ToolManager.shared.style(for: tool)
                            ) {
                                if selectedTool == tool {
                                    // 再次点击当前工具 -> 切换样式区
                                    if selectedTool.supportColor || selectedTool.supportWidth {
                                        showStylePresets.toggle()
                                    } else {
                                        // 不支持样式则保持收起
                                        showStylePresets = false
                                    }
                                } else {
                                    // 选择了新工具 -> 切换工具并收起样式区
                                    selectedTool = tool
                                    ToolManager.shared.currentTool = tool
                                    showStylePresets = false
                                }
                            }
                        }
                    }
                }
            }
        }

        struct StylePresetView: View {
            let selectedTool: Tool
            @EnvironmentObject private var toolManager: ToolManager

            var body: some View {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: iconSpacing) {
                        ForEach(selectedTool.presetStyles, id: \.self) { style in
                            ToolButtonView(
                                tool: selectedTool,
                                isSelected: false,
                                style: style
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
            HStack(spacing: iconSpacing) {
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
