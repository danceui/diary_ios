import UIKit

class StickerLayer: UIView, CanvasLayer {
    var stickers: [Sticker] = []

    func addSticker(_ sticker: Sticker) {
        stickers.append(sticker)
        updateStickersView()
    }

    // func removeSticker(withId id: UUID) {
    //     stickers.removeAll { $0.id == id }
    //     updateStickersView()
    // }

    func updateStickersView() {
        self.subviews.forEach { $0.removeFromSuperview() }
        for sticker in stickers {
            let view = StickerView(model: sticker)
            self.addSubview(view)
        }
    }

    // MARK: - 点击添加贴纸的功能
    private var onStickerAdded: ((Sticker) -> Void)?
    private var readyToAddSticker = true

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard readyToAddSticker else { return }
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        let sticker = Sticker(id: UUID(), center: location)
        // let view = StickerView(model: sticker)
        // stickers.append(view)
        // addSubview(view)
        onStickerAdded?(sticker)
        readyToAddSticker = false
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        readyToAddSticker = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        readyToAddSticker = true
    }
}