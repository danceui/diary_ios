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
    /// 找到路径在四个主要方向的极值点（右、上、左、下）
    func cornerPoints() -> (topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint)? {
        var allPoints: [CGPoint] = []
        
        // 遍历 CGPath 所有元素，提取控制点
        cgPath.applyWithBlock { element in
            let points = element.pointee.points
            let count: Int
            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint:
                count = 1
            case .addQuadCurveToPoint:
                count = 2
            case .addCurveToPoint:
                count = 3
            default:
                count = 0
            }
            for i in 0..<count {
                allPoints.append(points[i])
            }
        }
        
        // 计算中心点（质心）
        guard !allPoints.isEmpty else { return nil }
        let center = allPoints.reduce(CGPoint.zero) { partial, p in
            CGPoint(x: partial.x + p.x, y: partial.y + p.y)
        }
        let centerPoint = CGPoint(x: center.x / CGFloat(allPoints.count),
                                  y: center.y / CGFloat(allPoints.count))
        
        // 初始化
        var topLeft = allPoints[0]
        var topRight = allPoints[0]
        var bottomLeft = allPoints[0]
        var bottomRight = allPoints[0]
        
        // 遍历所有点，根据象限选距离最远的点
        for p in allPoints {
            let dx = p.x - centerPoint.x
            let dy = p.y - centerPoint.y
            let dist = hypot(dx, dy)
            
            if dx <= 0 && dy <= 0 { // 左上象限
                if dist > topLeft.distanceTo(centerPoint) {
                    topLeft = p
                }
            } else if dx > 0 && dy <= 0 { // 右上象限
                if dist > topRight.distanceTo(centerPoint) {
                    topRight = p
                }
            } else if dx <= 0 && dy > 0 { // 左下象限
                if dist > bottomLeft.distanceTo(centerPoint) {
                    bottomLeft = p
                }
            } else if dx > 0 && dy > 0 { // 右下象限
                if dist > bottomRight.distanceTo(centerPoint) {
                    bottomRight = p
                }
            }
        }
        return (topLeft, topRight, bottomLeft, bottomRight)
    }
}
