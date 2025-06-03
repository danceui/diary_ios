enum AnimationState {
    /// 没有动画，完全空闲
    case idle
    
    /// 用户手势正在拖拽翻页（.changed）
    case manualDragging
    
    /// 用户释放后，播放「手势触发的完成/取消动画」
    case manualRemaining
    
    /// 由 autoFlip(...) 触发的自动翻页动画（内置插值/定时器驱动）
    case autoAnimating
}