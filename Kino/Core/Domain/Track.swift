import Foundation

public enum TrackType: String, Codable {
    case video
    case audio
}

public struct Track: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public let type: TrackType
    public var clips: [Clip]
    
    public init(id: UUID = UUID(), name: String, type: TrackType) {
        self.id = id
        self.name = name
        self.type = type
        self.clips = []
    }
}
