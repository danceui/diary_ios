import UIKit

class StickerLayer: UIView {
    var readyToAddSticker = true
    var onStickerAdded: ((Sticker) -> Void)?
    var stickers: [Sticker] = []
    var stickerViews: [StickerView] = []
    var isEmpty: Bool {
        return stickers.isEmpty && stickerViews.isEmpty
    }

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - 监听触摸
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first, readyToAddSticker else { return }
        let sticker = Sticker(id: UUID(), center: touch.location(in: self), name: "star")
        onStickerAdded?(sticker)
        readyToAddSticker = false
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        readyToAddSticker = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        readyToAddSticker = true
    }
}
