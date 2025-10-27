import UIKit
import SwiftUI

private let fade = ToolbarConstants.fade

private let sliderColor = DetailsPanelConstants.sliderColor
private let detailPreviewSize = DetailsPanelConstants.detailPreviewSize
private let sliderSpacing = DetailsPanelConstants.sliderSpacing
private let sliderTextWidth = DetailsPanelConstants.sliderTextWidth
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

// MARK: - ScrollView Fade Mask
struct VerticalEdgeFadeMask: View {
    var fade: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: fade)

            Rectangle().fill(.black)

            LinearGradient(
                colors: [.black, .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: fade)
        }
    }
}

struct HorizontalEdgeFadeMask: View {
    var fade: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: fade)

            Rectangle().fill(.black)

            LinearGradient(
                colors: [.black, .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: fade)
        }
    }
}

// MARK: - Details Panel
@available(iOS 26.0, *)
struct StyleDetailsPreview: View {
    let tool: Tool
    let style: ToolStyle

    var body: some View {
        FancyBrushPreview(tool: tool, style: style)
            .frame(width: detailPreviewSize, height: detailPreviewSize)
            .overlay(Rectangle().stroke(debugBorder ? Color.green.withOpacity(0.5) : .clear, lineWidth: 1))
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
            .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))

            Text("\(Int(width))")
                .monospacedDigit()
                .tint(sliderColor)
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
            .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))

            Text("\(Int(round(opacity * 100)))%")
                .monospacedDigit()
                .tint(sliderColor)
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
                    .mask(HorizontalEdgeFadeMask(fade: fade))
                    Divider()
                }
            }
            .padding(.vertical, colorPickerPadding)
            .overlay(Rectangle().stroke(debugBorder ? Color.orange.withOpacity(0.5) : .clear, lineWidth: 1))
        }
        .mask(VerticalEdgeFadeMask(fade: fade))
        .frame(width: colorPickerWidth, height: colorPickerHeight)
    }
}
