import UIKit

struct FlipConstants {
    static let baseVelocity: CGFloat = 1000
    static let baseDuration: TimeInterval = 0.4
    static let progressThreshold: CGFloat = 0.499
    static let velocityThreshold: CGFloat = 800
    static let minSpeedFactor: CGFloat = 1
    static let maxSpeedFactor: CGFloat = 1.5
    static let epsilon: CGFloat = 0.01
    static let lightAngle: CGFloat = .pi / 12
    static let thicknessScaleSensitivity: CGFloat = 0.4
    static let transformm34: CGFloat = -1 / 2000
    static let largerOverlayAlpha: CGFloat = 0.25
    static let smallerOverlayAlpha: CGFloat = 0.15
}

struct FlipRequest {
    let direction: PageTurnDirection
    let type: AnimationType
}

enum AnimationState {
    case idle // 空闲状态，等待翻页请求
    case manualFlipping // 手势翻页中
    case autoFlipping // 代码翻页中
}

enum AnimationType {
    case manual // 手势发起的翻页
    case auto // 代码发起的翻页
}
