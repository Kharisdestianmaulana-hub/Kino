import Foundation

public struct MediaAsset: Codable, Identifiable {
    public let id: UUID
    public var originalURL: URL
    public var bookmarkData: Data? // For security-scoped bookmarks
    public var metadata: MediaMetadata
    public var isMissing: Bool
    
    public init(id: UUID = UUID(), originalURL: URL, bookmarkData: Data? = nil, metadata: MediaMetadata, isMissing: Bool = false) {
        self.id = id
        self.originalURL = originalURL
        self.bookmarkData = bookmarkData
        self.metadata = metadata
        self.isMissing = isMissing
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.originalURL = try container.decode(URL.self, forKey: .originalURL)
        self.bookmarkData = try container.decodeIfPresent(Data.self, forKey: .bookmarkData)
        self.metadata = try container.decode(MediaMetadata.self, forKey: .metadata)
        self.isMissing = try container.decodeIfPresent(Bool.self, forKey: .isMissing) ?? false
    }
}

public struct MediaMetadata: Codable {
    public var duration: Double
    public var hasVideo: Bool
    public var hasAudio: Bool
    public var isImage: Bool
    
    // Extended properties
    public var resolutionWidth: Int?
    public var resolutionHeight: Int?
    public var frameRate: Double?
    public var fileSizeBytes: Int64?
    
    public init(duration: Double, hasVideo: Bool, hasAudio: Bool, isImage: Bool = false,
                resolutionWidth: Int? = nil, resolutionHeight: Int? = nil, frameRate: Double? = nil, fileSizeBytes: Int64? = nil) {
        self.duration = duration
        self.hasVideo = hasVideo
        self.hasAudio = hasAudio
        self.isImage = isImage
        self.resolutionWidth = resolutionWidth
        self.resolutionHeight = resolutionHeight
        self.frameRate = frameRate
        self.fileSizeBytes = fileSizeBytes
    }
    
    // Custom Decoder untuk backward compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.duration = try container.decode(Double.self, forKey: .duration)
        self.hasVideo = try container.decode(Bool.self, forKey: .hasVideo)
        self.hasAudio = try container.decode(Bool.self, forKey: .hasAudio)
        self.isImage = try container.decodeIfPresent(Bool.self, forKey: .isImage) ?? false
        self.resolutionWidth = try container.decodeIfPresent(Int.self, forKey: .resolutionWidth)
        self.resolutionHeight = try container.decodeIfPresent(Int.self, forKey: .resolutionHeight)
        self.frameRate = try container.decodeIfPresent(Double.self, forKey: .frameRate)
        self.fileSizeBytes = try container.decodeIfPresent(Int64.self, forKey: .fileSizeBytes)
    }
}
