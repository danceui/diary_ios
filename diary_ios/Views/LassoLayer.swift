import UIKit
import PencilKit

class LassoLayer: UIView {
    var onLassoFinished: ((UIBezierPath) -> Void)?
    var onLassoDragged: ((CGAffineTransform) -> Void)?
    var onLassoDragFinished: ((CGAffineTransform) -> Void)?
    var onStickerTapped: ((CGPoint) -> Void)?

    private var lassoPath = UIBezierPath()
    private var originalLassoPath = UIBezierPath()
    private var previousPoint: CGPoint?
    private var firstPoint: CGPoint?
    private var dragStartPoint: CGPoint?
    private var isDrawing = false
    private var isDragging = false

    private let threshold: CGFloat = 7 // 超过则视为滑动
    private let cornerRadius = LassoConstants.cornerRadius

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }   

    // MARK: - 监听触摸
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        firstPoint = point
        previousPoint = point

        // 如果当前已有路径并且触点在其内, 开启拖动
        if let path = shapeLayer.path, path.contains(point) {
            isDragging = true
            isDrawing = false
            dragStartPoint = point
        } else {
            // 否则，还不确定是点击还是绘制，等 touchesMoved 和 touchesEnded 判断
            isDrawing = false
            isDragging = false
            dragStartPoint = nil
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self), let first = firstPoint else { return }
        // 如果不是拖动且不是绘制, 判断是点触还是绘制
        if !isDragging, !isDrawing {
            if point.distanceTo(first) > threshold {
                // 移动距离超过阈值，开始绘制套索
                isDrawing = true
                lassoPath = UIBezierPath()
                lassoPath.move(to: first)
                previousPoint = first
                shapeLayer.removeAllAnimations()
                shapeLayer.path = lassoPath.cgPath
            } else {
                // 移动距离没有超过阈值, 算作点击, 等待 touchesEnded 处理
                return
            }
        }
        // 如果正在拖动, 计算偏移量并应用变换
        if isDragging, let start = dragStartPoint {
            let dx = point.x - start.x
            let dy = point.y - start.y
            let transform = CGAffineTransform(translationX: dx, y: dy)
            onLassoDragged?(transform)
            return
        }
        // 继续绘制套索
        guard isDrawing, let prev = previousPoint else { return }
        let midPoint = CGPoint(x: (prev.x + point.x) / 2, y: (prev.y + point.y) / 2)
        lassoPath.addQuadCurve(to: midPoint, controlPoint: prev)
        previousPoint = point
        shapeLayer.path = lassoPath.cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        // 如果是拖动，计算最终变换
        if isDragging, let start = dragStartPoint {
            let dx = point.x - start.x
            let dy = point.y - start.y
            let transform = CGAffineTransform(translationX: dx, y: dy)
            onLassoDragFinished?(transform)
            // showButtonsOnLassoPath()
        } else if isDrawing {
            // 如果是绘制，结束套索路径
            lassoPath.close()
            shapeLayer.path = lassoPath.cgPath
            startWaitingAnimation()
            updateOriginalLassoPath()
            onLassoFinished?(lassoPath)
            // showButtonsOnLassoPath()
        } else {
            // 没有拖动也没有画, 说明是轻点, 检查贴纸
            onStickerTapped?(point)
        }
        isDrawing = false
        isDragging = false
        dragStartPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeLassoPath()
    }

    // MARK: - 套索路径
    func configureLassoPath(path: UIBezierPath) {
        // 供外部设置套索路径
        if let copiedPath = path.copy() as? UIBezierPath {
            lassoPath = copiedPath
            shapeLayer.path = lassoPath.cgPath
            startWaitingAnimation()
            updateOriginalLassoPath()
            // showButtonsOnLassoPath()
        }
    }

    func updateOriginalLassoPath() {
        // 每次设置套索路径后保存为 originalLassoPath
        if let copiedPath = lassoPath.copy() as? UIBezierPath {
            originalLassoPath = copiedPath
        }
    }

    func updateLassoPath(transform: CGAffineTransform) {
        // 实时更新套索位置
        if let copiedPath = originalLassoPath.copy() as? UIBezierPath {
            copiedPath.apply(transform)
            lassoPath = copiedPath
            shapeLayer.path = lassoPath.cgPath
        }
    }

    func removeLassoPath() {
        isDrawing = false
        isDragging = false
        dragStartPoint = nil
        shapeLayer.removeAllAnimations()
        shapeLayer.path = nil
        lassoPath.removeAllPoints()
        originalLassoPath.removeAllPoints()
    }

    // MARK: - 套索样式
    private func startWaitingAnimation() {
        // 动态虚线滚动
        let dashAnimation = CABasicAnimation(keyPath: "lineDashPhase")
        dashAnimation.fromValue = 0
        dashAnimation.toValue = 10
        dashAnimation.duration = 0.4
        dashAnimation.repeatCount = .infinity
        shapeLayer.add(dashAnimation, forKey: "dashPhase")
    }
    
    // MARK: - 套索按钮
    private func showButtonsOnLassoPath() {
        let rect = lassoPath.bounds
        
        func createButton(imageName: String, tint: UIColor, buttonSize: CGFloat, action: Selector) -> UIButton {
            let btn = UIButton(type: .custom)
            btn.setImage(UIImage(systemName: imageName), for: .normal)
            btn.tintColor = tint
            btn.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
            btn.imageView?.contentMode = .scaleAspectFit
            btn.backgroundColor = .clear
            btn.addTarget(self, action: action, for: .touchUpInside)
            return btn
        }

        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)

        let deleteBtn = createButton(imageName: "xmark.circle.fill", tint: .systemRed, buttonSize: 65, action: #selector(didTapDelete))
        deleteBtn.center = topLeft 

        let copyBtn = createButton(imageName: "rectangle.fill.on.rectangle.fill", tint: .systemBlue, buttonSize: 55, action: #selector(didTapCopy))
        copyBtn.center = topRight 

        let scaleBtn = createButton(imageName: "crop.rotate", tint: .darkGray, buttonSize: 80, action: #selector(didTapScale))
        scaleBtn.center = bottomRight

        // 直接添加到 self 上
        addSubview(deleteBtn)
        addSubview(copyBtn)
        addSubview(scaleBtn)
    }

    @objc private func didTapDelete() {
        print("Delete button tapped")
        removeLassoPath()
    }

    @objc private func didTapCopy() {
        print("Copy button tapped")
    }

    @objc private func didTapScale() {
        print("Scale button tapped")
    }
}
