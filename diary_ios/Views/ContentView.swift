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
                .background(
                    RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous)
                    .fill(Color.black.opacity(isSelected ? 0.12 : 0.05))
                    .blur(radius: isSelected ? 0.55 : 0.2)
                )
            }
            .buttonStyle(ToolButtonStyle(isSelected: isSelected))
        } 
    }

    @available(iOS 26.0, *)
    struct ToolButtonStyle: ButtonStyle {
        var isSelected: Bool

        func makeBody(configuration: Configuration) -> some View {
            // 选中时有一个“基础放大”，按下时再加一点点
            let selectedBaseScale: CGFloat = isSelected ? 1.06 : 1.0
            let pressBoost: CGFloat = configuration.isPressed ? 0.04 : 0.0
            let scale = selectedBaseScale + pressBoost

            return configuration.label
                .scaleEffect(scale)
                .animation(.easeOut(duration: 0.04), value: configuration.isPressed)
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
            GlassEffectContainer {
                HStack(spacing: iconSpacing) {
                    FunctionButtonView(iconName: "arrow.uturn.backward") {
                    notebookSpreadViewController.undo()
                    }
                    FunctionButtonView(iconName: "arrow.uturn.forward") {
                        notebookSpreadViewController.redo()
                    }
                    FunctionButtonView(iconName: "plus.square.on.square") {
                        notebookSpreadViewController.addNewPagePair()
                    }
                }
                .padding(.leading, topPadding / 2)
                .padding(.trailing, topPadding / 2)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
        }
    }

    @available(iOS 26.0, *)
    struct FunctionButtonView: View {
        let iconName: String
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .scaleEffect(0.7)
                .padding(iconPadding)
            }
            .padding(iconPadding)
        } 
    }
}
