import Foundation

public struct Project: Codable, Identifiable {
    public let id: UUID
    public var metadata: ProjectMetadata
    public var mediaReferences: [MediaAsset]
    public var sequences: [Sequence]
    public var settings: ProjectSettings
    public var moduleData: [String: Data] // Allows unavailable modules to retain data

    public init(id: UUID = UUID(), metadata: ProjectMetadata, settings: ProjectSettings) {
        self.id = id
        self.metadata = metadata
        self.mediaReferences = []
        self.sequences = []
        self.settings = settings
        self.moduleData = [:]
    }
}

public struct ProjectMetadata: Codable {
    public var name: String
    public var creationDate: Date
    public var modificationDate: Date

    public init(name: String, creationDate: Date = Date(), modificationDate: Date = Date()) {
        self.name = name
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
}

public struct ProjectSettings: Codable {
    public var frameRate: Double
    public var resolutionWidth: Int
    public var resolutionHeight: Int

    public init(frameRate: Double = 60.0, resolutionWidth: Int = 3840, resolutionHeight: Int = 2160) {
        self.frameRate = frameRate
        self.resolutionWidth = resolutionWidth
        self.resolutionHeight = resolutionHeight
    }
}
