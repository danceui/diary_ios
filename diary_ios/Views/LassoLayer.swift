import UIKit
import PencilKit

class LassoLayer: UIView {
    var onLassoFinished: ((UIBezierPath) -> Void)?

    private var lassoPath = UIBezierPath()
    private var lastPoint: CGPoint?
    private var isDrawing = false

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.systemBlue.setStroke()
        lassoPath.stroke()
    }

    // MARK: - 监听触摸
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        isDrawing = true
        lassoPath = UIBezierPath()
        lassoPath.move(to: point)
        lastPoint = point
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing, let point = touches.first?.location(in: self), let last = lastPoint else { return }
        let midPoint = CGPoint(x: (last.x + point.x) / 2, y: (last.y + point.y) / 2)
        lassoPath.addQuadCurve(to: midPoint, controlPoint: last)
        lastPoint = point
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawing = false
        lassoPath.close()
        onLassoFinished?(lassoPath)
    }
}