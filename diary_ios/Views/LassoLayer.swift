import UIKit
import PencilKit

class LassoLayer: UIView {
    var onLassoFinished: ((UIBezierPath) -> Void)?
    var onLassoDragged: ((CGAffineTransform) -> Void)?
    var onLassoDragFinished: ((CGAffineTransform) -> Void)?
    var onStickerTapped: ((CGPoint) -> Void)?

    private var lassoPath = UIBezierPath()
    private var originalLassoPath = UIBezierPath()
    private var lastPoint: CGPoint?
    private var firstPoint: CGPoint?
    private let threshold: CGFloat = 7 // 超过则视为滑动
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
        firstPoint = point
        lastPoint = point

        if let path = shapeLayer.path, path.contains(point) {
            // 如果当前已有路径并且触点在其内, 开启拖动
            isDragging = true
            isDrawing = false
        } else {
            // 否则，还不确定是点击还是绘制，等 touchesMoved 和 touchesEnded 判断
            isDrawing = false
            isDragging = false
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self), let first = firstPoint else { return }
        if !isDragging, !isDrawing {
            let distance = hypot(point.x - first.x, point.y - first.y)
            if distance > threshold {
                // 移动距离超过阈值，开始绘制套索
                isDrawing = true
                lassoPath = UIBezierPath()
                lassoPath.move(to: first)
                lastPoint = first
                shapeLayer.removeAllAnimations()
                shapeLayer.path = lassoPath.cgPath
            } else {
                // 移动距离没有超过阈值, 算作点击, 等待 touchesEnded 处理
                return
            }
        }
        // 继续绘制套索
        guard isDrawing, let last = lastPoint else { return }
        let midPoint = CGPoint(x: (last.x + point.x) / 2, y: (last.y + point.y) / 2)
        lassoPath.addQuadCurve(to: midPoint, controlPoint: last)
        lastPoint = point
        shapeLayer.path = lassoPath.cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return } 
        if isDrawing {
            // 结束绘制套索
            lassoPath.close()
            shapeLayer.path = lassoPath.cgPath
            startWaitingAnimation()
            updateOriginalLassoPath()
            onLassoFinished?(lassoPath)
        } else if !isDragging {
            // 没有拖动也没有画, 说明是轻点, 检查贴纸
            onStickerTapped?(point)
        }
        isDrawing = false
        isDragging = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeLassoPath()
    }

    // MARK: - 拖动手势处理
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isDragging else { return }
        let offset = gesture.translation(in: self)
        let transform = CGAffineTransform(translationX: offset.x, y: offset.y)

        switch gesture.state {
        case .changed:
            onLassoDragged?(transform)
        case .ended, .cancelled:
            onLassoDragFinished?(transform)
        default:
            break
        }
    }

    // MARK: - 套索路径
    func configureLassoPath(path: UIBezierPath) {
        if let copiedPath = path.copy() as? UIBezierPath {
            lassoPath = copiedPath
            shapeLayer.path = lassoPath.cgPath
            startWaitingAnimation()
            updateOriginalLassoPath()
        }
    }

    func updateOriginalLassoPath() {
        if let copiedPath = lassoPath.copy() as? UIBezierPath {
            originalLassoPath = copiedPath
        }
    }

    func updateLassoPath(transform: CGAffineTransform) {
        if let copiedPath = originalLassoPath.copy() as? UIBezierPath {
            copiedPath.apply(transform)
            lassoPath = copiedPath
            shapeLayer.path = lassoPath.cgPath
        }
    }

    func removeLassoPath() {
        isDrawing = false
        isDragging = false
        shapeLayer.removeAllAnimations()
        shapeLayer.path = nil
        lassoPath.removeAllPoints()
        originalLassoPath.removeAllPoints()
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
}
