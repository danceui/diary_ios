import UIKit
enum AnimationState {
    case idle
    case manualFlipping
    case autoFlipping
}

enum AnimationType {
    case manual   // 「手势」请求
    case auto     // 「代码自动」请求
}

struct FlipRequest {
    let direction: PageTurnDirection
    let type: AnimationType
}

enum EasingFunction {
    case linear
    case easeIn
    case easeOut // 快速开始 → 慢停
    case easeInOut // 平滑切换
    case cubicEaseOut // 更有重量感
    case sineEaseOut // iOS 风格柔软动画
    case exponentialEaseOut
    case backEaseOut // 有张力的反馈感

    func apply(_ t: CGFloat) -> CGFloat {
        switch self {
        case .linear:
            return t

        case .easeIn:
            return t * t

        case .easeOut:
            return 1 - pow(1 - t, 2)

        case .easeInOut:
            return t < 0.5
                ? 2 * t * t
                : 1 - pow(-2 * t + 2, 2) / 2

        case .cubicEaseOut:
            return 1 - pow(1 - t, 3)

        case .sineEaseOut:
            return sin(t * .pi / 2)

        case .exponentialEaseOut:
            return t == 1 ? 1 : 1 - pow(2, -10 * t)

        case .backEaseOut:
            let c1: CGFloat = 1.70158
            let c3 = c1 + 1
            return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
        }
    }
}
