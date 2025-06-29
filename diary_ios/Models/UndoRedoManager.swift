import PencilKit

@available(iOS 16.0, *)
class UndoRedoManager {
    private(set) var canvasState: CanvasState
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    init(initialState: CanvasState) {
        self.canvasState = initialState
    }

    func perform(_ command: CanvasCommand) {
        command.execute(on: canvasState)
        undoStack.append(command)
        print("📸 Updated undo stack & Cleared redo stack.")
        redoStack.removeAll()
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo(on: canvasState)
        redoStack.append(command)
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute(on: canvasState)
        print("🎞️ Redo.")
        undoStack.append(command)
    }

    func reset(to state: CanvasState) {
        canvasState = state
        undoStack.removeAll()
        redoStack.removeAll()
        print("🎞️ Cleared undo/redo stacks.")
    }
}
