import UIKit

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
    
    // 驱动 UI 的两个源：当前工具、每个工具的样式
    @Published var currentTool: Tool = .pen
    @Published private(set) var toolStyles: [Tool: ToolStyle]
    @Published private(set) var selectedPresetIndex: [Tool: Int?]

    private init() {
        // 初始化每个工具的默认样式
        toolStyles = Dictionary(uniqueKeysWithValues: allTools.map { tool in
            let defaultStyle = tool.presetStyles.first ?? ToolStyle(color: nil, width: nil, opacity: nil)
            return (tool, defaultStyle)
        })
        // 默认每个可用工具选中第 0 个 preset
        selectedPresetIndex = Dictionary(uniqueKeysWithValues: allTools.map { tool in
            (tool, tool.presetStyles.isEmpty ? nil : 0)
        })
    }

    func style(for tool: Tool) -> ToolStyle? { return toolStyles[tool] }

    // 用户点某个 preset；返回是否“第二次点同一 preset”
    @discardableResult
    func tapPreset(for tool: Tool, index: Int) -> Bool {
        let secondTap = (selectedPresetIndex[tool] == index)
        selectedPresetIndex[tool] = index

        // 应用该 preset 到当前样式
        let p = tool.presetStyles[index]
        setStyle(for: tool, color: p.color, width: p.width, opacity: p.opacity)
        return secondTap
    }

    // 当前选中 preset 的索引（若存在）
    func currentPresetIndex(for tool: Tool) -> Int? { selectedPresetIndex[tool] ?? nil }

    // 可直接取到“当前选中 preset”的样式（若存在）
    func currentPreset(for tool: Tool) -> ToolStyle? {
        guard let idx = currentPresetIndex(for: tool),
              tool.presetStyles.indices.contains(idx) else { return nil }
        return tool.presetStyles[idx]
    }
    
    // 更新样式时，务必通过“读->改->写回”的方式触发 @Published 的变更
    func setStyle(for tool: Tool, color: UIColor? = nil, width: CGFloat? = nil, opacity: CGFloat? = nil) {
        var style = toolStyles[tool] ?? ToolStyle(color: nil, width: nil, opacity: nil)
        if let color = color { style.color = color }
        if let width = width { style.width = width }
        if let opacity = opacity { style.opacity = opacity }
        toolStyles[tool] = style
    }

    func selectTool(_ tool: Tool) { 
        currentTool = tool 
    }
}
