import SwiftUI
import UIKit

private let toolPanelHeight = ToolbarConstants.toolPanelHeight
private let stylePresetPanelHeight = ToolbarConstants.stylePresetPanelHeight
private let panelWidth = ToolbarConstants.panelWidth
private let styleDetailWidth = ToolbarConstants.styleDetailWidth
private let styleDetailHeight = ToolbarConstants.styleDetailHeight
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
        @State private var selectedTool = ToolManager.shared.currentTool
        @State private var showStylePresets: Bool = false
        @State private var showStyleDetails: Bool = false

        var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(alignment: .top, spacing: popoverGap) {
                ToolsPanel(
                    selectedTool: $selectedTool,
                    showStylePresets: $showStylePresets,
                    showStyleDetails: $showStyleDetails
                )
                .frame(width: panelWidth, height: toolPanelHeight)
                .background(
                    RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )

                if showStylePresets, selectedTool.supportsPresets {
                    StylePresetsPanel(
                        selectedTool: selectedTool,
                        showStyleDetails: $showStyleDetails
                    )
                    .frame(width: panelWidth, height: stylePresetPanelHeight)
                    .background(
                        RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            StyleDetailsContentView(
                tool: selectedTool
            )
            .frame(width: styleDetailWidth, height: styleDetailHeight)
            .background(
                RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        
        // MARK: - 1.Tools Panel
        struct ToolsPanel: View {
            @Binding var selectedTool: Tool
            @Binding var showStylePresets: Bool
            @Binding var showStyleDetails: Bool
            @EnvironmentObject private var toolManager: ToolManager

            var body: some View {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: iconSpacing) {
                        ForEach(allTools, id: \.self) { tool in
                            ToolButtonView(
                                tool: tool,
                                isSelected: selectedTool == tool,
                                style: toolManager.styleForTool(for: tool)
                            ) {
                                if selectedTool == tool {
                                    showStylePresets.toggle()
                                    showStyleDetails = false
                                } else {
                                    selectedTool = tool
                                    toolManager.currentTool = tool
                                    showStylePresets = false
                                    showStyleDetails = false
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

        // MARK: - 2.Style Presets Panel
        struct StylePresetsPanel: View {
            let selectedTool: Tool
            @Binding var showStyleDetails: Bool
            @EnvironmentObject private var toolManager: ToolManager

            var body: some View {
                let presets = toolManager.presetStyles[selectedTool] ?? []
                let presetIndex = toolManager.presetIndexForTool(for: selectedTool)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: iconSpacing) {
                        ForEach(Array(presets.enumerated()), id: \.offset) { (idx, style) in
                            ToolButtonView(
                                tool: selectedTool,
                                isSelected: presetIndex == idx,
                                style: style
                            ) {
                                let _ = print("Clicked #\(idx) preset - \(Date())")
                                if presetIndex == idx {
                                    showStyleDetails.toggle()
                                } else {
                                    toolManager.selectPreset(for: selectedTool, index: idx)
                                    showStyleDetails = false
                                }
                            }
                            .padding(iconPadding)
                        }
                    }
                    .padding(.vertical, topPadding / 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
            }
        }
    }

    // MARK: - 3.Style Details Panel
    struct StyleDetailsPanel: View {
        let tool: Tool
        @EnvironmentObject private var toolManager: ToolManager

        // 控制延迟加载
        @State private var loaded = false

        var body: some View {
            Group {
                if loaded {
                    StyleDetailsContentView(tool: tool) // 使用新的内容视图
                    // Text("Style Details for \(tool)") // 占位
                        .environmentObject(toolManager)
                        // 移除 .presentationCompactAdaptation(.popover) 等 popover 特有代码
                        .padding(8)
                } else {
                    // 占位（轻量）
                    ProgressView().frame(width: styleDetailWidth - 20, height: styleDetailHeight - 20)
                }
            }
            .onAppear {
                // 下一帧再加载重内容，避免面板打开瞬间卡顿
                let _ = print("StyleDetailsPanel appeared - \(Date())")
                DispatchQueue.main.async {
                    loaded = true
                }
            }
        }
    }

    struct StyleDetailsContentView: View {
        let tool: Tool
        @EnvironmentObject private var toolManager: ToolManager

        // 本地编辑态，仅用于预览
        @State private var color: Color = .black
        @State private var width: Double = 4
        @State private var opacity: Double = 1

        private var detailIndex: Int? {
            toolManager.presetIndexForTool(for: tool)
        }

        private var previewStyle: ToolStyle {
            var style = toolManager.styleForTool(for: tool) ?? ToolStyle()
            if tool.supportColor { style.color = UIColor(color) }
            if tool.supportWidth { style.width = CGFloat(width) }
            if tool.supportOpacity { style.opacity = CGFloat(opacity) }
            return style
        }

        var body: some View {
            VStack(spacing: 12) {
                // if tool == .monoline || tool == .pen || tool == .highlighter {
                    // FancyBrushPreview(tool: tool, style: previewStyle)
                    //     .frame(width: 60, height: 60)
                // }
                if tool.supportWidth {  
                    HStack(spacing: 10) {Text("Style Details for \(tool)") 
                        // Slider(
                        //     value: $width,
                        //     in: 1...10,
                        //     step: 1,
                        //     onEditingChanged: { editing in
                        //         if !editing { commitChanges() }
                        //     }
                        // )
                        // .controlSize(.mini)
                        // .labelsHidden()
                        // .accessibilityLabel("Width")
                        // .frame(maxWidth: .infinity)

                        // Text("\(Int(width))")
                        //     .monospacedDigit()
                        //     .frame(width: 56, alignment: .center)
                    }
                }
                // if tool.supportOpacity {
                //     HStack(spacing: 10) {
                //         Slider(
                //             value: $opacity,
                //             in: 0.1...1,
                //             step: 0.01,
                //             onEditingChanged: { editing in
                //                 if !editing { commitChanges() }
                //             })
                //         .controlSize(.mini)
                //         .labelsHidden()
                //         .accessibilityLabel("Opacity")
                //         .frame(maxWidth: .infinity)

                //         Text("\(Int(round(opacity * 100)))%")
                //             .monospacedDigit()
                //             .frame(width: 56, alignment: .center)
                //     }
                // }
                // if tool.supportColor {
                //     ScrollView {
                //         VStack(spacing: 10) {
                //             ForEach(PaletteStyle.allCases) { s in
                //                 let colors = Palette.colors[s] ?? []
                //                 HStack(spacing: 10) {
                //                     ForEach(colors, id: \.self) { c in
                //                         Button {
                //                             color = c
                //                             commitChanges()
                //                         } label: {
                //                             Circle()
                //                                 .fill(c)
                //                                 .frame(width: 28, height: 28)
                //                                 .overlay(
                //                                     Circle()
                //                                         .stroke(lineWidth: color == c ? 3 : 0)
                //                                         .foregroundStyle(.primary.opacity(0.8))
                //                                 )
                //                         }
                //                         .buttonStyle(.plain)
                //                         .accessibilityLabel("Preset color")
                //                     }
                //                 }
                //             }
                //         }
                //         .padding(.top, 2)
                //     }
                //     .padding(12)
                // }
            }
            .padding(10)
            .onAppear {
                loadFromManager()
                let _ = print("StyleDetailsContentView appeared - \(Date())")
            }
        }

        private func loadFromManager() {
            guard let idx = detailIndex,
              let style = toolManager.getStyle(for: tool, at: idx) else { return }
            if tool.supportColor   { color = style.color?.toColor() ?? .black }
            if tool.supportWidth   { width = Double(style.width ?? 4) }
            if tool.supportOpacity { opacity = Double(style.opacity ?? 1) }
        }

        private func commitChanges() {
            guard let idx = detailIndex else { return }
            let updated = ToolStyle(
                color: UIColor(color),
                width: CGFloat(width),
                opacity: CGFloat(opacity)
            )
            if updated == (toolManager.getStyle(for: tool, at: idx) ?? ToolStyle()) { return }
            toolManager.setStyle(for: tool, at: idx, to: updated)
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
