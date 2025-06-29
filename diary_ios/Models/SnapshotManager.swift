import PencilKit

@available(iOS 16.0, *)
class SnapshotManager {
    private var snapshots: [PageSnapshot]
    private var currentIndex: Int
    private let maxSnapshots: Int

    init(initialSnapshot: PageSnapshot, maxSnapshots: Int = 50) {
        self.snapshots = [initialSnapshot]
        self.currentIndex = 0
        self.maxSnapshots = maxSnapshots
    }

    var currentSnapshot: PageSnapshot { return snapshots[currentIndex] }
    var currentDrawing: PKDrawing { return currentSnapshot.drawing }
    var canUndo: Bool { return currentIndex > 0 }
    var canRedo: Bool { return currentIndex < snapshots.count - 1 }

    func addSnapshot(_ newSnapshot: PageSnapshot) {
        guard newSnapshot != snapshots[currentIndex] else {
            print("❌ Skip duplicate snapshot.")
            return
        }

        if currentIndex < snapshots.count - 1 {
            snapshots = Array(snapshots.prefix(currentIndex + 1))
        }

        snapshots.append(newSnapshot)
        currentIndex += 1

        if snapshots.count > maxSnapshots {
            snapshots.removeFirst()
            currentIndex -= 1
        }
        print("📸 Added snapshot #\(currentIndex).")
        // printAllSnapshotsInfo(snapshots: snapshots, currentIndex: currentIndex)
    }

    func undo() -> PageSnapshot? {
        guard canUndo else { return nil }
    let startTime = CFAbsoluteTimeGetCurrent()
        currentIndex -= 1
    let duration = CFAbsoluteTimeGetCurrent() - startTime
        print("🎞️ Undo to snapshot #\(currentIndex). Took \(duration) seconds.")
        return snapshots[currentIndex]
    }

    func redo() -> PageSnapshot? {
        guard canRedo else { return nil }
    let startTime = CFAbsoluteTimeGetCurrent()
        currentIndex += 1
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    print("🎞️ Redo to snapshot #\(currentIndex). Took \(duration) seconds")
        return snapshots[currentIndex]
    }

    func reset(with newInitialDrawing: PageSnapshot) {
        snapshots = [newInitialDrawing]
        currentIndex = 0
        print("🎞️ Reset snapshots.")
    }
}
