import PencilKit

@available(iOS 16.0, *)
class UndoRedoManager {
    var canvasState: CanvasState
    private var undoStack: [CanvasCommand] = []
    private var redoStack: [CanvasCommand] = []

    init(initialState: CanvasState = CanvasState()) {
        self.canvasState = initialState
    }

    func executeCommand(_ command: CanvasCommand) {
        command.execute(on: canvasState)
        undoStack.append(command)
        redoStack.removeAll()
        print("🕹️ Added new command.")
    }

    func undoCommand() {
        guard let command = undoStack.popLast() else { return }
        command.undo(on: canvasState)
        redoStack.append(command)
        print("🕹️ Undo command.")
    }

    func redoCommand() {
        guard let command = redoStack.popLast() else { return }
        command.execute(on: canvasState)
        print("🕹️ Redo command.")
        undoStack.append(command)
    }

    func reset(to state: CanvasState) {
        canvasState = state
        undoStack.removeAll()
        redoStack.removeAll()
        print("🕹️ Cleared command history.")
    }
}
