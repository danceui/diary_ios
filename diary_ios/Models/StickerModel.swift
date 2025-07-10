import UIKit

struct Sticker: {
    var id: UUID
    var center: CGPoint
    var scale: CGFloat
    var rotation: CGFloat
}

class StickerView: UIImageView {
    var model: Sticker

    init(model: Sticker) {
        self.model = model
        super.init(frame: ...)
        self.image = UIImage(named: model.imageName)
        setupGestures()
    }

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(pan)
        self.addGestureRecognizer(pinch)
        self.addGestureRecognizer(rotate)
    }

    // Implement gesture handlers...
}