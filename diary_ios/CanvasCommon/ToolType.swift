import UIKit
enum Tool {
    case pen, eraser, highlighter
}

class ToolType {
    var currentTool: Tool = .pen
    var strokeColor: UIColor = .black
    var strokeWidth: CGFloat = 5.0
}
