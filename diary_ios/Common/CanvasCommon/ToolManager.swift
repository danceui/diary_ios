import UIKit
import Combine

enum Tool {
    case pen, highlighter, monoline
    case eraser
    case sticker
    case lasso

    var isDrawing: Bool { self == .pen || self == .highlighter || self == .monoline }
    var isSticker: Bool { self == .sticker }
    var isEraser: Bool { self == .eraser }
    var isLasso: Bool { self == .lasso }

    var supportColor: Bool { self == .pen || self == .highlighter || self == .monoline }
    var supportWidth: Bool { self == .pen || self == .highlighter || self == .monoline || self == .eraser }
    var supportOpacity: Bool { self == .pen || self == .highlighter || self == .monoline }
    var supportsPresets: Bool { self == .pen || self == .highlighter || self == .monoline }

    var iconName: String {
        switch self {
        case .pen:
            return "pen_drawing"
        case .monoline:
            return "monoline_drawing"
        case .highlighter:
            return "paintbrush.pointed.fill" // SF Symbol
        case .eraser:
            return "eraser.fill"
        case .sticker:
            return "sparkles"
        case .lasso:
            return "lasso"
        }
    }

    var presetStyles: [ToolStyle] {
        switch self {
        case .pen:
            return [
                ToolStyle(color: UIColor.black, width: 2, opacity: 1.0),
                ToolStyle(color: UIColor.blue, width: 4, opacity: 0.8),
                ToolStyle(color: UIColor.red, width: 6, opacity: 0.6)
            ]
        case .highlighter:
            return [
                ToolStyle(color: UIColor.black, width: 4, opacity: 0.5),
                ToolStyle(color: UIColor.green, width: 6, opacity: 0.4),
                ToolStyle(color: UIColor.orange, width: 8, opacity: 0.6)
            ]
        case .monoline:
            return [
                ToolStyle(color: UIColor.black, width: 4, opacity: 1.0),
                ToolStyle(color: UIColor.gray, width: 6, opacity: 0.8),
                ToolStyle(color: UIColor.red, width: 8, opacity: 0.6)
            ]
        default:
            return []
        }
    }
}

let allTools: [Tool] = [.pen, .monoline, .highlighter, .eraser, .sticker, .lasso]

struct ToolStyle: Hashable {
    var color: UIColor?
    var width: CGFloat?
    var opacity: CGFloat?
}

protocol ToolObserver: AnyObject {
    func toolDidChange(tool: Tool, style: ToolStyle?)
}

class ToolManager: ObservableObject {
    static let shared = ToolManager()
    
    @Published var currentTool: Tool = .pen
    @Published private(set) var presetStyles: [Tool: [ToolStyle]] = [:]
    @Published private(set) var presetIndices: [Tool: Int] = [:]

    // 初始化默认预设
    private init() {
        for tool in allTools where tool.supportsPresets {
            presetStyles[tool] = tool.presetStyles
            presetIndices[tool] = 0
        }
    }

    // 合成 publisher
    var toolAndStyle: AnyPublisher<(Tool, ToolStyle?), Never> {
        Publishers.CombineLatest3($currentTool, $presetIndices, $presetStyles)
            .map { tool, indices, styles -> (Tool, ToolStyle?) in
                guard tool.supportsPresets,
                    let idx = indices[tool],
                    let arr = styles[tool],
                    arr.indices.contains(idx) else {
                    return (tool, nil)
                }
                return (tool, arr[idx])
            }
            .removeDuplicates { lhs, rhs in
                lhs.0 == rhs.0 && lhs.1 == rhs.1
            }
            .eraseToAnyPublisher()
    }

    // 外部操作
    func selectTool(_ tool: Tool) { currentTool = tool }
    func selectPreset(for tool: Tool, index: Int) {
        guard tool.supportsPresets,
            let thisPresetStyles = presetStyles[tool],
            thisPresetStyles.indices.contains(index) else { return }
        presetIndices[tool] = index
    }

    // 外部查询
    func presetIndexForTool(for tool: Tool) -> Int? {
        guard tool.supportsPresets else { return nil}
        return presetIndices[tool]
    }

    func styleForTool(for tool: Tool) -> ToolStyle? {
        guard tool.supportsPresets,
            let idx = presetIndices[tool],
            let thisPresetStyles = presetStyles[tool],
            thisPresetStyles.indices.contains(idx) else { return nil }
        return thisPresetStyles[idx]
    }

    func setStyleFromDetail(for tool: Tool, index: Int, updated: ToolStyle) {
        guard tool.supportsPresets,
            var thisPresetStyles = presetStyles[tool],
            thisPresetStyles.indices.contains(idx) else { return }
        thisPresetStyles[idx] = updated
        presetStyles[tool] = thisPresetStyles
    }

}
