import UIKit
import SwiftUI

struct ToolConstants {
}

struct ToolbarConstants {
    static let toolSelectionHeight: CGFloat = 160.0
    static let stylePresetHeight: CGFloat = 160.0
    static let leadingPadding: CGFloat = 30.0
    static let trailingPadding: CGFloat = 30.0
    static let topPadding: CGFloat = 10.0
    static let popoverGap: CGFloat = 12
    static let iconSize: CGFloat = 30.0
    static let iconPadding: CGFloat = 7.0
    static let iconSpacing: CGFloat = 4.0
    static let toolbarBackgroundColor: UIColor = .systemBackground
    static let toolbarButtonColor: UIColor = .systemBlue
    static let toolbarButtonSelectedColor: UIColor = .systemGreen
}

struct PreviewConstants {
    static let penMinWidth: CGFloat = 0.8
    static let penMinWidthRatio: CGFloat = 0.5
    static let penMaxWidthRatio: CGFloat = 0.8
    static let steps: Int = 10
    static let segmentCount = 8
    static let previewColors: [Color] = [
        .red.opacity(1.0),
        .blue.opacity(0.7),
        .green.opacity(0.5),
        .orange.opacity(0.8),
        .purple.opacity(0.6),
        .pink.opacity(1.0),
        .yellow.opacity(0.5),
        .pink.opacity(0.9)
    ]
}
