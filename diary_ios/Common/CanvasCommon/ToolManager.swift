import UIKit
import Combine

enum Tool: String, CaseIterable, Identifiable {
    case pen, highlighter, monoline
    case eraser
    case sticker
    case lasso
    var id: String { rawValue } // 稳定 ID

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
            return "paintbrush.pointed.fill"
        case .monoline:
            return "paintbrush.pointed.fill"
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

    var presets: [ToolStyle] {
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

struct ToolStyle: Hashable {
    var color: UIColor?
    var width: CGFloat?
    var opacity: CGFloat?
}

struct ToolPreset: Identifiable, Hashable {
    var tool: Tool
    var index: Int
    var style: ToolStyle
    // 用 tool+index 作为稳定 id，便于 ForEach
    var id: String { "\(tool)#\(index)" }
    // 只按 tool+index 判等，忽略 style
    static func == (lhs: ToolPreset, rhs: ToolPreset) -> Bool {
        lhs.tool == rhs.tool && lhs.index == rhs.index
    }

    // 只按 tool+index 参与哈希
    func hash(into hasher: inout Hasher) {
        hasher.combine(tool)
        hasher.combine(index)
    }
}

protocol ToolObserver: AnyObject {
    func toolDidChange(tool: Tool, style: ToolStyle?)
}

final class ToolManager: ObservableObject {
    static let shared = ToolManager()
    private let debugToolManager = Debuggers.debugToolManager
    @Published private(set) var currentTool: Tool = .pen
    @Published private(set) var presets: [Tool: [ToolPreset]] = [:]
    @Published private(set) var selectedIndex: [Tool: Int] = [:]

    private init() {
        for t in Tool.allCases where t.supportsPresets {
            let p = t.presets.enumerated().map { (i, style) in
                ToolPreset(tool: t, index: i, style: style)
            }
            presets[t] = p
            selectedIndex[t] = 0
        }
    }

    // 合成 publisher
    var toolAndStyle: AnyPublisher<(Tool, ToolStyle?), Never> {
        Publishers.CombineLatest3($currentTool, $presets, $selectedIndex)
            .map { tool, styles, indices -> (Tool, ToolStyle?) in
                guard tool.supportsPresets,
                    let arr = styles[tool],
                    let idx = indices[tool],
                    arr.indices.contains(idx) else { return (tool, nil) }
                if self.debugToolManager { print("📢 [ToolManager] Publisher: New tool \(tool) and style \(idx).") }
                return (tool, arr[idx].style)
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
            let arr = presets[tool],
            arr.indices.contains(index) else { return }
        selectedIndex[tool] = index
    }

    // 外部查询
    func getStyle(for tool: Tool) -> ToolStyle? {
        guard tool.supportsPresets,
            let idx = selectedIndex[tool],
            let arr = presets[tool],
            arr.indices.contains(idx) else { return nil }

        // if debugToolManager { print("⚒️ [ToolManager] Get current style for \(tool).") }
        return arr[idx].style
    }

    func getStyle(for tool: Tool, at index: Int) -> ToolStyle? {
        guard tool.supportsPresets,
            let arr = presets[tool],
            arr.indices.contains(index) else { return nil }

        if debugToolManager { print("⚒️ [ToolManager] Get style for \(tool) at #\(index) preset.") }
        return arr[index].style
    }

    @discardableResult
    func setStyle(for tool: Tool, at index: Int, to updated: ToolStyle) -> Bool {
        guard tool.supportsPresets,
            var arr = presets[tool],
            arr.indices.contains(index) else { return false}

        arr[index].style = updated
        presets[tool] = arr
        if debugToolManager { print("⚒️ [ToolManager] Set style for \(tool) at #\(index) preset.") }
        return true
    }
}
