import UIKit
import PencilKit

func isStrokeEqual(_ lhs: PKStroke, _ rhs: PKStroke) -> Bool {
    // 快速比较常用字段（颜色、宽度、笔类型）
    guard lhs.ink.inkType == rhs.ink.inkType,
          lhs.ink.color == rhs.ink.color,
          lhs.path.count == rhs.path.count,
          lhs.transform == rhs.transform else {
        return false
    }
    for i in 0..<lhs.path.count {
        let lPoint = lhs.path[i].location
        let rPoint = rhs.path[i].location
        if lPoint != rPoint {
            return false
        }
    }
    return true
}

func strokeIntersectsRect(stroke: PKStroke, eraserRect: CGRect) -> Bool {
    return stroke.renderBounds.intersects(eraserRect)
}

func mergeUniqueStrokes(existing: [IndexedStroke], new: [IndexedStroke]) -> [IndexedStroke] {
    var result = existing

    for n in new {
        let alreadyExists = result.contains { a in
            a.index == n.index || isStrokeEqual(a.stroke, n.stroke)
        }
        if !alreadyExists { result.append(n) }
    }

    return result
}
