import PencilKit

@available(iOS 16.0, *)
class DrawingSnapshotManager {
    private var snapshots: [PageSnapshot]
    private var currentIndex: Int
    private let maxSnapshots: Int

    init(initialDrawing: PageSnapshot, maxSnapshots: Int = 50) {
        self.snapshots = [initialDrawing]
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
        print("📸 Added snapshot #\(currentIndex)")
    }

    func undo() -> PageSnapshot? {
        guard canUndo else { return nil }
        currentIndex -= 1
        print("🎞️ Undo to #\(currentIndex)")
        return snapshots[currentIndex]
    }

    func redo() -> PageSnapshot? {
        guard canRedo else { return nil }
        currentIndex += 1
        print("🎞️ Redo to #\(currentIndex)")
        return snapshots[currentIndex]
    }

    func reset(with newInitialDrawing: PageSnapshot) {
        snapshots = [newInitialDrawing]
        currentIndex = 0
        print("🎞️ Reset snapshots.")
    }
}