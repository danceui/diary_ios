import UIKit
import SwiftUI

private let fade = ToolbarConstants.fade

private let sliderColor = DetailsPanelConstants.sliderColor
private let previewSize = DetailsPanelConstants.previewSize
private let previewHPadding = DetailsPanelConstants.previewHPadding
private let previewVPadding = DetailsPanelConstants.previewVPadding
private let previewBackgroundSquareSize = DetailsPanelConstants.previewBackgroundSquareSize
private let sliderSpacing = DetailsPanelConstants.sliderSpacing
private let sliderTextWidth = DetailsPanelConstants.sliderTextWidth
private let sliderHPadding = DetailsPanelConstants.sliderHPadding
private let colorPickerPadding = DetailsPanelConstants.colorPickerPadding
private let colorPickerWidth = DetailsPanelConstants.colorPickerWidth
private let colorPickerHeight = DetailsPanelConstants.colorPickerHeight
private let colorPickerFade = DetailsPanelConstants.colorPickerFade
private let colorPickerButtonSize = DetailsPanelConstants.colorPickerButtonSize
private let colorPickerButtonPadding = DetailsPanelConstants.colorPickerButtonPadding
private let colorPickerSpacing = DetailsPanelConstants.colorPickerSpacing

private let debugBorder = Debuggers.debugBorder

@available(iOS 26.0, *)
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
    }
}

// MARK: - Effect For Details Panel
struct VerticalEdgeFade: View {
    var fade: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color.black.opacity(0),      // 完全透明
                    Color.black.opacity(0.383),
                    Color.black.opacity(0.707),
                    Color.black.opacity(0.924),
                    Color.black                  // 完全不透明
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: fade)

            Rectangle().fill(.black)

            LinearGradient(
                colors: [
                    Color.black, // 完全不透明
                    Color.black.opacity(0.924),
                    Color.black.opacity(0.707),
                    Color.black.opacity(0.383),
                    Color.black.opacity(0) // 底部完全不透明
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: fade)
        }
    }
}

struct HorizontalEdgeFade: View {
    var fade: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color.black.opacity(0),      // 完全透明
                    Color.black.opacity(0.383),
                    Color.black.opacity(0.707),
                    Color.black.opacity(0.924),
                    Color.black                  // 完全不透明
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: fade)

            Rectangle().fill(.black)

            LinearGradient(
                colors: [
                    Color.black, // 完全不透明
                    Color.black.opacity(0.924),
                    Color.black.opacity(0.707),
                    Color.black.opacity(0.383),
                    Color.black.opacity(0) // 底部完全不透明
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: fade)
        }
    }
}

struct CheckerboardBackground: View {
    var squareSize: CGFloat

    var body: some View {
        GeometryReader { geo in
            let cols = Int(geo.size.width / squareSize)
            let rows = Int(geo.size.height / squareSize)
            Canvas { context, size in
                for y in 0..<rows {
                    for x in 0..<cols {
                        let isEven = (x + y).isMultiple(of: 2)
                        let color = isEven
                            ? Color(.systemGray5).opacity(0.6)
                            : Color(.systemGray6).opacity(0.6)
                        context.fill(
                            Path(
                                CGRect(
                                    x: CGFloat(x) * squareSize,
                                    y: CGFloat(y) * squareSize,
                                    width: squareSize,
                                    height: squareSize
                                )
                            ),
                            with: .color(color)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Details Panel
@available(iOS 26.0, *)
struct StyleDetailsPreview: View {
    let tool: Tool
    let style: ToolStyle

    var body: some View {
        ZStack {
            FancyBrushPreview(tool: tool, style: style)
                .frame(width: previewSize, height: previewSize)
                .padding(.vertical, previewVPadding)
                .padding(.horizontal, previewHPadding)
                .background(CheckerboardBackground(squareSize: previewBackgroundSquareSize))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(Rectangle().stroke(debugBorder ? Color.green.withOpacity(0.5) : .clear, lineWidth: 1))
        }
    }
}

struct StyleWidthControl: View {
    @Binding var width: Double
    var onCommit: () -> Void

    var body: some View {
        HStack(spacing: sliderSpacing) {
            Slider(
                value: $width,
                in: 1...10,
                step: 1,
                onEditingChanged: { editing in if !editing { onCommit() } }
            )
            .tint(sliderColor)
            .controlSize(.mini)
            .labelsHidden()
            .accessibilityLabel("Width")
            .frame(maxWidth: .infinity)
            .padding(.horizontal, colorPickerPadding)
            .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))

            Text("\(Int(width))")
                .monospacedDigit()
                .foregroundStyle(sliderColor) 
                .frame(width: sliderTextWidth, alignment: .center)
                .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))
        }
    }
}

struct StyleOpacityControl: View {
    @Binding var opacity: Double
    var onCommit: () -> Void

    var body: some View {
        HStack(spacing: sliderSpacing) {
            Slider(
                value: $opacity,
                in: 0.1...1,
                step: 0.1,
                onEditingChanged: { editing in if !editing { onCommit() } }
            )
            .tint(sliderColor)
            .controlSize(.mini)
            .labelsHidden()
            .accessibilityLabel("Opacity")
            .frame(maxWidth: .infinity)
            .padding(.horizontal, colorPickerPadding)
            .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))

            Text("\(Int(round(opacity * 100)))%")
                .monospacedDigit()
                .foregroundStyle(sliderColor) 
                .frame(width: sliderTextWidth, alignment: .center)
                .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))
        }
    }
}

struct StyleColorPalette: View {
    @Binding var selectedColor: Color
    var onCommit: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: colorPickerSpacing) {
                ForEach(PaletteStyle.allCases) { s in
                    let colors = Palette.colors[s] ?? []
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: colorPickerSpacing) {
                            ForEach(colors, id: \.self) { c in
                                Button {
                                    selectedColor = c
                                    onCommit()
                                } label: {
                                    Circle()
                                        .fill(c)
                                        .frame(width: colorPickerButtonSize, height: colorPickerButtonSize)
                                        .padding(colorPickerButtonPadding)
                                        .overlay(
                                            Circle().strokeBorder(c.opacity(0.8), lineWidth: selectedColor == c ? 3 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Preset color")
                                .overlay(Rectangle().stroke(debugBorder ? Color.green.withOpacity(0.5) : .clear, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, colorPickerPadding)
                    }
                    .mask(HorizontalEdgeFade(fade: fade))
                    Divider()
                }
            }
            .padding(.vertical, colorPickerPadding)
            .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))
        }
        .mask(VerticalEdgeFade(fade: fade))
        .frame(width: colorPickerWidth, height: colorPickerHeight)
    }
}

// MARK: - AnchorKey
struct ToolAnchorKey: PreferenceKey {
    static var defaultValue: [Tool: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Tool: Anchor<CGRect>], nextValue: () -> [Tool: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct PresetID: Hashable {
    let tool: Tool
    let index: Int
}

struct PresetAnchorKey: PreferenceKey {
    static var defaultValue: [PresetID: Anchor<CGRect>] = [:]
    static func reduce(value: inout [PresetID: Anchor<CGRect>], nextValue: () -> [PresetID: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct StyleDetailsKey: Hashable {
    let tool: Tool
    let index: Int
}