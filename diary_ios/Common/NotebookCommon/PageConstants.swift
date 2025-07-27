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
    
    var size: CGSize {
        switch self {
        case .a4:
            return CGSize(width: 595, height: 842) // A4 (210mm × 297mm in points @72dpi)
        case .b5:
            return CGSize(width: 499, height: 709) // B5 (176mm × 250mm in points @72dpi)
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
    static let normalBackgroundColor: UIColor = UIColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1) // 浅米色背景
    static let coverBackgroundColor: UIColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) // 浅灰色背景
}