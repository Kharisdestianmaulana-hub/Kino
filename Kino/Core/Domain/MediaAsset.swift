import Foundation

public struct MediaAsset: Codable, Identifiable {
    public let id: UUID
    public let originalURL: URL
    public var bookmarkData: Data? // For security-scoped bookmarks
    public var metadata: MediaMetadata
    
    public init(id: UUID = UUID(), originalURL: URL, bookmarkData: Data? = nil, metadata: MediaMetadata) {
        self.id = id
        self.originalURL = originalURL
        self.bookmarkData = bookmarkData
        self.metadata = metadata
    }
}

public struct MediaMetadata: Codable {
    public var duration: Double
    public var hasVideo: Bool
    public var hasAudio: Bool
    public var isImage: Bool // Tambahan baru
    
    public init(duration: Double, hasVideo: Bool, hasAudio: Bool, isImage: Bool = false) {
        self.duration = duration
        self.hasVideo = hasVideo
        self.hasAudio = hasAudio
        self.isImage = isImage
    }
    
    // Custom Decoder untuk backward compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.duration = try container.decode(Double.self, forKey: .duration)
        self.hasVideo = try container.decode(Bool.self, forKey: .hasVideo)
        self.hasAudio = try container.decode(Bool.self, forKey: .hasAudio)
        self.isImage = try container.decodeIfPresent(Bool.self, forKey: .isImage) ?? false
    }
}
