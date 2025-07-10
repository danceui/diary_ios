import UIKit
enum Tool {
    case pen, eraser, highlighter
}

protocol ToolObserver: AnyObject {
    func toolDidChange(tool: Tool, color: UIColor, width: CGFloat)
}

class ToolManager {
    static let shared = ToolManager()
    
    private init() {}
    var currentTool: Tool = .pen { didSet { notifyToolChange() } }
    var strokeColor: UIColor = .black { didSet { notifyToolChange() } }
    var strokeWidth: CGFloat = 5.0 { didSet { notifyToolChange() } }

    private var observers = NSHashTable<AnyObject>.weakObjects()

    func addObserver(_ observer: ToolObserver) {
        observers.add(observer)
        observer.toolDidChange(tool: currentTool, color: strokeColor, width: strokeWidth)
    }

    private func notifyToolChange() {
        for observer in observers.allObjects {
            if let observer = observer as? ToolObserver {
                observer.toolDidChange(tool: currentTool, color: strokeColor, width: strokeWidth)
            }
        }
    }
}