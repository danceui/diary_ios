import UIKit

func format(_ value: CGFloat) -> String {
    return String(format: "%.1f", value)
}

func formatPoint(_ p: CGPoint) -> String {
    return "(\(format(p.x)), \(format(p.y)))"
}

func formatSize(_ s: CGSize) -> String {
    return "(\(format(s.width)), \(format(s.height)))"
}

func formatRect(_ r: CGRect) -> String {
    return "(\(format(r.origin.x)), \(format(r.origin.y)), \(format(r.size.width)), \(format(r.size.height)))"
}

func easeInOutCubic(_ x: CGFloat) -> CGFloat {
    return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
}