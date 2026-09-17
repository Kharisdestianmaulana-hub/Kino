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
    
    public init(duration: Double, hasVideo: Bool, hasAudio: Bool) {
        self.duration = duration
        self.hasVideo = hasVideo
        self.hasAudio = hasAudio
    }
}
