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

public struct TextProperties: Codable, Equatable {
    public var text: String
    public var fontName: String
    public var fontSize: Double
    public var colorHex: String
    public var alignment: Int // 0: left, 1: center, 2: right
    
    public init(text: String = "Basic Text", fontName: String = "Helvetica", fontSize: Double = 150, colorHex: String = "#FFFFFF", alignment: Int = 1) {
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.colorHex = colorHex
        self.alignment = alignment
    }
}

public struct ColorAdjustment: Codable, Equatable {
    public var brightness: Double
    public var contrast: Double
    public var saturation: Double
    
    public init(brightness: Double = 0.0, contrast: Double = 1.0, saturation: Double = 1.0) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
    }
}

public struct Clip: Codable, Identifiable, Equatable {
    public let id: UUID
    public var mediaAssetID: UUID?
    public var textProperties: TextProperties?
    
    /// The start time of the clip on the track's timeline (in seconds).
    public var timelineStart: Double
    
    /// The start time within the original media asset (in seconds).
    public var sourceStart: Double
    
    /// The duration of the clip (in seconds).
    public var duration: Double
    
    /// Properties for visual manipulation
    public var transform: ClipTransform
    
    /// Color adjustment parameters
    public var colorAdjustment: ColorAdjustment?
    
    /// Properties for audio manipulation (1.0 = 100%, 0.0 = mute)
    public var volume: Float
    
    /// Dictionary of keyframes, mapped by property name (e.g. "scale", "opacity")
    public var keyframes: [String: [Keyframe]]
    
    /// ID of a linked clip (e.g. linked audio track)
    public var linkedClipID: UUID?

    public init(id: UUID = UUID(), mediaAssetID: UUID? = nil, textProperties: TextProperties? = nil, timelineStart: Double, sourceStart: Double, duration: Double, transform: ClipTransform = ClipTransform(), colorAdjustment: ColorAdjustment? = nil, volume: Float = 1.0, keyframes: [String: [Keyframe]] = [:], linkedClipID: UUID? = nil) {
        self.id = id
        self.mediaAssetID = mediaAssetID
        self.textProperties = textProperties
        self.timelineStart = timelineStart
        self.sourceStart = sourceStart
        self.duration = duration
        self.transform = transform
        self.colorAdjustment = colorAdjustment
        self.volume = volume
        self.keyframes = keyframes
        self.linkedClipID = linkedClipID
    }
    
    // Custom Decoder untuk Backward Compatibility (mencegah crash saat buka file save lama)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.mediaAssetID = try container.decodeIfPresent(UUID.self, forKey: .mediaAssetID)
        self.textProperties = try container.decodeIfPresent(TextProperties.self, forKey: .textProperties)
        self.timelineStart = try container.decode(Double.self, forKey: .timelineStart)
        self.sourceStart = try container.decode(Double.self, forKey: .sourceStart)
        self.duration = try container.decode(Double.self, forKey: .duration)
        
        self.transform = try container.decodeIfPresent(ClipTransform.self, forKey: .transform) ?? ClipTransform()
        self.colorAdjustment = try container.decodeIfPresent(ColorAdjustment.self, forKey: .colorAdjustment)
        self.volume = try container.decodeIfPresent(Float.self, forKey: .volume) ?? 1.0
        self.keyframes = try container.decodeIfPresent([String: [Keyframe]].self, forKey: .keyframes) ?? [:]
        self.linkedClipID = try container.decodeIfPresent(UUID.self, forKey: .linkedClipID)
    }
    
    /// Helper to get an interpolated value at a specific local time.
    /// localTime is the time offset from the start of the clip (0.0 means the very beginning of the clip block).
    public func interpolatedValue(for property: String, at localTime: Double, fallback: Double) -> Double {
        guard let trackKeyframes = keyframes[property], !trackKeyframes.isEmpty else {
            return fallback
        }
        
        let sorted = trackKeyframes.sorted(by: { $0.time < $1.time })
        
        if localTime <= sorted.first!.time {
            return sorted.first!.value
        }
        
        if localTime >= sorted.last!.time {
            return sorted.last!.value
        }
        
        for i in 0..<(sorted.count - 1) {
            let kf1 = sorted[i]
            let kf2 = sorted[i+1]
            
            if localTime >= kf1.time && localTime < kf2.time {
                var progress = (localTime - kf1.time) / (kf2.time - kf1.time)
                
                // Apply easing
                switch kf1.easing {
                case .linear:
                    break // progress remains the same
                case .easeIn:
                    progress = progress * progress
                case .easeOut:
                    progress = progress * (2.0 - progress)
                case .easeInOut:
                    if progress < 0.5 {
                        progress = 2.0 * progress * progress
                    } else {
                        progress = -1.0 + (4.0 - 2.0 * progress) * progress
                    }
                }
                
                return kf1.value + (kf2.value - kf1.value) * progress
            }
        }
        
        return fallback
    }
}
import Foundation

public enum KeyframeEasing: String, Codable, Equatable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
}

public struct Keyframe: Codable, Identifiable, Equatable {
    public let id: UUID
    /// Waktu relatif terhadap awal klip (0.0 = awal klip, berapapun timelineStart-nya)
    public var time: Double
    public var value: Double
    public var easing: KeyframeEasing
    
    public init(id: UUID = UUID(), time: Double, value: Double, easing: KeyframeEasing = .linear) {
        self.id = id
        self.time = time
        self.value = value
        self.easing = easing
    }
}
