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
}

@available(iOS 26.0, *)
// MARK: - Drawing Toolbar
struct DrawingToolbar: View {
    let notebookSpreadViewController: NotebookSpreadViewController
    @StateObject private var menu = MenuStore()
    @State private var toolAnchors: [Tool: Anchor<CGRect>] = [:]
    @State private var presetAnchors: [PresetID: Anchor<CGRect>] = [:]
    @EnvironmentObject private var toolManager: ToolManager

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(alignment: .top, spacing: panelGap) {
                GlassEffectContainer {
                    ToolsPanel(
                        onToolTap: { tool in
                            if toolManager.currentTool == tool {
                                switch menu.route {
                                case .toolsOnly:
                                    if tool.supportsPresets { menu.openPresets(for: tool)}
                                case .presets(let t) where t == tool:
                                    menu.backToTools()
                                case .details(let t, _) where t == tool:
                                    menu.closeDetailsToPresets()
                                default:
                                    menu.openPresets(for: tool)
                                }
                            } else {
                                toolManager.selectTool(tool)
                                if case .presets = menu.route { menu.backToTools() }
                            }
                        }
                    )
                }
                .frame(width: panelWidth, height: toolsPanelHeight)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                .overlay(Rectangle().stroke(debugBorder ? Color.black.withOpacity(0.6) : .clear))
            }
            // 汇总所有工具按钮锚点
            .onPreferenceChange(ToolAnchorKey.self) { toolAnchors = $0 }
            .onPreferenceChange(PresetAnchorKey.self) { presetAnchors = $0 }
            overlayPanels
        }
    }

    @ViewBuilder
    private var overlayPanels: some View {
        GeometryReader { proxy in 
            ZStack {
                // ---------- 二级：Style Presets ----------
                let isPresetsVisible = {
                    if case .presets(let t) = menu.route { return t.supportsPresets }
                    if case .details(let t, _) = menu.route { return t.supportsPresets } 
                    return false
                }()

                let presetsPos = positionForPanel(proxy: proxy, extraX: 0)

                GlassEffectContainer {
                    StylePresetsPanel(
                        onPresetTap: { idx in
                            guard let tool = currentTool else { return }
                            let currentIndex = toolManager.presetIndexForTool(for: tool)

                            if currentIndex == idx {
                                switch menu.route {
                                case .details(let t, let i) where t == tool && i == idx:
                                    menu.closeDetailsToPresets()
                                default:
                                    menu.openDetails(for: tool, index: idx)
                                }
                            } else {
                                toolManager.selectPreset(for: tool, index: idx)
                                if case .details = menu.route { menu.closeDetailsToPresets() }
                            }
                        }
                    )
                }
                .frame(width: panelWidth, height: stylePresetPanelHeight)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                .position(presetsPos)
                .opacity(isPresetsVisible ? 1 : 0)
                .allowsHitTesting(isPresetsVisible)
                .zIndex(10)

                // ---------- 三级：Style Details ----------
                let isDetailsVisible = {
                    if case .details = menu.route { return true }
                    return false
                }()

                let detailsPos = positionForDetailsPanel(
                    proxy: proxy,
                    defaultXExtra: (isPresetsVisible ? (panelWidth + panelGap) : 0)
                )

                GlassEffectContainer {
                    StyleDetailsPanel(
                        route: menu.route
                    )
                }
                .frame(width: detailWidth, height: detailHeight)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: toolbarCornerRadius, style: .continuous))
                .position(detailsPos)
                .opacity(isDetailsVisible ? 1 : 0)
                .allowsHitTesting(isDetailsVisible)
                .zIndex(20)
            }
        }
    }

    // 当前路由里的工具（如果存在）
    private var currentTool: Tool? {
        switch menu.route {
        case .presets(let t): return t
        case .details(let t, _): return t
        default: return toolManager.currentTool
        }
    }
    
    // 计算面板中心点（基于被选工具按钮的锚点）
    private func positionForPanel(proxy: GeometryProxy, extraX: CGFloat) -> CGPoint {
        guard let tool = currentTool,
              let anchor = toolAnchors[tool] else {
            // 找不到锚点时，退化到左上角偏移（不阻塞）
            return CGPoint(x: panelWidth + panelGap + extraX + panelWidth/2, y: topPadding + stylePresetPanelHeight/2)
        }
        let rect = proxy[anchor]
        let x = rect.maxX + panelGap + (panelWidth/2) + extraX
        let y = min(max(rect.midY, rect.height/2 + 8), proxy.size.height - rect.height/2 - 8)
        return CGPoint(x: x, y: y)
    }

    private func positionForDetailsPanel(proxy: GeometryProxy, defaultXExtra: CGFloat) -> CGPoint {
        if case .details(let tool, let idx) = menu.route,
        let anchor = presetAnchors[PresetID(tool: tool, index: idx)] {
            let r = proxy[anchor]
            // 紧贴 preset cell 右侧
            let x = r.maxX + panelGap + detailWidth / 2
            let y = min(max(r.midY, detailHeight/2 + 8),
                        proxy.size.height - detailHeight/2 - 8)
            return CGPoint(x: x, y: y)
        }
        // 回退：用当前工具按钮的锚点 + （如果二级在场）额外水平偏移
        if let tool = currentTool, let a = toolAnchors[tool] {
            let r = proxy[a]
            let x = r.maxX + panelGap + detailWidth/2 + defaultXExtra
            let y = min(max(r.midY, detailHeight/2 + 8),
                        proxy.size.height - detailHeight/2 - 8)
            return CGPoint(x: x, y: y)
        }
        // 实在没有锚点时的兜底
        return CGPoint(x: panelWidth + panelGap + detailWidth/2 + defaultXExtra,
                    y: topPadding + detailHeight/2)
    }
}

