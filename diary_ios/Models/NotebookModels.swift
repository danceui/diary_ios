import UIKit

enum PageRole {
    case normal
    case cover
    case back
    case empty
}

enum PageSize {
    case a4
    case b5
    
    var singleSize: CGSize {
        switch self {
        case .a4:
            return CGSize(width: 595, height: 842) // A4 (210mm × 297mm in points @72dpi)
        case .b5:
            return CGSize(width: 499, height: 709) // B5 (176mm × 250mm in points @72dpi)
        }
    }
    var doubleSize: CGSize {
        switch self {
        case .a4:
            return CGSize(width: 595 * 2, height: 842) // A4 (210mm × 297mm in points @72dpi)
        case .b5:
            return CGSize(width: 499 * 2, height: 709) // B5 (176mm × 250mm in points @72dpi)
        }
    }
}

enum PageTurnDirection {
    case nextPage
    case lastPage
}

struct PageConstants {
    static let pageSize: PageSize = .a4
    static let pageCornerRadius: CGFloat = 20
    static let pageShadowRadius: CGFloat = 3
    static let pageShadowOpacity: Float = 0.3
    static let leftMaskedCorners: CACornerMask = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    static let rightMaskedCorners: CACornerMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
}

struct NotebookConstants {
    static let defaultZoomScale: CGFloat = 0.8
    static let maxZoomScale: CGFloat = 3.0
    static let minZoomScale: CGFloat = 0.5

    static let spineShadowWidth: CGFloat = 10
    static let spineShadowOpacity: Float = 0.3
    static let spineShadowRadius: CGFloat = 20
}

struct StackConstants {
    static let baseOffset: CGFloat = 5
}
