import UIKit
enum FlipState {
    case idle
    case flippingToNext(progress: CGFloat)
    case flippingToLast(progress: CGFloat)

    var isFlipping: Bool {
        switch self {
        case .idle: return false
        default: return true
        }
    }

    var direction: PageTurnDirection? {
        switch self {
        case .flippingToNext: return .nextPage
        case .flippingToLast: return .lastPage
        case .idle: return nil
        }
    }
}