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
                ToolStyle(color: UIColor.black, width: 4, opacity: 1.0),
                ToolStyle(color: UIColor.blue, width: 6, opacity: 1.0),
                ToolStyle(color: UIColor.red, width: 3, opacity: 1.0)
            ]
        case .highlighter:
            return [
                ToolStyle(color: UIColor.yellow.withAlphaComponent(0.5), width: 10, opacity: 0.5),
                ToolStyle(color: UIColor.green.withAlphaComponent(0.5), width: 12, opacity: 0.4),
                ToolStyle(color: UIColor.orange.withAlphaComponent(0.5), width: 14, opacity: 0.6)
            ]
        case .monoline:
            return [
                ToolStyle(color: UIColor.black, width: 2, opacity: 1.0),
                ToolStyle(color: UIColor.gray, width: 3, opacity: 1.0)
            ]
        default:
            return []
        }
    }
}

let allTools: [Tool] = [.pen, .highlighter, .monoline, .eraser, .sticker, .lasso]

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
        toolStyles = [
            .pen: ToolStyle(color: .black, width: 4, opacity: 1.0),
            .highlighter: ToolStyle(color: UIColor.yellow, width: 6, opacity: 0.5),
            .monoline: ToolStyle(color: .black, width: 2, opacity: 1.0),
            .eraser: ToolStyle(color: nil, width: 10, opacity: nil),
            .sticker: ToolStyle(color: nil, width: nil, opacity: nil),
            .lasso: ToolStyle(color: nil, width: nil, opacity: nil)
        ]
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
