import UIKit
import PencilKit

class LassoLayer: UIView {
    var onLassoFinished: ((UIBezierPath) -> Void)?
    var onLassoDragged: ((CGPoint) -> Void)?

    private var lassoPath = UIBezierPath()
    private var lastPoint: CGPoint?
    private var isDrawing = false
    private var isDragging = false

    // 用于绘制虚线套索路径
    private let shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.systemBlue.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1.5
        layer.lineDashPattern = [6, 4] // 6pt 实线 + 4pt 空白
        return layer
    }()

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = true
        layer.addSublayer(shapeLayer)

        // 添加手势识别器
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
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
        shapeLayer.removeAllAnimations()
        shapeLayer.path = lassoPath.cgPath
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing, let point = touches.first?.location(in: self), let last = lastPoint else { return }
        let midPoint = CGPoint(x: (last.x + point.x) / 2, y: (last.y + point.y) / 2)
        lassoPath.addQuadCurve(to: midPoint, controlPoint: last)
        lastPoint = point
        shapeLayer.path = lassoPath.cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawing = false
        lassoPath.close()
        shapeLayer.path = lassoPath.cgPath
        startWaitingAnimation()
        onLassoFinished?(lassoPath)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawing = false
        shapeLayer.path = nil
    }

    // MARK: - 手势处理
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isDragging else { return }

        let delta = gesture.translation(in: self)
        onLassoDragged?(offset: delta)
        gesture.setTranslation(.zero, in: self)
    }

    // MARK: - 等待动画
    private func startWaitingAnimation() {
        // 动态虚线滚动
        let dashAnimation = CABasicAnimation(keyPath: "lineDashPhase")
        dashAnimation.fromValue = 0
        dashAnimation.toValue = 10
        dashAnimation.duration = 0.4
        dashAnimation.repeatCount = .infinity
        shapeLayer.add(dashAnimation, forKey: "dashPhase")
    }

    func clearLasso() {
        isDragging = false
        shapeLayer.removeAllAnimations()
        shapeLayer.path = nil
    }
}