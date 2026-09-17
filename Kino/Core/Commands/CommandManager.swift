import Foundation

public class CommandManager {
    private let undoManager: UndoManager
    public private(set) var lastActionRequiresPlaybackRebuild: Bool = true
    
    public init(undoManager: UndoManager = UndoManager()) {
        self.undoManager = undoManager
    }
    
    public func execute(_ command: Command) throws {
        try command.execute()
        lastActionRequiresPlaybackRebuild = command.requiresPlaybackRebuild
        registerUndo(for: command)
    }
    
    private func registerUndo(for command: Command) {
        undoManager.registerUndo(withTarget: self) { target in
            command.undo()
            target.lastActionRequiresPlaybackRebuild = command.requiresPlaybackRebuild
            target.registerRedo(for: command)
        }
        undoManager.setActionName(command.name)
    }
    
    private func registerRedo(for command: Command) {
        undoManager.registerUndo(withTarget: self) { target in
            do {
                try command.redo()
                target.lastActionRequiresPlaybackRebuild = command.requiresPlaybackRebuild
                target.registerUndo(for: command)
            } catch {
                print("Failed to redo command: \(command.name)")
            }
        }
        undoManager.setActionName(command.name)
    }
    
    public func undo() {
        if undoManager.canUndo {
            undoManager.undo()
        }
    }
    
    public func redo() {
        if undoManager.canRedo {
            undoManager.redo()
        }
    }
    
    public func beginGrouping() {
        undoManager.beginUndoGrouping()
    }
    
    public func endGrouping() {
        undoManager.endUndoGrouping()
    }
}
