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
    // @Published private(set) var toolStyles: [Tool: ToolStyle]
    @Published private(set) var presetStyles: [Tool: [ToolStyle]] = [:]
    @Published private(set) var presetIndexes: [Tool: Int?] = [:]

    // 合成 publisher：任何相关变化都会触发 (Tool, ToolStyle)
    var toolManagerPublisher: AnyPublisher<(Tool, ToolStyle), Never> {
        Publishers.CombineLatest3($currentTool, $presetIndexes, $presetStyles)
            .map { [weak self] tool, _, _ in
                guard let self = self else { return (tool, ToolStyle(color: .black, width: 4, opacity: 1)) }
                return (tool, self.styleForTool(for: tool) ?? ToolStyle(color: .black, width: 4, opacity: 1))
            }
            .removeDuplicates { lhs, rhs in
                lhs.0 == rhs.0 && lhs.1 == rhs.1     // ToolStyle 需 Equatable
            }
            .eraseToAnyPublisher()
    }

    // 初始化单例
    private init() {
        // 初始化每个工具的默认样式
        presetStyles = Dictionary(uniqueKeysWithValues: allTools.map { tool in
            (tool, tool.presetStyles)
        })
        // 默认每个可用工具选中第 0 个 preset
        presetIndexes = Dictionary(uniqueKeysWithValues: allTools.map { tool in
            let hasPreset = !(tool.presetStyles.isEmpty ?? true)
            return (tool, hasPreset ? 0 : nil)
        })
    }

    func selectTool(_ tool: Tool) { currentTool = tool }
    func selectPreset(for tool: Tool, index: Int) { presetIndexes[tool] = index }

    // 获取某工具的选中样式下标
    func presetIndexForTool(for tool: Tool) -> Int? { presetIndexes[tool] ?? nil }

    // 获取某工具的当前样式
    func styleForTool(for tool: Tool) -> ToolStyle? {
        guard let idx = presetIndexForTool(for: tool),
              let thisPresetStyles = presetStyles[tool],
              thisPresetStyles.indices.contains(idx) else { return nil }
        return thisPresetStyles[idx]
    }

    // 用户点某个 preset；返回是否“第二次点同一项”
    @discardableResult
    func tapPreset(for tool: Tool, index: Int) -> Bool {
        let secondTap = (presetIndexes[tool] == index)
        presetIndexes[tool] = index
        // 应用该 preset 到当前样式
        // let p = tool.presetStyles[index]
        // setStyle(for: tool, color: p.color, width: p.width, opacity: p.opacity)
        return secondTap
    }

    // 更新样式时，务必通过“读->改->写回”的方式触发 @Published 的变更
    // func setStyle(for tool: Tool, color: UIColor? = nil, width: CGFloat? = nil, opacity: CGFloat? = nil) {
    //     var style = toolStyles[tool] ?? ToolStyle(color: nil, width: nil, opacity: nil)
    //     if let color = color { style.color = color }
    //     if let width = width { style.width = width }
    //     if let opacity = opacity { style.opacity = opacity }
    //     toolStyles[tool] = style
    // }

    // 从 Detail 面板实时修改：直接写回“当前选中 preset”的样式
    func setStyleFromDetail(for tool: Tool, updated: ToolStyle) {
        guard let idx = presetIndexForTool(for: tool),
              var thisPresetStyles = presetStyles[tool],
              thisPresetStyles.indices.contains(idx) else { return }
        presetStyles[tool]?[idx] = updated
    }

}
