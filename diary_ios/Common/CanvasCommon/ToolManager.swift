import UIKit
import Combine

enum Tool: String, CaseIterable, Identifiable {
    case pen, monoline, highlighter
    case eraser
    case sticker
    case lasso
    var id: String { rawValue } // 稳定 ID

    var isBrush: Bool { self == .pen || self == .monoline || self == .highlighter }
    var isSticker: Bool { self == .sticker }
    var isEraser: Bool { self == .eraser }
    var isLasso: Bool { self == .lasso }

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

    var brushPresets: [BrushStyle]? {
        switch self {
        case .pen:
            return [
                BrushStyle(color: UIColor.black, width: 2, opacity: 1.0),
                BrushStyle(color: UIColor.blue, width: 4, opacity: 0.8),
                BrushStyle(color: UIColor.red, width: 6, opacity: 0.6)
            ]
        case .monoline:
            return [
                BrushStyle(color: UIColor.black, width: 4, opacity: 1.0),
                BrushStyle(color: UIColor.gray, width: 6, opacity: 0.8),
                BrushStyle(color: UIColor.red, width: 8, opacity: 0.6)
            ]
        case .highlighter:
            return [
                BrushStyle(color: UIColor.black, width: 4, opacity: 0.5),
                BrushStyle(color: UIColor.green, width: 6, opacity: 0.4),
                BrushStyle(color: UIColor.orange, width: 8, opacity: 0.6)
            ]
        default:
            return nil
        }
    }
}

struct BrushStyle: Hashable, Equatable {
    var color: UIColor
    var width: CGFloat
    var opacity: CGFloat

    static func == (lhs: BrushStyle, rhs: BrushStyle) -> Bool {
        lhs.width == rhs.width &&
        lhs.opacity == rhs.opacity &&
        lhs.color == rhs.color
    }
}

struct BrushPreset: Identifiable, Hashable {
    let id = UUID()
    var tool: Tool
    var style: BrushStyle
}

protocol ToolObserver: AnyObject {
    func toolDidChange(tool: Tool, style: BrushStyle?)
}

final class ToolManager: ObservableObject {
    static let shared = ToolManager()
    private let debugToolManager = Debuggers.debugToolManager
    @Published private(set) var currentTool: Tool = .pen
    @Published private(set) var presets: [Tool: [BrushPreset]] = [:]
    @Published private(set) var selectedPresetID: [Tool: UUID] = [:]
    var currentPresets: [BrushPreset] { presets[currentTool] ?? [] }

    private init() {
        for t in Tool.allCases {
            guard t.isBrush, let defaultPresets = t.brushPresets else { continue }
            let list = defaultPresets.map { BrushPreset(tool: t, style: $0) }
            presets[t] = list
            selectedPresetID[t] = list.first?.id
        }
    }

    // 合成 publisher
    var toolAndStyle: AnyPublisher<(Tool, BrushStyle?), Never> {
        Publishers.CombineLatest3($currentTool, $presets, $selectedPresetID)
            .map { tool, presets, selected -> (Tool, BrushStyle?) in
                guard tool.isBrush,
                    let arr = presets[tool],
                    let id = selected[tool],
                    let preset = arr.first(where: { $0.id == id }) else { return (tool, nil) }
                return (tool, preset.style)
            }
            .removeDuplicates { (lhs, rhs) in lhs.0 == rhs.0 && lhs.1 == rhs.1 }
            .eraseToAnyPublisher()
    }

    // Actions
    func selectTool(_ tool: Tool) { currentTool = tool }
    
    func selectPreset(for tool: Tool, id: UUID) {
        guard tool.isBrush, let arr = presets[tool], arr.contains(where: { $0.id == id }) else { return }
        selectedPresetID[tool] = id
    }

    // Queries
    func getBrushStyle(for tool: Tool) -> BrushStyle? {
        guard tool.isBrush,
              let id = selectedPresetID[tool],
              let p = presets[tool]?.first(where: { $0.id == id }) else { return nil }
        return p.style
    }

    func getBrushStyle(for tool: Tool, id: UUID) -> BrushStyle? {
        guard tool.isBrush,
              let p = presets[tool]?.first(where: { $0.id == id }) else { return nil }
        return p.style
    }

    @discardableResult
    func setBrushStyle(for tool: Tool, id: UUID, to updated: BrushStyle) -> Bool {
        guard tool.isBrush,
              var arr = presets[tool],
              let i = arr.firstIndex(where: { $0.id == id }) else { return false }
        arr[i].style = updated
        presets[tool] = arr
        if debugToolManager { print("🎛️ [ToolManager] Set style for \(tool).") }
        return true
    }
}
