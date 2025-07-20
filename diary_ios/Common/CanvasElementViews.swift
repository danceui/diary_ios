import UIKit
import PencilKit

// MARK: - 笔画
typealias IndexedStroke = (index: Int, stroke: PKStroke)

// MARK: - 贴纸
struct Sticker {
    var id: UUID
    var center: CGPoint
    var name: String
}

// 贴纸视图（仅显示，不支持交互）
class StickerView: UIImageView {
    var sticker: Sticker
    var lassoPath: UIBezierPath?

    init(sticker: Sticker) {
        self.sticker = sticker
        let size = CGSize(width: 80, height: 80) // 默认大小
        let origin = CGPoint(x: sticker.center.x - size.width / 2,
                             y: sticker.center.y - size.height / 2)
        super.init(frame: CGRect(origin: origin, size: size))

        self.image = UIImage(named: "star")
        self.isUserInteractionEnabled = false

        // if let image = self.image {
        //     if let path = generateLassoPathFromAlpha(image: image, in: self.bounds) {
        //         path.apply(CGAffineTransform(translationX: self.frame.origin.x, y: self.frame.origin.y))
        //         self.lassoPath = path
        //     }
        // }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
