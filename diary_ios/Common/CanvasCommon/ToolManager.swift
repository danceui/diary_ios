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
                ToolStyle(color: UIColor.yellow, width: 4, opacity: 0.5),
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

class ToolManager {
    static let shared = ToolManager()
    private init() {
        toolStyles = Dictionary(uniqueKeysWithValues: allTools.map { tool in
            let defaultStyle = tool.presetStyles.first ?? ToolStyle(color: nil, width: nil, opacity: nil)
            return (tool, defaultStyle)
        })
    }
    
    var currentTool: Tool = .pen { didSet { notifyToolChange() } }
    private var observers = NSHashTable<AnyObject>.weakObjects()
    private var toolStyles: [Tool: ToolStyle] = [:]

    func addObserver(_ observer: ToolObserver) {
        observers.add(observer)
        observer.toolDidChange(tool: currentTool, style: toolStyles[currentTool])
    }

    func removeObserver(_ observer: ToolObserver) {
        observers.remove(observer)
    }

    private func notifyToolChange() {
        let style = toolStyles[currentTool]
        for observer in observers.allObjects {
            (observer as? ToolObserver)?.toolDidChange(tool: currentTool, style: toolStyles[currentTool])
        }
    }

    func style(for tool: Tool) -> ToolStyle? {
        return toolStyles[tool]
    }

    func setStyle(for tool: Tool, color: UIColor? = nil, width: CGFloat? = nil, opacity: CGFloat? = nil) {
        var style = toolStyles[tool] ?? ToolStyle(color: nil, width: nil, opacity: nil)
        if let color = color { style.color = color }
        if let width = width { style.width = width }
        if let opacity = opacity { style.opacity = opacity }
        toolStyles[tool] = style

        // 如果是当前工具，主动刷新 UI
        if tool == currentTool {
            notifyToolChange()
        }
    }
}
