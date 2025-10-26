import SwiftUI
import UIKit

private let toolsPanelHeight = ToolbarConstants.toolsPanelHeight
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
private let buttonPadding = ToolbarConstants.buttonPadding
private let buttonSpacing = ToolbarConstants.buttonSpacing
private let popoverMaxHeight: CGFloat = stylePresetPanelHeight
private let detailPreviewSize = ToolbarConstants.detailPreviewSize
private let panelGap = ToolbarConstants.panelGap

private let debugBorder = Debuggers.debugBorder
private let debugToolManager = Debuggers.debugToolManager

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
                HStack(alignment: .top, spacing: panelGap) {
                    GlassEffectContainer {
                        ToolsPanel(
                            selectedTool: $selectedTool,
                            showStylePresets: $showStylePresets,
                            showStyleDetails: $showStyleDetails
                        )
                    }
                    .frame(width: panelWidth, height: toolsPanelHeight)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                    .overlay(Rectangle().stroke(debugBorder ? Color.black.withOpacity(0.5) : .clear, lineWidth: 1))

                    if showStylePresets, selectedTool.supportsPresets {
                        GlassEffectContainer {
                            StylePresetsPanel(
                                selectedTool: selectedTool,
                                showStyleDetails: $showStyleDetails
                            )
                        }
                        .frame(width: panelWidth, height: stylePresetPanelHeight)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                        .overlay(Rectangle().stroke(debugBorder ? Color.black.withOpacity(0.5) : .clear, lineWidth: 1))
                    }
                }

                GlassEffectContainer {
                    StyleDetailsPanel(
                        tool: selectedTool
                    )
                }
                .frame(width: styleDetailWidth, height: styleDetailHeight)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                .offset(x: calculateOffset())
                .opacity(showStyleDetails && selectedTool.supportsPresets ? 1 : 0)
            }
        }

        private func calculateOffset() -> CGFloat {
            var offset = panelWidth + panelGap
            if showStylePresets && selectedTool.supportsPresets {
                offset += panelWidth + panelGap
            }
            return offset
        }
        
        // MARK: - 1.Tools Panel
        struct ToolsPanel: View {
            @Binding var selectedTool: Tool
            @Binding var showStylePresets: Bool
            @Binding var showStyleDetails: Bool
            @State private var cachedStyles: [Tool: ToolStyle?] = [:]
            @EnvironmentObject private var toolManager: ToolManager

            var body: some View {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: buttonSpacing) {
                        ForEach(allTools, id: \.self) { tool in
                            ToolButton(
                                tool: tool,
                                isSelected: selectedTool == tool,
                                style: cachedStyles[tool] ?? nil
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
                            .padding(buttonPadding)
                            .overlay(Rectangle().stroke(debugBorder ? Color.blue.withOpacity(0.5) : .clear, lineWidth: 1))
                        }
                    }
                    .padding(.vertical, buttonSpacing)
                    .overlay(Rectangle().stroke(debugBorder ? Color.red.withOpacity(0.5) : .clear, lineWidth: 1))
                }
                .clipShape(RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                .onAppear { refreshCache() }
                .onReceive(toolManager.$presetStyles) { _ in refreshCache() }
                .onReceive(toolManager.$presetIndices) { _ in refreshCache() }
            }

            private func refreshCache() {
                print("🧰 [ToolsPanel] Refreshing cached styles for all tools.")
                var dict: [Tool: ToolStyle?] = [:]
                for t in allTools {
                    dict[t] = toolManager.styleForTool(for: t) // 只在需要时集中查询一次
                }
                cachedStyles = dict
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
                    VStack(spacing: buttonSpacing) {
                        ForEach(Array(presets.enumerated()), id: \.offset) { (idx, style) in
                            ToolButton(
                                tool: selectedTool,
                                isSelected: presetIndex == idx,
                                style: style
                            ) {
                                if presetIndex == idx {
                                    showStyleDetails.toggle()
                                } else {
                                    showStyleDetails = false
                                    toolManager.selectPreset(for: selectedTool, index: idx)
                                }
                            }
                            .padding(buttonPadding)
                            .overlay(Rectangle().stroke(debugBorder ? Color.blue.withOpacity(0.5) : .clear, lineWidth: 1))
                        }
                    }
                    .padding(.vertical, buttonSpacing)
                    .overlay(Rectangle().stroke(debugBorder ? Color.red.withOpacity(0.5) : .clear, lineWidth: 1))
                }
                .clipShape(RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
            }
        }
    }

    // MARK: - 3.Style Details Panel
    struct StyleDetailsPanel: View {
        let tool: Tool
        @EnvironmentObject private var toolManager: ToolManager

        // 本地编辑态，仅用于预览
        @State private var color: Color = .black
        @State private var width: Double = 4
        @State private var opacity: Double = 1
        @State private var baseStyle: ToolStyle = ToolStyle()
        @State private var editingIndex: Int? = nil

        private var previewStyle: ToolStyle {
            var style = baseStyle
            if tool.supportColor { style.color = UIColor(color) }
            if tool.supportWidth { style.width = CGFloat(width) }
            if tool.supportOpacity { style.opacity = CGFloat(opacity) }
            return style
        }

        var body: some View {
            VStack(spacing: 12) {
                if tool == .monoline || tool == .pen || tool == .highlighter {
                    FancyBrushPreview(tool: tool, style: previewStyle)
                    .frame(width: detailPreviewSize, height: detailPreviewSize)
                }
                if tool.supportWidth {
                    HStack(spacing: 10) {
                        Slider(
                            value: $width,
                            in: 1...10,
                            step: 1,
                            onEditingChanged: { editing in
                                if !editing { commitChanges() }
                            }
                        )
                        .controlSize(.mini)
                        .labelsHidden()
                        .accessibilityLabel("Width")
                        .frame(maxWidth: .infinity)
                        .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))

                        Text("\(Int(width))")
                        .monospacedDigit()
                        .frame(width: 56, alignment: .center)
                        .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))
                    }
                }
                if tool.supportOpacity {
                    HStack(spacing: 10) {
                        Slider(
                            value: $opacity,
                            in: 0.1...1,
                            step: 0.01,
                            onEditingChanged: { editing in
                                if !editing { commitChanges() }
                            })
                        .controlSize(.mini)
                        .labelsHidden()
                        .accessibilityLabel("Opacity")
                        .frame(maxWidth: .infinity)
                        .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))

                        Text("\(Int(round(opacity * 100)))%")
                        .monospacedDigit()
                        .frame(width: 56, alignment: .center)
                        .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))
                    }
                }
                if tool.supportColor {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(PaletteStyle.allCases) { s in
                                let colors = Palette.colors[s] ?? []
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(colors, id: \.self) { c in
                                            Button {
                                                color = c
                                                commitChanges()
                                            } label: {
                                                Circle()
                                                    .fill(c)
                                                    .frame(width: 28, height: 28)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(lineWidth: color == c ? 3 : 0)
                                                            .foregroundStyle(.primary.opacity(0.8))
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel("Preset color")
                                            .overlay(Rectangle().stroke(debugBorder ? Color.green.withOpacity(0.5) : .clear, lineWidth: 1))
                                        }
                                    }
                                }
                            }
                            .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(4)
                }
            }
            .padding(10)
            .onAppear {
                editingIndex = toolManager.presetIndexForTool(for: tool)
                if debugToolManager { print("🎨 [StyleDetailsPanel] Loading style from manager.") }
                loadFromManager()
            }
            .onDisappear { 
                commitChanges() 
            }
        }

        private func loadFromManager() {
            guard let idx = editingIndex,
              let style = toolManager.getStyle(for: tool, at: idx) else { return }
            baseStyle = style
            if tool.supportColor   { color = style.color?.toColor() ?? .black }
            if tool.supportWidth   { width = Double(style.width ?? 4) }
            if tool.supportOpacity { opacity = Double(style.opacity ?? 1) }
        }

        private func commitChanges() {
            guard let idx = editingIndex else { return }
            let updated = ToolStyle(
                color: UIColor(color),
                width: CGFloat(width),
                opacity: CGFloat(opacity)
            )
            // if updated == (toolManager.getStyle(for: tool, at: idx) ?? ToolStyle()) { return }
            toolManager.setStyle(for: tool, at: idx, to: updated)
            baseStyle = updated
        }
    }

    // MARK: - Tool Button View
    @available(iOS 26.0, *)
    struct ToolButton: View {
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
                // Canvas 内容随 .frame(width:) 自适应放大缩小
                let base = PreviewSVGConstants.baseSize
                let scale = min(size.width / base, size.height / base)
                context.scaleBy(x: scale, y: scale)

                let rect = CGRect(x: 0, y: 0, width: base, height: base)
                let segments = generatePathSegments(in: rect, base: base)
                let line = generatePathLine(in: rect, base: base)

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
            .overlay(Rectangle().stroke(debugBorder ? Color.green.withOpacity(0.5) : .clear, lineWidth: 1))
        }
    }

    // MARK: - Function Toolbar
    struct FunctionToolbar: View {
        let notebookSpreadViewController: NotebookSpreadViewController
        
        var body: some View {
            GlassEffectContainer {
                HStack(spacing: buttonSpacing) {
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
                .padding(buttonPadding)
            }
            .padding(buttonPadding)
        } 
    }
}