@available(iOS 26.0, *)
// MARK: - 1.Tools Panel
struct ToolsPanel: View {
    var onToolTap: (Tool) -> Void 
    @EnvironmentObject private var toolManager: ToolManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: buttonSpacing) {
                ForEach(allTools, id: \.self) { tool in
                    ToolButtonForToolsPanel(tool: tool) {
                        onToolTap(tool)
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

@available(iOS 26.0, *)
struct ToolButtonForToolsPanel: View {
    let tool: Tool
    let action: () -> Void
    @EnvironmentObject private var toolManager: ToolManager

    var body: some View {
        ToolButton(
            tool: tool,
            isSelected: toolManager.currentTool == tool,
            style: toolManager.styleForTool(for: tool),
            action: action
        )
        .anchorPreference(key: ToolAnchorKey.self, value: .bounds) { [tool: $0] }
    }
}

// MARK: - 2.Style Presets Panel
@available(iOS 26.0, *)
struct StylePresetsPanel: View {
    var onPresetTap: (Int) -> Void 
    @EnvironmentObject private var toolManager: ToolManager

    var body: some View {
        let tool = toolManager.currentTool
        let presets = toolManager.presetStyles[tool] ?? []
        let presetIndex = toolManager.presetIndexForTool(for: tool)

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: buttonSpacing) {
                ForEach(Array(presets.enumerated()), id: \.offset) { (idx, style) in
                    ToolButton(
                        tool: tool,
                        isSelected: presetIndex == idx,
                        style: style
                    ) {
                        onPresetTap(idx) 
                    }
                    .padding(buttonPadding)
                    .anchorPreference(key: PresetAnchorKey.self, value: .bounds) { [PresetID(tool: tool, index: idx): $0] }
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

@available(iOS 26.0, *)
// MARK: - 3.Style Details Panel
struct StyleDetailsPanel: View {
    let route: MenuRoute
    @EnvironmentObject private var toolManager: ToolManager

    // 本地编辑态，仅用于预览
    @State private var color: Color = .black
    @State private var width: Double = 4
    @State private var opacity: Double = 1

    private var tool: Tool? {
        if case .details(let t, _) = route { return t }
        if case .presets(let t) = route { return t }
        return toolManager.currentTool
    }
    private var lockedIndex: Int? {
        if case .details(_, let i) = route { return i }
        return nil
    }

    var body: some View {
        VStack(spacing: 12) {
            if let tool, tool == .monoline || tool == .pen || tool == .highlighter {
                StyleDetailsPreview(tool: tool, style: previewStyle(for: tool))
            }
            if let tool, tool.supportWidth {
                StyleWidthControl(width: $width) { commitChanges() }
            }
            if let tool, tool.supportOpacity {
                StyleOpacityControl(opacity: $opacity) { commitChanges() }
            }
            if let tool, tool.supportColor {
                StyleColorPalette(selectedColor: $color) { commitChanges() }
            }
        }
        .padding(10)
        // 路由变化时，从 ToolManager 同步当前预设到本地态（不重建视图）
        .onChange(of: route) { _, newValue in
            guard case .details(let t, let idx) = newValue,
                  let style = toolManager.getStyle(for: t, at: idx) else { return }
            applyStyleFromManager(style, tool: t)
        }
        .onAppear {
            if debugToolManager { print("🎨 [StyleDetailsPanel] Appeared.") }
            if case .details(let t, let idx) = route,
               let style = toolManager.getStyle(for: t, at: idx) {
                applyStyleFromManager(style, tool: t)
            }
        }
        .onDisappear { 
            commitChanges()
        }
    }

    private func previewStyle(for tool: Tool) -> ToolStyle {
        var s = ToolStyle()
        if tool.supportColor   { s.color   = UIColor(color) }
        if tool.supportWidth   { s.width   = CGFloat(width) }
        if tool.supportOpacity { s.opacity = CGFloat(opacity) }
        return s
    }

    private func applyStyleFromManager(_ s: ToolStyle, tool: Tool) {
        if tool.supportColor   { color   = s.color?.toColor() ?? .black }
        if tool.supportWidth   { width   = Double(s.width ?? 4) }
        if tool.supportOpacity { opacity = Double(s.opacity ?? 1) }
    }

    private func commitChanges() {
        guard let tool, let idx = lockedIndex else { return }
        let updated = ToolStyle(color: UIColor(color), width: CGFloat(width), opacity: CGFloat(opacity))
        if updated != toolManager.getStyle(for: tool, at: idx) {
            toolManager.setStyle(for: tool, at: idx, to: updated)
        }
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

@available(iOS 26.0, *)
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
