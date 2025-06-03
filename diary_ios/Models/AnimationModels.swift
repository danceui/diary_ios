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