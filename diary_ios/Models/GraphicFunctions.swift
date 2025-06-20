import UIKit

func computeShadowWidth(shadowAngle: CGFloat,
                                lightAngle: CGFloat,
                                containerWidth: CGFloat) -> CGFloat {
    if shadowAngle - .pi / 2 >= lightAngle {
        return 0
    } else {
        let numerator = containerWidth * cos(lightAngle - shadowAngle)
        let denominator = cos(lightAngle)
        return numerator / denominator
    }
}

func computeOverlayAlpha(shadowProgress: CGFloat,
                         overlayAlpha: CGFloat) -> CGFloat {
    guard shadowProgress >= 0 && shadowProgress <= 1 else {
        return 0
    }
    return (1 - cos(shadowProgress * .pi)) * overlayAlpha
}