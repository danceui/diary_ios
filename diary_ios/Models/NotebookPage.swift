struct PageSnapshot {
    var drawing: PKDrawing
    // var stickers: [StickerModel] // 你后续自定义的贴纸层模型
    // 可以继续添加其他图层，例如文本、图片等
    
    private(set) lazy var drawingHash: Int = {
        return drawing.dataRepresentation().hashValue
    }()
    
    static func == (lhs: PageSnapshot, rhs: PageSnapshot) -> Bool {
        return lhs.drawing == rhs.drawing
    }
    static func != (lhs: PageSnapshot, rhs: PageSnapshot) -> Bool {
        return lhs.drawing != rhs.drawing
    }
}