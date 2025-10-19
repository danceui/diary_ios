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

@available(iOS 26.0, *)
struct ContentView: View {
    private let notebookSpreadViewController = NotebookSpreadViewController()
    @StateObject private var toolManager = ToolManager.shared

    var body: some View {
        ZStack(alignment: .topLeading) {
            NotebookViewContainer(notebookSpreadViewController: notebookSpreadViewController).ignoresSafeArea()
            // 左侧工具栏
            VStack {
                Spacer()
                DrawingToolbar(notebookSpreadViewController: notebookSpreadViewController)
                    .environmentObject(toolManager)
                    .padding(.leading, leadingPadding)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading) 
            // 右上角功能按钮栏
            VStack {
                FunctionToolbar(notebookSpreadViewController: notebookSpreadViewController)
                    .padding(.top, topPadding)
                    .padding(.trailing, trailingPadding)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // 避免键盘顶起
    }

    // MARK: - Pressable Card Style
    struct PressableCardStyle: ButtonStyle {
        var isSelected: Bool
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 1.1 : 1.0)
                // ① 为按钮本体启用液态玻璃（前景 + 轮廓折射）
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                // ② 选中态描边（建议用 .tint 以适配玻璃下的动态配色）
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: isSelected ? 2 : 0)
                )
                // ③ 轻柔阴影（液态玻璃自身有体积感，这里别太重）
                // .shadow(radius: configuration.isPressed ? 7 : 5)
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }

    // MARK: - Fancy Brush Preview
    @available(iOS 26.0, *)
    struct FancyBrushPreview: View {
        let tool: Tool
        let style: ToolStyle
        var body: some View {
            Canvas { context, size in
                let segments = generatePathSegments(in: CGRect(origin: .zero, size: size), base: PreviewSVGConstants.baseSize)
                let line = generatePathLine(in: CGRect(origin: .zero, size: size), base: PreviewSVGConstants.baseSize)
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
                            line: line
                        )
                case .eraser: break
                case .sticker: break
                case .lasso: break
                } 
            }
            .frame(width: iconSize, height: iconSize)
            // .border(.red, width: 1)
        }
    }

    struct ToolButtonView: View {
        let tool: Tool
        let isSelected: Bool
        let style: ToolStyle?
        let action: () -> Void

        // @EnvironmentObject private var toolManager: ToolManager
        @State private var isPressed = false

        @available(iOS 26.0, *)
        var body: some View {
            Button(action: action) {
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
                .contentShape(Rectangle()) // 保证整个区域可点击
            }
            .buttonStyle(PressableCardStyle(isSelected: isSelected))
        }
    }


    // MARK: - Drawing Toolbar
    struct DrawingToolbar: View {
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
                // 背板改为液态玻璃
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                // 玻璃已自带圆角边界，无需再 clip
                .shadow(radius: 5)
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
                let currentStyle = toolManager.style(for: selectedTool)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: iconSpacing) {
                        ForEach(selectedTool.presetStyles, id: \.self) { style in
                            ToolButtonView(
                                tool: selectedTool,
                                isSelected: currentStyle == style,
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

    // MARK: - Function Toolbar
    struct FunctionToolbar: View {
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
