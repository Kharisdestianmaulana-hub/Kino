import Foundation

public struct ClipTransform: Codable, Equatable {
    public var positionX: Double
    public var positionY: Double
    public var scale: Double
    public var rotation: Double
    public var opacity: Double
    
    public init(positionX: Double = 0, positionY: Double = 0, scale: Double = 1.0, rotation: Double = 0, opacity: Double = 1.0) {
        self.positionX = positionX
        self.positionY = positionY
        self.scale = scale
        self.rotation = rotation
        self.opacity = opacity
    }
}

public struct Clip: Codable, Identifiable, Equatable {
    public let id: UUID
    public var mediaAssetID: UUID
    
    /// The start time of the clip on the track's timeline (in seconds).
    public var timelineStart: Double
    
    /// The start time within the original media asset (in seconds).
    public var sourceStart: Double
    
    /// The duration of the clip (in seconds).
    public var duration: Double
    
    /// Properties for visual manipulation
    public var transform: ClipTransform
    
    /// Properties for audio manipulation (1.0 = 100%, 0.0 = mute)
    public var volume: Float
    
    /// ID of a linked clip (e.g. linked audio track)
    public var linkedClipID: UUID?

    public init(id: UUID = UUID(), mediaAssetID: UUID, timelineStart: Double, sourceStart: Double, duration: Double, transform: ClipTransform = ClipTransform(), volume: Float = 1.0, linkedClipID: UUID? = nil) {
        self.id = id
        self.mediaAssetID = mediaAssetID
        self.timelineStart = timelineStart
        self.sourceStart = sourceStart
        self.duration = duration
        self.transform = transform
        self.volume = volume
        self.linkedClipID = linkedClipID
    }
    
    // Custom Decoder untuk Backward Compatibility (mencegah crash saat buka file save lama)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.mediaAssetID = try container.decode(UUID.self, forKey: .mediaAssetID)
        self.timelineStart = try container.decode(Double.self, forKey: .timelineStart)
        self.sourceStart = try container.decode(Double.self, forKey: .sourceStart)
        self.duration = try container.decode(Double.self, forKey: .duration)
        
        self.transform = try container.decodeIfPresent(ClipTransform.self, forKey: .transform) ?? ClipTransform()
        self.volume = try container.decodeIfPresent(Float.self, forKey: .volume) ?? 1.0
        self.linkedClipID = try container.decodeIfPresent(UUID.self, forKey: .linkedClipID)
    }
}
