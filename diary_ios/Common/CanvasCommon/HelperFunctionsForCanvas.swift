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

func mergeUniqueStrokes(existing: [PKStroke], new: [PKStroke]) -> [PKStroke] {
    var result = existing

    for newStroke in new {
        let alreadyExists = result.contains(where: { isStrokeEqual($0, newStroke) })
        if !alreadyExists { result.append(newStroke) }
    }

    return result
}