import UIKit

class CanvasCommandManager {
    private let canvasLayer: CanvasLayer
    private(set) var undoStack: [CanvasCommand] = []
    private(set) var redoStack: [CanvasCommand] = []
    var onCommandExecuted: (() -> Void)?

    init(canvasLayer: CanvasLayer) {
        self.canvasLayer = canvasLayer
    }

    func executeAndSave(command: CanvasCommand) {
        command.execute()
        undoStack.append(command)
        redoStack.removeAll()
        onCommandExecuted?()
        print("🕹️ Executed command.")
        printStackInfo(undoStack: undoStack, redoStack: redoStack)
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        onCommandExecuted?()
        print("🕹️ Undo command.")
        printStackInfo(undoStack: undoStack, redoStack: redoStack) 
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        onCommandExecuted?()
        print("🕹️ Redo command.")
        printStackInfo(undoStack: undoStack, redoStack: redoStack) 
    }
}