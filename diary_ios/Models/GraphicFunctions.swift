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