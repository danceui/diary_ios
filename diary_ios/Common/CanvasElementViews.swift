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

    init(sticker: Sticker) {
        self.sticker = sticker
        let size = CGSize(width: 80, height: 80) // 默认大小
        let origin = CGPoint(x: sticker.center.x - size.width / 2,
                             y: sticker.center.y - size.height / 2)
        super.init(frame: CGRect(origin: origin, size: size))

        self.image = UIImage(named: "star")
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
