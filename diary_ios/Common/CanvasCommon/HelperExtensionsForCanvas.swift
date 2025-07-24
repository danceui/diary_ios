import UIKit
import PencilKit

// MARK: - CGPoint 相关
extension CGPoint {
    func distanceTo(_ point: CGPoint) -> CGFloat {
        hypot(self.x - point.x, self.y - point.y)
    }
}

// MARK: - PKStroke 相关
extension PKStroke {
    func isEqualTo(_ stroke: PKStroke) -> Bool {
        // 快速比较基本属性
        guard self.ink.inkType == stroke.ink.inkType,
            self.ink.color == stroke.ink.color,
            self.path.count == stroke.path.count,
            self.transform == stroke.transform else {
            return false
        }
        // 逐点比较 path
        for i in 0..<self.path.count {
            let p1 = self.path[i].location
            let p2 = stroke.path[i].location
            if p1 != p2 {
                return false
            }
        }
        return true
    }
    
    func intersectsRect(_ rect: CGRect) -> Bool {
        return self.renderBounds.intersects(rect)
    }
}

// MARK: - UIBezierPath 相关
extension UIBezierPath {
}
