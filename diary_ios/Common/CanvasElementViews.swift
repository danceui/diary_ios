import UIKit
import PencilKit

// MARK: - 笔画
class StrokeBatchView: UIView {
    let strokes: [PKStroke]
    private let imageView = UIImageView()

    init(strokes: [PKStroke], frame: CGRect) {
        self.strokes = strokes
        super.init(frame: frame)
        setupView()
        renderStrokesToImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(imageView)
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFit
        isUserInteractionEnabled = false // 后续可加上交互功能
    }

    private func renderStrokesToImage() {
        // 1. 创建一个 PKDrawing 并附上这些 strokes
        let drawing = PKDrawing(strokes: strokes)

        // 2. 渲染为 UIImage
        let scale = UIScreen.main.scale
        let image = drawing.image(from: bounds, scale: scale)

        imageView.image = image
    }
}

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
        self.isUserInteractionEnabled = false // 暂时不可交互
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// class StickerRenderer {
//     let model: StickerModel
//     let size: CGSize = CGSize(width: 80, height: 80)

//     init(model: StickerModel) {
//         self.model = model
//     }

//     func draw(in context: CGContext) {
//         guard let image = UIImage(named: model.name)?.cgImage else { return }

//         let origin = CGPoint(
//             x: model.center.x - size.width / 2,
//             y: model.center.y - size.height / 2
//         )
//         let rect = CGRect(origin: origin, size: size)
//         context.draw(image, in: rect)
//     }
// }