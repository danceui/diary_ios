import SwiftUI
import UIKit
import Combine

private let toolsPanelHeight = ToolbarConstants.toolsPanelHeight
private let stylePresetPanelHeight = ToolbarConstants.stylePresetPanelHeight
private let panelWidth = ToolbarConstants.panelWidth
private let leadingPadding = ToolbarConstants.leadingPadding
private let trailingPadding = ToolbarConstants.trailingPadding
private let topPadding = ToolbarConstants.topPadding
private let toolbarCornerRadius = ToolbarConstants.toolbarCornerRadius
private let iconSize = ToolbarConstants.iconSize
private let iconPadding = ToolbarConstants.iconPadding
private let buttonPadding = ToolbarConstants.buttonPadding
private let buttonSpacing = ToolbarConstants.buttonSpacing
private let popoverMaxHeight: CGFloat = stylePresetPanelHeight
private let panelGap = ToolbarConstants.panelGap
private let fade = ToolbarConstants.fade

private let detailWidth = DetailsPanelConstants.detailWidth
private let detailHeight = DetailsPanelConstants.detailHeight

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
        @State private var showPresets: Bool = false
        @State private var showDetails: Bool = false
        @State private var lockedID: UUID? = nil
        @EnvironmentObject private var toolManager: ToolManager

        var body: some View {
            ZStack(alignment: .topLeading) {
                HStack(alignment: .top, spacing: panelGap) {
                    GlassEffectContainer {
                        ToolsPanel(
                            showPresets: $showPresets,
                            showDetails: $showDetails,
                        )
                    }
                    .frame(width: panelWidth, height: toolsPanelHeight)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                    .overlay(Rectangle().stroke(debugBorder ? Color.black.withOpacity(0.5) : .clear, lineWidth: 1))

                    if showPresets, toolManager.currentTool.supportsPresets {
                        GlassEffectContainer {
                            PresetsPanel(
                                showDetails: $showDetails,
                                lockedID: $lockedID
                            )
                        }
                        .frame(width: panelWidth, height: stylePresetPanelHeight)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                        .overlay(Rectangle().stroke(debugBorder ? Color.black.withOpacity(0.5) : .clear, lineWidth: 1))
                    }
                    if showDetails, toolManager.currentTool.supportsPresets {
                        GlassEffectContainer {
                            StyleDetailsPanel(
                                tool: toolManager.currentTool,
                                lockedID: lockedID
                            ) 
                        }
                        .frame(width: detailWidth, height: detailHeight)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                        .overlay(Rectangle().stroke(debugBorder ? Color.black.withOpacity(0.5) : .clear, lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - 1.Tools Panel
    struct ToolsPanel: View {
        @Binding var showPresets: Bool
        @Binding var showDetails: Bool
        @EnvironmentObject private var toolManager: ToolManager

        var body: some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: buttonSpacing) {
                    ForEach(Tool.allCases) { tool in
                        ToolButton(
                            tool: tool,
                            isSelected: toolManager.currentTool == tool,
                            style: toolManager.getStyle(for: tool)
                        ) {
                            showDetails = false
                            if toolManager.currentTool == tool {
                                showPresets.toggle()
                            } else {
                                toolManager.selectTool(tool)
                                showPresets = false
                            }
                        }
                        .padding(buttonPadding)
                        .overlay(Rectangle().stroke(debugBorder ? Color.blue.withOpacity(0.5) : .clear, lineWidth: 1))
                    }
                }
                .padding(.vertical, 1.5 * buttonSpacing)
                .overlay(Rectangle().stroke(debugBorder ? Color.red.withOpacity(0.5) : .clear, lineWidth: 1))
            }
            .mask(VerticalEdgeFade(fade: fade))
            .clipShape(RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
        }
    }

    // MARK: - 2.Style Presets Panel
    struct PresetsPanel: View {
        @Binding var showDetails: Bool
        @Binding var lockedID: UUID?
        @EnvironmentObject private var toolManager: ToolManager

        var body: some View {
            let tool = toolManager.currentTool
            let presets = toolManager.currentPresets
            let selectedID = toolManager.selectedPresetID[tool]

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: buttonSpacing) {
                    ForEach(presets) { preset in
                        ToolButton(
                            tool: tool,
                            isSelected: selectedID == preset.id,
                            style: preset.style
                        ) {
                            if selectedID == preset.id {
                                if !showDetails {
                                    lockedID = selectedID
                                    showDetails = true
                                } else {
                                    showDetails = false
                                    lockedID = nil
                                }
                            } else {
                                if showDetails {
                                    showDetails = false
                                }
                                DispatchQueue.main.async {
                                    toolManager.selectPreset(for: tool, id: preset.id)
                                    lockedID = nil
                                }
                            }
                        }
                        .padding(buttonPadding)
                        .overlay(Rectangle().stroke(debugBorder ? Color.blue.withOpacity(0.5) : .clear, lineWidth: 1))
                    }
                }
                .padding(.vertical, 1.5 * buttonSpacing)
                .overlay(Rectangle().stroke(debugBorder ? Color.red.withOpacity(0.5) : .clear, lineWidth: 1))
            }
            .mask(VerticalEdgeFade(fade: fade))
            .clipShape(RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
        }
    }

    // MARK: - 3.Style Details Panel
    struct StyleDetailsPanel: View {
        let tool: Tool
        let lockedID: UUID?
        @EnvironmentObject private var toolManager: ToolManager

        // 本地编辑态，仅用于预览
        @State private var color: Color = .black
        @State private var width: Double = 4
        @State private var opacity: Double = 1

        private var previewStyle: ToolStyle {
            var style = ToolStyle()
            if tool.supportColor   { style.color   = UIColor(color) }
            if tool.supportWidth   { style.width   = CGFloat(width) }
            if tool.supportOpacity { style.opacity = CGFloat(opacity) }
            return style
        }

        var body: some View {
            VStack(spacing: 12) {
                if tool == .monoline || tool == .pen || tool == .highlighter {
                    StyleDetailsPreview(tool: tool, style: previewStyle)
                }
                if tool.supportWidth {
                    StyleWidthControl(width: $width) { commitChanges() }
                }
                if tool.supportOpacity {
                    StyleOpacityControl(opacity: $opacity) { commitChanges() }
                }
                if tool.supportColor {
                    StyleColorPalette(selectedColor: $color) { commitChanges() }
                }
            }
            .padding(10)
            .onAppear { loadFromManager() }
            .onChange(of: lockedID) { _ in loadFromManager() }
            .onChange(of: toolManager.selectedPresetID[tool]) { _ in loadFromManager() }
            .onDisappear { 
                commitChanges()
            }
        }

        private func loadFromManager() {
            let effectiveID = lockedID ?? toolManager.selectedPresetID[tool]
            guard let id = effectiveID,
                let style = toolManager.getStyle(for: tool, id: id) else { return }
            apply(style)
        }

        private func apply(_ s: ToolStyle) {
            if tool.supportColor   { color   = s.color?.toColor() ?? .black }
            if tool.supportWidth   { width   = Double(s.width ?? 4) }
            if tool.supportOpacity { opacity = Double(s.opacity ?? 1) }
        }

        private func commitChanges() {
            let updated = ToolStyle(
                    color: UIColor(color),
                    width: CGFloat(width),
                    opacity: CGFloat(opacity)
                )
            let effectiveID = lockedID ?? toolManager.selectedPresetID[tool]
            guard let id = effectiveID else { return }
            toolManager.setStyle(for: tool, id: id, to: updated)
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
