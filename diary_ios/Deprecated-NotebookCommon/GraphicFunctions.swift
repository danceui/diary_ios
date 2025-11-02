import UIKit
func sineEaseOut(_ t: CGFloat) -> CGFloat {
    return sin(t * .pi / 2)
}

func computeShadowWidth(shadowProgress: CGFloat,
                                lightAngle: CGFloat,
                                containerWidth: CGFloat) -> CGFloat {
    let shadowAngle = shadowProgress * .pi
    if shadowAngle - .pi / 2 >= lightAngle {
        return 0
    } else {
        let numerator = containerWidth * cos(lightAngle - shadowAngle)
        let denominator = cos(lightAngle)
        return numerator / denominator
    }
}

func computeSpineShadowOpacity(absProgress: CGFloat) -> Float {
    let progressThreshold = FlipConstants.progressThreshold
    let shadowOpacity = NotebookConstants.spineShadowOpacity
    let shadowProgress = progressThreshold - abs(progressThreshold - absProgress)
    let shadowOpacityFactor = 1 - cos(Float(shadowProgress) * .pi)
    return Float(shadowOpacity * shadowOpacityFactor)
}

func computeOverlayAlpha(alphaProgress: CGFloat,
                         overlayAlpha: CGFloat) -> CGFloat {
    guard alphaProgress >= 0 && alphaProgress <= 1 else {
        return 0
    }
    return (1 - cos(alphaProgress * .pi)) * overlayAlpha
}

func insetRectSafe(from rect: CGRect, inset: CGFloat) -> CGRect? {
    guard inset.isFinite, inset >= 0, rect.width > 0, rect.height > 0 else { return .zero }

    // 确保 inset 不超过 rect 的一半, 避免 inset 后的矩形变为负值或无效
    let safeInsetX = min(inset, rect.width / 2)
    let safeInsetY = min(inset, rect.height / 2)
    let insetRect = rect.insetBy(dx: safeInsetX, dy: safeInsetY)

    return insetRect
}

func computeXDecay(_ n: Int) -> CGFloat {
    if n == 0 { return 0 }
    else if n == 1 { return log(2.0) * StackConstants.baseOffset }
    else { return 3.0 * log(CGFloat(n)) * StackConstants.baseOffset }
}

func computeYDecay(_ n: Int) -> CGFloat {
    let alpha = 0.8
    return pow(CGFloat(n), alpha) * StackConstants.baseOffset
}