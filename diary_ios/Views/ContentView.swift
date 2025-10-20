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
                // DrawingToolbar(notebookSpreadViewController: notebookSpreadViewController)
                //     .environmentObject(toolManager)
                //     .padding(.leading, leadingPadding)
                DrawingToolbarTest(notebookSpreadViewController: notebookSpreadViewController)
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

    struct DrawingToolbarTest: View {
        let notebookSpreadViewController: NotebookSpreadViewController
        @State private var selectedTool: Tool = ToolManager.shared.currentTool
        @State private var showStylePresets: Bool = false
        @Namespace private var glassNS

        var body: some View {
            GlassEffectContainer(spacing: 10.0) {
                HStack(alignment: .top, spacing: popoverGap) {
                    
                    // first column: tool panel
                    VStack(spacing: iconSpacing) {
                        ToolSelectionView(
                            selectedTool: $selectedTool,
                            showStylePresets: $showStylePresets
                        )
                        .padding(6)
                        .frame(height: toolSelectionHeight)
                    }
                    .glassEffect()
                    .glassEffectID("toolbar", in: glassNS)
                    // .glassEffectUnion(id: "toolbar", namespace: glassNS)
                    
                    // second column: style presets panel
                    if showStylePresets {
                        VStack(spacing: iconSpacing) {
                            StylePresetView(selectedTool: selectedTool)
                            .padding(6)
                            .frame(height: stylePresetHeight)
                        }
                        .glassEffect()
                        .glassEffectID("presets", in: glassNS)
                        // .glassEffectUnion(id: "presets", namespace: glassNS)
                    }
                }
            }
        }


        struct ToolSelectionView: View {
            @Binding var selectedTool: Tool
            @Binding var showStylePresets: Bool
            @EnvironmentObject private var toolManager: ToolManager
            private let glassSpring = Animation.spring(response: 0.32, dampingFraction: 0.85)

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
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(radius: 5)
                // 右侧：样式预设竖条（仅在需要时显示）
                if showStylePresets {
                    VStack(spacing: iconSpacing) {
                        StylePresetView(selectedTool: selectedTool)
                    }
                    .frame(height: stylePresetHeight)
                    .padding(6)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(radius: 5)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        
        struct ToolSelectionView: View {
            @Binding var selectedTool: Tool
            @Binding var showStylePresets: Bool
            @EnvironmentObject private var toolManager: ToolManager
            private let glassSpring = Animation.spring(response: 0.32, dampingFraction: 0.85)

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

    // MARK: - Tool Button View
    struct ToolButtonView: View {
        let tool: Tool
        let isSelected: Bool
        let style: ToolStyle?
        let action: () -> Void

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
                .contentShape(Rectangle())
            }
            .buttonStyle(.glass)
        }
    }
    
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
