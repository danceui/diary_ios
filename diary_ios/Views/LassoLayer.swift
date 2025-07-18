import UIKit
import PencilKit

class LassoLayer: UIView {
    var onLassoFinished: ((UIBezierPath) -> Void)?
    var onLassoDragged: ((CGAffineTransform) -> Void)?
    var onLassoDragFinished: ((CGAffineTransform) -> Void)?

    private var lassoPath = UIBezierPath()
    private var originalLassoPath = UIBezierPath()
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
        panGesture.cancelsTouchesInView = false
        addGestureRecognizer(panGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }   

    // MARK: - 监听触摸
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }

        // 如果当前已经存在一个闭合的套索路径，并且用户点击在套索内 —— 说明是要拖动
        if shapeLayer.path?.contains(point) == true {
            isDragging = true
            isDrawing = false
        } else {
            // 否则，说明是要重新开始套索选择
            isDrawing = true
            isDragging = false
            lassoPath = UIBezierPath()
            lassoPath.move(to: point)
            lastPoint = point
            shapeLayer.removeAllAnimations()
            shapeLayer.path = lassoPath.cgPath
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isDragging, isDrawing, let point = touches.first?.location(in: self), let last = lastPoint else { return }
        let midPoint = CGPoint(x: (last.x + point.x) / 2, y: (last.y + point.y) / 2)
        lassoPath.addQuadCurve(to: midPoint, controlPoint: last)
        lastPoint = point
        shapeLayer.path = lassoPath.cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDrawing {
            isDrawing = false
            lassoPath.close()
            shapeLayer.path = lassoPath.cgPath
            startWaitingAnimation()
            if let copiedPath = lassoPath.copy() as? UIBezierPath {
                originalLassoPath = copiedPath
            }
            onLassoFinished?(lassoPath)
        } else if isDragging {
            isDragging = false
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeLassoPath()
    }

    // MARK: - 手势处理
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isDragging else { return }
        let offset = gesture.translation(in: self)
        let transform = CGAffineTransform(translationX: offset.x, y: offset.y)

        switch gesture.state {
        case .changed:
            onLassoDragged?(transform)
            updateLassoPath(transform: transform)
        case .ended, .cancelled:
            onLassoDragFinished?(transform)
        default:
            break
        }
    }

    func updateLassoPath(transform: CGAffineTransform) {
        if let copiedPath = originalLassoPath.copy() as? UIBezierPath {
            copiedPath.apply(transform)
            lassoPath = copiedPath
            shapeLayer.path = lassoPath.cgPath
        }
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

    func removeLassoPath() {
        isDrawing = false
        isDragging = false
        shapeLayer.removeAllAnimations()
        shapeLayer.path = nil
    }
}
