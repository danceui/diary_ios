import UIKit

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