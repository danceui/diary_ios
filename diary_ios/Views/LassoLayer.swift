import UIKit
import PencilKit

class LassoLayer: UIView {
    private var lassoPath = UIBezierPath()
    private var isDrawing = false
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.systemBlue.setStroke()
        lassoPath.stroke()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        isDrawing = true
        lassoPath = UIBezierPath()
        lassoPath.move(to: point)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing, let point = touches.first?.location(in: self) else { return }
        lassoPath.addLine(to: point)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawing = false
        lassoPath.close()
        // delegate?.lassoSelectionFinished(with: performHitTesting())
    }
}