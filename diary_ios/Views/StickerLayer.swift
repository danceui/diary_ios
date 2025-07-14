import UIKit

class StickerLayer: UIView {
    var currentTool: Tool = .sticker
    var readyToAddSticker = true
    var onStickerAdded: ((Sticker) -> Void)?

    var stickers: [Sticker] = []
    var stickerViews: [StickerView] = []

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
        guard let touch = touches.first else { return }

        if currentTool.isSticker {
            guard readyToAddSticker else { return }
            let sticker = Sticker(id: UUID(), center: touch.location(in: self), name: "star")
            onStickerAdded?(sticker)
            readyToAddSticker = false
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchFinished()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchFinished()
    }

    private func handleTouchFinished() {
        readyToAddSticker = true
    }

    // MARK: - 切换工具
    func toolDidChange(tool: Tool) {
        currentTool = tool
    }
}