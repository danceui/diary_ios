import UIKit

struct FlipConstants {
    // 翻页动画相关常量
    static let baseVelocity: CGFloat = 1000
    static let baseDuration: TimeInterval = 0.4
    static let progressThreshold: CGFloat = 0.499
    static let velocityThreshold: CGFloat = 800
    static let minSpeedFactor: CGFloat = 1
    static let maxSpeedFactor: CGFloat = 1.5
    static let transformm34: CGFloat = -1 / 2200

    static let epsilon: CGFloat = 0.01

    // 阴影相关常量
    static let lightAngle: CGFloat = .pi / 12
    static let thicknessScaleSensitivity: CGFloat = 0.4
    static let largerOverlayAlpha: CGFloat = 0.2
    static let smallerOverlayAlpha: CGFloat = 0.2
    static let flipShadowOffset: CGFloat = 5
    static let flipShadowRadius: CGFloat = 30
    static let flipShadowOpacity: Float = 0.3
    static let flipShadowInset: CGFloat = 30
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
