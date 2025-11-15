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

@available(iOS 26.0, *)
struct ContentView: View {
    private let notebookPageViewController = NotebookPageViewController()
    @StateObject private var toolManager = ToolManager.shared

    var body: some View {
        ZStack {
            NotebookPageViewContainer(notebookPageViewController: notebookPageViewController)
                .ignoresSafeArea()
        }
        // 左侧工具栏（垂直居中；只有面板区域参与命中）
        .overlay(alignment: .leading) {
            VStack {
                Spacer()
                DrawingToolbar(notebookPageViewController: notebookPageViewController)
                    .environmentObject(toolManager)
                    .padding(.leading, leadingPadding)
                    .allowsHitTesting(true)
                Spacer()
            }
        }
        // 右上角功能按钮栏
        .overlay(alignment: .topTrailing) {
            FunctionToolbar(notebookPageViewController: notebookPageViewController)
                .padding(.top, topPadding)
                .padding(.trailing, trailingPadding)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Drawing Toolbar
    struct DrawingToolbar: View {
        let notebookPageViewController: NotebookPageViewController
        @State private var showPresets: Bool = false
        @State private var showDetails: Bool = false
        @State private var lockedID: UUID? = nil

        var body: some View {
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

                // if showPresets {
                GlassEffectContainer {
                    PresetsPanel(
                        showDetails: $showDetails,
                        lockedID: $lockedID
                    )
                }
                .frame(width: panelWidth, height: stylePresetPanelHeight)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                .opacity(showPresets ? 1 : 0)
                .overlay(Rectangle().stroke(debugBorder ? Color.black.withOpacity(0.5) : .clear, lineWidth: 1))
                // }
                
                // if showDetails {
                GlassEffectContainer {
                    StyleDetailsPanel(
                        lockedID: $lockedID
                    ) 
                }
                .frame(width: detailWidth, height: detailHeight)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                .opacity(showDetails ? 1 : 0)
                .overlay(Rectangle().stroke(debugBorder ? Color.black.withOpacity(0.5) : .clear, lineWidth: 1))
                // }
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
                            style: toolManager.getBrushStyle(for: tool)
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
            if toolManager.currentTool.isBrush {
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
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - 3.Style Details Panel
    struct StyleDetailsPanel: View {
        @Binding var lockedID: UUID?
        @EnvironmentObject private var toolManager: ToolManager
        private var tool: Tool { toolManager.currentTool }

        // 本地编辑态，仅用于预览
        @State private var color: Color = .black
        @State private var width: Double = 4
        @State private var opacity: Double = 1

        private var previewStyle: BrushStyle {
            BrushStyle(
                color: UIColor(color),
                width: CGFloat(width),
                opacity: CGFloat(opacity)
            )
        }

        var body: some View {
            if tool.isBrush {
                VStack(spacing: 12) {
                    if tool.isBrush {
                        StyleDetailsPreview(tool: tool, style: previewStyle)
                        StyleWidthControl(width: $width) { commitChanges() }
                        StyleOpacityControl(opacity: $opacity) { commitChanges() }
                        StyleColorPalette(selectedColor: $color) { commitChanges() }
                    }
                }
                .padding(10)
                .onAppear { loadFromManager() }
                .onChange(of: lockedID) { _ in loadFromManager() }
                // .onChange(of: toolManager.selectedPresetID[tool]) { _ in loadFromManager() }
                // .onChange(of: toolManager.currentTool) { _ in loadFromManager() }
                .onDisappear { 
                    commitChanges()
                }
            } else {
                EmptyView()
            }
        }

        private func apply(_ s: BrushStyle) {
            color = s.color.toColor()
            width = Double(s.width)
            opacity = Double(s.opacity)
        }

        private func loadFromManager() {
            guard tool.isBrush else { return }
            let effectiveID = lockedID ?? toolManager.selectedPresetID[tool]
            guard let id = effectiveID,
                let style = toolManager.getBrushStyle(for: tool, id: id) else { return }
            apply(style)
        }

        private func commitChanges() {
            guard tool.isBrush else { return }
            let effectiveID = lockedID ?? toolManager.selectedPresetID[tool]
            guard let id = effectiveID else { return }
            let updated = BrushStyle(
                color: UIColor(color),
                width: CGFloat(width),
                opacity: CGFloat(opacity)
            )
            if let old = toolManager.getBrushStyle(for: tool, id: id), old == updated { return }
            toolManager.setBrushStyle(for: tool, id: id, to: updated)
        }
    }

    // MARK: - Tool Button View
    @available(iOS 26.0, *)
    struct ToolButton: View {
        let tool: Tool
        let isSelected: Bool
        let style: BrushStyle?
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
        let notebookPageViewController: NotebookPageViewController
        
        var body: some View {
            GlassEffectContainer {
                HStack(spacing: buttonSpacing) {
                    FunctionButtonView(iconName: "arrow.uturn.backward") {
//                        notebookPageViewController.undo()
                    }
                    FunctionButtonView(iconName: "arrow.uturn.forward") {
//                        notebookPageViewController.redo()
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
