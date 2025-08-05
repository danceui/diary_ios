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
        let color: Color
        let width: CGFloat

        var body: some View {
            Canvas { context, size in
                let inset: CGFloat = max(width / 2, 1)
                let drawingSize = CGSize(width: size.width - inset * 2, height: size.height - inset * 2)
                func convert(x: CGFloat, y: CGFloat) -> CGPoint {
                    let scaleX = drawingSize.width / 26.458333
                    let scaleY = drawingSize.height / 26.458333
                    return CGPoint(x: x * scaleX + inset, y: y * scaleY + inset)
                }
                var path = Path()
                // calculated swift path based on SVG data
                path.move(to: convert(x: 1.850687, y: 17.570022))
                path.addCurve(to: convert(x: 3.595063, y: 10.347862), control1: convert(x: 0.932941, y: 15.069087), control2: convert(x: 2.005763, y: 12.310653))
                path.addCurve(to: convert(x: 7.413834, y: 9.341245), control1: convert(x: 4.369668, y: 9.059063), control2: convert(x: 6.114127, y: 8.652024))
                path.addCurve(to: convert(x: 10.264806, y: 14.073580), control1: convert(x: 9.210874, y: 10.161493), control2: convert(x: 10.110526, y: 12.176224))
                path.addCurve(to: convert(x: 12.273829, y: 17.778131), control1: convert(x: 10.483572, y: 15.465286), control2: convert(x: 10.861685, y: 17.156747))
                path.addCurve(to: convert(x: 15.463040, y: 15.976733), control1: convert(x: 13.613956, y: 18.174263), control2: convert(x: 14.812265, y: 17.042496))
                path.addCurve(to: convert(x: 19.090702, y: 14.688075), control1: convert(x: 16.207361, y: 14.831670), control2: convert(x: 17.789632, y: 13.946173))
                path.addCurve(to: convert(x: 22.366480, y: 17.372298), control1: convert(x: 20.187863, y: 15.560343), control2: convert(x: 20.831390, y: 17.184842))
                path.addCurve(to: convert(x: 24.955118, y: 16.138709), control1: convert(x: 23.412848, y: 17.497058), control2: convert(x: 24.159403, y: 16.672955))
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
            .frame(width: iconSize, height: iconSize)
        }
    }

    struct ToolButtonView: View {
        let tool: Tool
        let isSelected: Bool
        let color: Color?
        let width: CGFloat?
        let action: () -> Void

        @State private var isPressed = false
        @State private var startLocation: CGPoint?

        var body: some View {
            ZStack {
                // 手势监听包裹图层
                Group {
                    if tool == .monoline || tool == .pen, let color = color, let width = width {
                        FancyBrushPreview(color: color, width: width)
                    } else {
                        Image(systemName: tool.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(color ?? (isSelected ? .blue : .gray))
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
                                color: ToolManager.shared.style(for: tool)?.color?.toColor(),
                                width: ToolManager.shared.style(for: tool)?.width
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
                                color: style.color?.toColor(),
                                width: style.width
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
