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
    let id = UUID()
    var tool: Tool
    var style: ToolStyle
}

protocol ToolObserver: AnyObject {
    func toolDidChange(tool: Tool, style: ToolStyle?)
}

final class ToolManager: ObservableObject {
    static let shared = ToolManager()
    private let debugToolManager = Debuggers.debugToolManager
    @Published private(set) var currentTool: Tool = .pen
    @Published private(set) var presets: [Tool: [ToolPreset]] = [:]
    @Published private(set) var selectedPresetID: [Tool: UUID] = [:]
    var currentPresets: [ToolPreset] { presets[currentTool] ?? [] }

    private init() {
        for t in Tool.allCases where t.supportsPresets {
            let list = t.presets.map { style in ToolPreset(tool: t, style: style) }
            presets[t] = list
            selectedPresetID[t] = list.first?.id
        }
    }

    // 合成 publisher
    var toolAndStyle: AnyPublisher<(Tool, ToolStyle?), Never> {
        Publishers.CombineLatest3($currentTool, $presets, $selectedPresetID)
            .map { tool, styles, selected -> (Tool, ToolStyle?) in
                guard tool.supportsPresets,
                    let arr = styles[tool],
                    let id = selected[tool],
                    let preset = arr.first(where: { $0.id == id }) else { return (tool, nil) }
                return (tool, preset.style)
            }
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .eraseToAnyPublisher()
    }

    // 外部操作
    func selectTool(_ tool: Tool) { currentTool = tool }
    
    func selectPreset(for tool: Tool, id: UUID) {
        guard let arr = presets[tool], arr.contains(where: { $0.id == id }) else { return }
        selectedPresetID[tool] = id
    }

    // 外部查询
    func getStyle(for tool: Tool) -> ToolStyle? {
        guard let id = selectedPresetID[tool],
              let p = presets[tool]?.first(where: { $0.id == id }) else { return nil }
        return p.style
    }

    func getStyle(for tool: Tool, id: UUID) -> ToolStyle? {
        guard let id = selectedPresetID[tool],
              let p = presets[tool]?.first(where: { $0.id == id }) else { return nil }
        return p.style
    }

    @discardableResult
    func setStyle(for tool: Tool, id: UUID, to updated: ToolStyle) -> Bool {
        guard var arr = presets[tool], let i = arr.firstIndex(where: { $0.id == id }) else { return false }
        arr[i].style = updated
        presets[tool] = arr
        if debugToolManager { print("🎛️ [ToolManager] Set style for \(tool).") }
        return true
    }
}
