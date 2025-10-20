import SwiftUI
import UIKit

private let toolPanelHeight = ToolbarConstants.toolPanelHeight
private let stylePresetPanelHeight = ToolbarConstants.stylePresetPanelHeight
private let panelWidth = ToolbarConstants.panelWidth
private let leadingPadding = ToolbarConstants.leadingPadding
private let trailingPadding = ToolbarConstants.trailingPadding
private let topPadding = ToolbarConstants.topPadding
private let toolbarCornerRadius = ToolbarConstants.toolbarCornerRadius
private let iconSize = ToolbarConstants.iconSize
private let iconPadding = ToolbarConstants.iconPadding
private let iconSpacing = ToolbarConstants.iconSpacing
private let popoverMaxHeight: CGFloat = stylePresetPanelHeight
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

    // MARK: - Drawing Toolbar
    struct DrawingToolbar: View {
        let notebookSpreadViewController: NotebookSpreadViewController
        @State private var selectedTool: Tool = ToolManager.shared.currentTool
        @State private var showStylePresets: Bool = false

        var body: some View {
            HStack(alignment: .top, spacing: popoverGap) {
                GlassEffectContainer {
                    ToolPanelView(
                        selectedTool: $selectedTool,
                        showStylePresets: $showStylePresets
                    )
                }
                .frame(width: panelWidth, height: toolPanelHeight)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                if showStylePresets {
                    GlassEffectContainer {
                        StylePresetPanelView(
                            selectedTool: selectedTool
                        )
                    }
                    .frame(width: panelWidth, height: stylePresetPanelHeight)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                }
            }
        }
        
        struct ToolPanelView: View {
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
                                    if selectedTool.supportColor || selectedTool.supportWidth {
                                        showStylePresets.toggle()
                                    } else {
                                        showStylePresets = false
                                    }
                                } else {
                                    selectedTool = tool
                                    ToolManager.shared.currentTool = tool
                                    showStylePresets = false
                                }
                            }
                            .padding(iconPadding)
                        }
                    }
                    .padding(.top, topPadding / 2)
                    .padding(.bottom, topPadding / 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
            }
        }

        struct StylePresetPanelView: View {
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
                            .padding(iconPadding)
                        }
                    }
                    .padding(.top, topPadding / 2)
                    .padding(.bottom, topPadding / 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
            }
        }
    }

    // MARK: - Tool Button View
    @available(iOS 26.0, *)
    struct ToolButtonView: View {
        let tool: Tool
        let isSelected: Bool
        let style: ToolStyle?
        let action: () -> Void

        var body: some View {
            Button(action: action) {
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
                .padding(iconPadding)
                .foregroundColor(style?.color?.toColor() ?? (isSelected ? .blue : .gray))
                // .background(
                //     RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous)
                //     .fill(isSelected ? Color.black.opacity(0.18) : Color.black.opacity(0.06))
                //     .blur(radius: isSelected ? 0.6 : 0.2)
                // )
            }
            .buttonStyle(ToolButtonStyle(isSelected: isSelected))
        } 
    }
    
    @available(iOS 26.0, *)
    struct ToolButtonStyle: ButtonStyle {
        var isSelected: Bool
        private let corner = toolbarCornerRadius

        func makeBody(configuration: Configuration) -> some View {
            // 一个连续的强度值：普通 < 按压 < 选中
            let base: CGFloat = isSelected ? 0.55 : 0.18
            let pressBoost: CGFloat = configuration.isPressed ? 0.12 : 0.0
            let level = min(1.0, base + pressBoost) // 0…1

            configuration.label
                // 底板：稳态，不动画（避免亮度跳变）
                .background(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(Color.black.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .strokeBorder(.separator.opacity(isSelected ? 0.55 : 0.28), lineWidth: 1)
                        )
                )
                // 高亮层：只让它跟着 level 变化（包含 blur）
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(.white.opacity(0.18 + 0.22 * level))
                        .blur(radius: 10 * level)
                        .compositingGroup()
                        .allowsHitTesting(false)
                )
                // 轻微按压缩放与阴影（统一动画曲线）
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .shadow(radius: 6 * level + (isSelected ? 2 : 0), y: 1 + 1.5 * level)
                // 只对 level/pressed 做动画，其它禁用隐式动画
                .animation(.interpolatingSpring(stiffness: 280, damping: 28), value: level)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .transaction { $0.animation = nil }
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
