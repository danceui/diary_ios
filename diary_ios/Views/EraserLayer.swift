import UIKit
import PencilKit

protocol EraserLayerDelegate: AnyObject {
    func applyEraser(eraserLocation: CGPoint, eraserSize: CGFloat)
    func commitEraseCommand()
}

class EraserLayer: UIView {
    weak var eraseDelegate: EraserLayerDelegate?

    private let eraserPreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 1 // 先设为1，后面动态更新
        view.isHidden = true
        return view
    }()

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = true
        addSubview(eraserPreviewView)
        eraserPreviewView.isHidden = true
    }

    // MARK: - 监听触摸
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let eraserSize: CGFloat = 20 // 可根据实际需要动态设置
        let frame = CGRect(x: location.x - eraserSize / 2,
                        y: location.y - eraserSize / 2,
                        width: eraserSize,
                        height: eraserSize)
        eraserPreviewView.frame = frame
        eraserPreviewView.layer.cornerRadius = eraserSize / 2
        eraserPreviewView.isHidden = false
        eraseDelegate?.applyEraser(eraserLocation: location, eraserSize: 4)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        eraserPreviewView.isHidden = true
        eraseDelegate?.commitEraseCommand()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        eraserPreviewView.isHidden = true
        eraseDelegate?.commitEraseCommand()
    }
}