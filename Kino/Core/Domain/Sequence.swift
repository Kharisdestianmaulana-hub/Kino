import Foundation

public struct Sequence: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var tracks: [Track]
    public var markers: [Marker]

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.tracks = []
        self.markers = []
    }
}
