import UIKit
import PencilKit

class LassoLayer: UIView {
    var onLassoFinished: ((UIBezierPath) -> Void)?
    var onStickerTapped: ((CGPoint) -> Void)?
    var onLassoDragged: ((CGAffineTransform) -> Void)?
    var onLassoDragFinished: ((CGAffineTransform) -> Void)?
    var onDelete: (() -> Void)?

    private var lassoPath = UIBezierPath()
    private var originalLassoPath = UIBezierPath()
    private var previousPoint: CGPoint?
    private var firstPoint: CGPoint?
    private var dragStartPoint: CGPoint?
    private var isDrawing = false
    private var isDragging = false
    
    private var deleteBtn: UIButton?
    private var copyBtn: UIButton?
    private var scaleBtn: UIButton?

    private let threshold: CGFloat = 7 // 超过则视为滑动
    // private let size: CGFloat = LassoConstants.lassoButtonSize

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
            removeLassoPath()
            isDrawing = false
            isDragging = false
            dragStartPoint = nil
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self), let first = firstPoint else { return }
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
            updateOriginalLassoPath()
        } else if isDrawing {
            // 如果是绘制，结束套索路径
            lassoPath.close()
            shapeLayer.path = lassoPath.cgPath
            onLassoFinished?(lassoPath)
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
            createButtonsOnLassoPath()
        }
    }

    private func updateOriginalLassoPath() {
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
        // 更新按钮位置
        updateButtonsWithLassoPath()
    }

    func removeLassoPath() {
        // 在 undo 时清除套索
        isDrawing = false
        isDragging = false
        dragStartPoint = nil
        shapeLayer.removeAllAnimations()
        shapeLayer.path = nil
        lassoPath.removeAllPoints()
        originalLassoPath.removeAllPoints()
        removeButtons()
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
    private func createButtonsOnLassoPath() {
        func createButton(imageName: String, tint: UIColor, size: CGFloat, action: Selector) -> UIButton {
            let btn = UIButton(type: .custom)
            btn.frame = CGRect(x: 0, y: 0, width: size, height: size)
            btn.backgroundColor = .clear
            btn.addTarget(self, action: action, for: .touchUpInside)
            let config = UIImage.SymbolConfiguration(pointSize: size, weight: .regular)
            let image = UIImage(systemName: imageName, withConfiguration: config)
            btn.setImage(image, for: .normal)
            btn.tintColor = tint
            return btn
        }

        deleteBtn = createButton(imageName: "xmark.circle.fill", tint: .systemRed, size: 33, action: #selector(didTapDelete))
        copyBtn = createButton(imageName: "rectangle.fill.on.rectangle.fill", tint: .systemBlue, size: 32, action: #selector(didTapCopy))
        scaleBtn = createButton(imageName: "crop.rotate", tint: .darkGray, size: 40, action: #selector(didTapScale))

        updateButtonsWithLassoPath() // 初始化位置

        if let deleteBtn = deleteBtn { addSubview(deleteBtn) }
        if let copyBtn = copyBtn { addSubview(copyBtn) }
        if let scaleBtn = scaleBtn { addSubview(scaleBtn) }
    }

    private func updateButtonsWithLassoPath() {
        let rect = lassoPath.bounds
        deleteBtn?.center = CGPoint(x: rect.minX, y: rect.minY)
        copyBtn?.center = CGPoint(x: rect.maxX, y: rect.minY)
        scaleBtn?.center = CGPoint(x: rect.maxX, y: rect.maxY)
    }

    private func removeButtons() {
        deleteBtn?.removeFromSuperview()
        copyBtn?.removeFromSuperview()
        scaleBtn?.removeFromSuperview()
        
        deleteBtn = nil
        copyBtn = nil
        scaleBtn = nil
    }

    @objc private func didTapDelete() {
        print("Delete button tapped")
        onDelete?()
    }

    @objc private func didTapCopy() {
        print("Copy button tapped")
    }

    @objc private func didTapScale() {
        print("Scale button tapped")
    }
}
