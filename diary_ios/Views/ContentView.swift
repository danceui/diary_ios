import SwiftUI
import UIKit

let toolSelectionHeight = ToolbarConstants.toolSelectionHeight
let stylePresetHeight = ToolbarConstants.stylePresetHeight
let leadingPadding = ToolbarConstants.leadingPadding
let trailingPadding = ToolbarConstants.trailingPadding
let topPadding = ToolbarConstants.topPadding

let iconSize = ToolbarConstants.iconSize
let iconPadding = ToolbarConstants.iconPadding
let iconSpacing = ToolbarConstants.iconSpacing

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
                for (index, segment) in segments.enumerated() {
                    let (start, ctrl1, ctrl2, end) = segment
                    if tool == .monoline {
                        drawMonolinePreview(
                            context: context,
                            start: segment.0,
                            ctrl1: segment.1,
                            ctrl2: segment.2,
                            end: segment.3,
                            style: style,
                            segmentIndex: index,
                            totalSegments: segments.count
                        )
                    } else if tool == .pen {
                        drawPenPreview(
                            context: context,
                            start: segment.0,
                            ctrl1: segment.1,
                            ctrl2: segment.2,
                            end: segment.3,
                            style: style,
                            segmentIndex: index,
                            totalSegments: segments.count
                        )
                    } else {
                        // context.stroke(path, with: .color(PreviewConstants.previewColors[index]), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
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

        @State private var isPressed = false
        @State private var startLocation: CGPoint?

        var body: some View {
            ZStack {
                // 手势监听包裹图层
                Group {
                    if tool == .monoline || tool == .pen, let style = style {
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

        var body: some View {
            VStack(spacing: iconSpacing) {
                // 工具选择区
                ToolSelectionView(selectedTool: $selectedTool)
                    .frame(height: toolSelectionHeight)
                // 分割线
                Divider()
                    .frame(width: iconSize)
                    .padding(.top, iconSpacing)
                // 样式预设区
                if selectedTool.supportColor || selectedTool.supportWidth {
                    StylePresetView(selectedTool: selectedTool)
                        .frame(height: stylePresetHeight)
                }
            }
            .padding(6)
            .background(.ultraThinMaterial) // 半透明磨砂效果
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        struct ToolSelectionView: View {
            @Binding var selectedTool: Tool

            var body: some View {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: iconSpacing) {
                        ForEach(allTools, id: \.self) { tool in
                            ToolButtonView(
                                tool: tool,
                                isSelected: selectedTool == tool,
                                style: ToolManager.shared.style(for: tool)
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
