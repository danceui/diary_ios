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

func computeXDecay(_ distance: Int, scale: CGFloat = 1.5, alpha: CGFloat = 0.6) -> CGFloat {
    return pow(CGFloat(distance), alpha) * scale
}

func computeYDecay(_ distance: Int, scale: CGFloat = 1.0, alpha: CGFloat = 0.6) -> CGFloat {
    return pow(CGFloat(distance), alpha) * scale
}