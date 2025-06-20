import UIKit

struct PageConstants {
    static let defaultPageSize: PaperSize = .a4
    static let defaultPageRole: PageRole = .normal
    static let defaultCornerRadius: CGFloat = 20 // 页面圆角
}

struct StackConstants {
    static let baseOffset: CGFloat = 5
}

enum PageRole {
    case normal
    case cover
    case back
    case empty
}

enum PaperSize {
    case a4
    case b5
    case a4a4
    case custom(width: CGFloat, height: CGFloat)
    
    var size: CGSize {
        switch self {
        case .a4:
            return CGSize(width: 595, height: 842) // A4 (210mm × 297mm in points @72dpi)
        case .a4a4:
            return CGSize(width: 595 * 2, height: 842) // A4 (210mm × 297mm in points @72dpi)
        case .b5:
            return CGSize(width: 499, height: 709) // B5 (176mm × 250mm in points @72dpi)
        case .custom(let width, let height):
            return CGSize(width: width, height: height)
        }
    }
}

enum PageTurnDirection {
    case nextPage
    case lastPage
}