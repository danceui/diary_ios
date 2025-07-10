import UIKit

struct Sticker {
    var id: UUID
    var center: CGPoint
}

// 贴纸视图（仅显示，不支持交互）
class StickerView: UIImageView {
    var model: Sticker

    init(model: Sticker) {
        self.model = model
        let size = CGSize(width: 80, height: 80) // 默认大小
        let origin = CGPoint(x: model.center.x - size.width / 2,
                             y: model.center.y - size.height / 2)
        super.init(frame: CGRect(origin: origin, size: size))

        self.image = UIImage(named: model.imageName)
        self.isUserInteractionEnabled = false // 暂时不可交互
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}