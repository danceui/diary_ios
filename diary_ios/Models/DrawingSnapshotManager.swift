import PencilKit

@available(iOS 16.0, *)
class DrawingSnapshotManager {
    private var snapshots: [PKDrawing]
    private var currentIndex: Int
    private let maxSnapshots: Int

    init(initialDrawing: PKDrawing, maxSnapshots: Int = 50) {
        self.snapshots = [initialDrawing]
        self.currentIndex = 0
        self.maxSnapshots = maxSnapshots
    }

    /// 当前快照
    var currentDrawing: PKDrawing {
        return snapshots[currentIndex]
    }

    /// 是否可以撤销
    var canUndo: Bool {
        return currentIndex > 0
    }

    /// 是否可以重做
    var canRedo: Bool {
        return currentIndex < snapshots.count - 1
    }

    /// 添加新快照（如果内容变化）
    func addSnapshot(_ newDrawing: PKDrawing) {
        let newData = newDrawing.dataRepresentation()
        let currentData = snapshots[currentIndex].dataRepresentation()

        // 内容没变化就跳过
        guard newData != currentData else {
            print("DrawingSnapshotManager: Skip duplicate snapshot.")
            return
        }

        // 如果之前撤销过，再添加新快照时清除 redo 分支
        if currentIndex < snapshots.count - 1 {
            snapshots = Array(snapshots.prefix(currentIndex + 1))
        }

        snapshots.append(newDrawing)
        currentIndex += 1

        // 控制快照数量
        if snapshots.count > maxSnapshots {
            snapshots.removeFirst()
            currentIndex -= 1
        }

        print("DrawingSnapshotManager: Added snapshot #\(currentIndex)")
    }

    /// 撤销：返回上一状态
    func undo() -> PKDrawing? {
        guard canUndo else { return nil }
        currentIndex -= 1
        print("DrawingSnapshotManager: Undo to #\(currentIndex)")
        return snapshots[currentIndex]
    }

    /// 重做：返回下一状态
    func redo() -> PKDrawing? {
        guard canRedo else { return nil }
        currentIndex += 1
        print("DrawingSnapshotManager: Redo to #\(currentIndex)")
        return snapshots[currentIndex]
    }

    /// 重置快照历史（例如加载新页面）
    func reset(with newInitialDrawing: PKDrawing) {
        snapshots = [newInitialDrawing]
        currentIndex = 0
        print("DrawingSnapshotManager: Reset snapshots.")
    }
}