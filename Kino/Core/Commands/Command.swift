import Foundation

public protocol Command {
    var name: String { get }
    func execute() throws
    func undo()
    func redo() throws
}

public extension Command {
    var requiresPlaybackRebuild: Bool { true }
}

public class CompositeCommand: Command {
    public let name: String
    private let commands: [Command]
    
    public init(name: String, commands: [Command]) {
        self.name = name
        self.commands = commands
    }
    
    public func execute() throws {
        for command in commands {
            try command.execute()
        }
    }
    
    public func undo() {
        for command in commands.reversed() {
            command.undo()
        }
    }
    
    public func redo() throws {
        for command in commands {
            try command.redo()
        }
    }
}
