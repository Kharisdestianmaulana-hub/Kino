import Foundation
import AVFoundation
import CoreGraphics
import CoreImage

#if canImport(AppKit)
import AppKit
#endif

public class PlaybackEngine {
    
    public init() {}
    
    @MainActor
    public func buildPlayerItem(for sequence: Sequence, using mediaReferences: [MediaAsset], isExport: Bool = false) async -> AVPlayerItem? {
        let composition = AVMutableComposition()
        composition.naturalSize = CGSize(width: 1920, height: 1080)
        let renderSize = CGSize(width: 1920, height: 1080)
        
        let videoTracks = sequence.tracks.filter { $0.type == .video }
        var maxTimelineDuration: CMTime = .zero
        
        for (trackIndex, videoTrack) in videoTracks.enumerated() {
            let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            for (i, clip) in videoTrack.clips.enumerated() {
                if clip.textProperties != nil {
                    let targetTime = CMTime(seconds: clip.timelineStart, preferredTimescale: 600)
                    let duration = CMTime(seconds: clip.duration, preferredTimescale: 600)
                    compVideoTrack?.insertEmptyTimeRange(CMTimeRange(start: targetTime, duration: duration))
                    let endTime = CMTimeAdd(targetTime, duration)
                    if endTime > maxTimelineDuration { maxTimelineDuration = endTime }
                    continue
                }
                
                guard let assetRef = mediaReferences.first(where: { $0.id == clip.mediaAssetID }) else { continue }
                guard let bookmark = assetRef.bookmarkData else { continue }
                
                var isStale = false
                guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { continue }
                
                _ = url.startAccessingSecurityScopedResource()
                let avAsset = AVURLAsset(url: url)
                
                do {
                    let sourceTime = CMTime(seconds: clip.sourceStart, preferredTimescale: 600)
                    let targetTime = CMTime(seconds: clip.timelineStart, preferredTimescale: 600)
                    
                    if let sourceTrack = avAsset.tracks(withMediaType: .video).first {
                        let maxAvailableDuration = sourceTrack.timeRange.duration.seconds - sourceTime.seconds
                        let safeDuration = min(clip.duration, maxAvailableDuration)
                        
                        if safeDuration > 0 {
                            let duration = CMTime(seconds: safeDuration, preferredTimescale: 600)
                            let timeRange = CMTimeRange(start: sourceTime, duration: duration)
                            try compVideoTrack?.insertTimeRange(timeRange, of: sourceTrack, at: targetTime)
                            
                            let endTime = CMTimeAdd(targetTime, duration)
                            if endTime > maxTimelineDuration {
                                maxTimelineDuration = endTime
                            }
                        }
                    } else if assetRef.metadata.isImage {
                        let duration = CMTime(seconds: clip.duration, preferredTimescale: 600)
                        compVideoTrack?.insertEmptyTimeRange(CMTimeRange(start: targetTime, duration: duration))
                        
                        let endTime = CMTimeAdd(targetTime, duration)
                        if endTime > maxTimelineDuration {
                            maxTimelineDuration = endTime
                        }
                    }
                } catch {
                    print("[PlaybackEngine] Error inserting track \(trackIndex) clip \(i): \(error)")
                }
            }
        }
        
                if !isExport {
            let padDuration = CMTime(seconds: 36000, preferredTimescale: 600)
            let padRange = CMTimeRange(start: maxTimelineDuration, duration: padDuration)
            for track in composition.tracks(withMediaType: .video) {
                track.insertEmptyTimeRange(padRange)
            }
            maxTimelineDuration = CMTimeAdd(maxTimelineDuration, padDuration)
        }
        
        let videoComposition = PlaybackEngine.buildVideoComposition(for: sequence, in: composition, using: mediaReferences, renderSize: renderSize, duration: maxTimelineDuration)
        
        let audioTracks = sequence.tracks.filter { $0.type == .audio }
        for audioTrack in audioTracks {
            if let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                for clip in audioTrack.clips {
                    guard let assetRef = mediaReferences.first(where: { $0.id == clip.mediaAssetID }),
                          let bookmark = assetRef.bookmarkData else { continue }
                    
                    var isStale = false
                    guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { continue }
                    _ = url.startAccessingSecurityScopedResource()
                    
                    let avAsset = AVURLAsset(url: url)
                    do {
                        if let sourceTrack = avAsset.tracks(withMediaType: .audio).first {
                            let sourceTime = CMTime(seconds: clip.sourceStart, preferredTimescale: 600)
                            let targetTime = CMTime(seconds: clip.timelineStart, preferredTimescale: 600)
                            
                            let maxAvailableDuration = sourceTrack.timeRange.duration.seconds - sourceTime.seconds
                            let safeDuration = min(clip.duration, maxAvailableDuration)
                            
                            if safeDuration > 0 {
                                let safeTimeRange = CMTimeRange(start: sourceTime, duration: CMTime(seconds: safeDuration, preferredTimescale: 600))
                                try compAudioTrack.insertTimeRange(safeTimeRange, of: sourceTrack, at: targetTime)
                            }
                        }
                    } catch {
                        print("Error inserting audio clip: \(error)")
                    }
                }
            }
        }
        
        let playerItem = AVPlayerItem(asset: composition)
        if videoComposition != nil {
            playerItem.videoComposition = videoComposition
        }
        
        return playerItem
    }
    

    private static func buildInstructions(for sequence: Sequence, composition: AVMutableComposition, compVideoTracks: [AVMutableCompositionTrack], mediaReferences: [MediaAsset], imageCache: [UUID: CIImage], renderSize: CGSize) -> [KinoVideoCompositionInstruction] {
        let duration = composition.duration.seconds
        let videoTracks = sequence.tracks.filter { $0.type == .video }
        
        var timePoints = Set<Double>()
        timePoints.insert(0.0)
        timePoints.insert(duration)
        
        for track in videoTracks {
            for clip in track.clips {
                timePoints.insert(clip.timelineStart)
                timePoints.insert(clip.timelineStart + clip.duration)
            }
        }
        
        let sortedPoints = Array(timePoints).sorted()
        var instructions: [KinoVideoCompositionInstruction] = []
        let compTrackIDs = compVideoTracks.map { $0.trackID }
        
        for i in 0..<sortedPoints.count - 1 {
            let start = sortedPoints[i]
            let end = sortedPoints[i+1]
            let segDuration = end - start
            if segDuration > 0.001 { // ignore extremely tiny rounding artifacts
                let timeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600), duration: CMTime(seconds: segDuration, preferredTimescale: 600))
                
                var requiredTrackIDs: [NSValue] = []
                for (trackIndex, track) in videoTracks.enumerated() {
                    let compTrackID = compTrackIDs[trackIndex]
                    
                    let hasVideoMedia = track.clips.contains { clip in
                        let clipEnd = clip.timelineStart + clip.duration
                        let overlaps = (clip.timelineStart < end - 0.001 && clipEnd > start + 0.001)
                        return overlaps && clip.textProperties == nil
                    }
                    
                    if hasVideoMedia {
                        requiredTrackIDs.append(NSNumber(value: compTrackID) as NSValue)
                    }
                }
                
                let instruction = KinoVideoCompositionInstruction(
                    timeRange: timeRange,
                    videoTracks: videoTracks,
                    compTrackIDs: compTrackIDs,
                    mediaReferences: mediaReferences,
                    imageCache: imageCache,
                    renderSize: renderSize,
                    requiredTrackIDs: requiredTrackIDs
                )
                instructions.append(instruction)
            }
        }
        return instructions
    }

    public static func buildVideoComposition(for sequence: Sequence, in composition: AVMutableComposition, using mediaReferences: [MediaAsset], renderSize: CGSize, duration: CMTime) -> AVMutableVideoComposition? {
        let videoTracks = sequence.tracks.filter { $0.type == .video }
        let compVideoTracks = composition.tracks(withMediaType: .video)
        guard compVideoTracks.count == videoTracks.count else { return nil }
        
        // Preload images to avoid concurrent mutation crashes in AVFoundation's render threads
        var imageCache: [UUID: CIImage] = [:]
        for videoTrack in videoTracks {
            for clip in videoTrack.clips {
                guard let assetRef = mediaReferences.first(where: { $0.id == clip.mediaAssetID }) else { continue }
                if assetRef.metadata.isImage, imageCache[assetRef.id] == nil, let bookmark = assetRef.bookmarkData {
                    var isStale = false
                    if let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                        let isScoped = url.startAccessingSecurityScopedResource()
                        if let data = try? Data(contentsOf: url), let img = CIImage(data: data) {
                            imageCache[assetRef.id] = img
                        }
                        if isScoped {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                }
            }
        }
        
        let instructions = buildInstructions(for: sequence, composition: composition, compVideoTracks: compVideoTracks, mediaReferences: mediaReferences, imageCache: imageCache, renderSize: renderSize)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = KinoVideoCompositor.self
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
        videoComposition.instructions = instructions
        
        return videoComposition
    }
    
    @MainActor
    public func updateCompositions(for playerItem: AVPlayerItem, sequence: Sequence, using mediaReferences: [MediaAsset]) {
        guard let composition = playerItem.asset as? AVMutableComposition else { return }
        let renderSize = CGSize(width: 1920, height: 1080)
        let duration = composition.duration
        
        let videoTracks = sequence.tracks.filter { $0.type == .video }
        let compVideoTracks = composition.tracks(withMediaType: .video)
        
        if compVideoTracks.count == videoTracks.count {
            var imageCache: [UUID: CIImage] = [:]
            for videoTrack in videoTracks {
                for clip in videoTrack.clips {
                    guard let assetRef = mediaReferences.first(where: { $0.id == clip.mediaAssetID }) else { continue }
                    if assetRef.metadata.isImage, imageCache[assetRef.id] == nil, let bookmark = assetRef.bookmarkData {
                        var isStale = false
                        if let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                            let isScoped = url.startAccessingSecurityScopedResource()
                            if let data = try? Data(contentsOf: url), let img = CIImage(data: data) {
                                imageCache[assetRef.id] = img
                            }
                            if isScoped {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                    }
                }
            }
            
            let instructions = Self.buildInstructions(for: sequence, composition: composition, compVideoTracks: compVideoTracks, mediaReferences: mediaReferences, imageCache: imageCache, renderSize: renderSize)
            
            if let current = playerItem.videoComposition as? AVMutableVideoComposition {
                current.instructions = instructions
                // Toggle to force re-render of paused frame
                playerItem.videoComposition = nil
                playerItem.videoComposition = current
            } else {
                let videoComposition = AVMutableVideoComposition()
                videoComposition.customVideoCompositorClass = KinoVideoCompositor.self
                videoComposition.renderSize = renderSize
                videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
                videoComposition.instructions = instructions
                playerItem.videoComposition = videoComposition
            }
        }
        
        // Update Audio
        if let compAudioTrack = composition.tracks(withMediaType: .audio).first,
           let audioTrack = sequence.tracks.first(where: { $0.type == .audio }) {
            let audioMix = AVMutableAudioMix()
            let ap = AVMutableAudioMixInputParameters(track: compAudioTrack)
            for clip in audioTrack.clips {
                let targetTime = CMTime(seconds: clip.timelineStart, preferredTimescale: 600)
                ap.setVolume(clip.volume, at: targetTime)
            }
            audioMix.inputParameters = [ap]
            playerItem.audioMix = audioMix
        }
    }
}
import Foundation
import AVFoundation
import CoreGraphics
import CoreImage
import CoreVideo

public class KinoVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    public var timeRange: CMTimeRange
    public var enablePostProcessing: Bool = false
    public var containsTweening: Bool = true
    public var requiredSourceTrackIDs: [NSValue]? = nil
    public var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    // Custom data
    public var videoTracks: [Track]
    public var compTrackIDs: [CMPersistentTrackID]
    public var mediaReferences: [MediaAsset]
    public var imageCache: [UUID: CIImage]
    public var renderSize: CGSize
    
    public init(timeRange: CMTimeRange, videoTracks: [Track], compTrackIDs: [CMPersistentTrackID], mediaReferences: [MediaAsset], imageCache: [UUID: CIImage], renderSize: CGSize, requiredTrackIDs: [NSValue]? = nil) {
        self.timeRange = timeRange
        self.videoTracks = videoTracks
        self.compTrackIDs = compTrackIDs
        self.mediaReferences = mediaReferences
        self.imageCache = imageCache
        self.renderSize = renderSize
        
        self.requiredSourceTrackIDs = requiredTrackIDs
    }
}

public class KinoVideoCompositor: NSObject, AVVideoCompositing {
    public var sourcePixelBufferAttributes: [String : Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
    ]
    
    public var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
    ]
    
    private let renderContextQueue = DispatchQueue(label: "com.kino.renderContext")
    private let renderingQueue = DispatchQueue(label: "com.kino.rendering")
    private var renderContext: AVVideoCompositionRenderContext?
    private let ciContext = CIContext(options: nil)
    
    public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync {
            self.renderContext = newRenderContext
        }
    }
    
    private func renderText(_ props: TextProperties, renderSize: CGSize) -> CIImage? {
        let text = props.text.isEmpty ? " " : props.text
        
        let nsColor = NSColor(hex: props.colorHex) ?? NSColor.white
        let nsFont = NSFont(name: props.fontName, size: CGFloat(props.fontSize)) ?? NSFont.systemFont(ofSize: CGFloat(props.fontSize))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = props.alignment == 0 ? .left : (props.alignment == 1 ? .center : .right)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: nsFont,
            .foregroundColor: nsColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        
        let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), nil)
        
        let width = max(1, size.width)
        let height = max(1, size.height)
        
        guard let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: height), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Draw the text
        CTFrameDraw(frame, context)
        
        if let cgImage = context.makeImage() {
            return CIImage(cgImage: cgImage)
        }
        return nil
    }
    
    public func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async {
            guard let instruction = request.videoCompositionInstruction as? KinoVideoCompositionInstruction else {
                request.finish(with: NSError(domain: "com.kino", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid instruction type"]))
                return
            }
            
            guard let pixelBuffer = self.renderContext?.newPixelBuffer() else {
                request.finish(with: NSError(domain: "com.kino", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"]))
                return
            }
            
            let renderSize = instruction.renderSize
            var finalImage = CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: renderSize))
                        let currentTime = request.compositionTime.seconds
            print("[KinoVideoCompositor] Render requested for time: \(currentTime)")
            
            // Render tracks from bottom to top
            for (trackIndex, videoTrack) in instruction.videoTracks.enumerated().reversed() {
                let trackID = instruction.compTrackIDs[trackIndex]
                
                if let clip = videoTrack.clips.first(where: { currentTime >= $0.timelineStart && currentTime < $0.timelineStart + $0.duration }) {
                    
                    var sourceImage: CIImage? = nil
                    
                    if let textProps = clip.textProperties {
                        sourceImage = self.renderText(textProps, renderSize: renderSize)
                    } else if let assetRef = instruction.mediaReferences.first(where: { $0.id == clip.mediaAssetID }) {
                        if assetRef.metadata.isImage {
                            sourceImage = instruction.imageCache[assetRef.id]
                        } else {
                            if let pixelBuf = request.sourceFrame(byTrackID: trackID) {
                                sourceImage = CIImage(cvPixelBuffer: pixelBuf)
                            }
                        }
                    }
                    
                    if var img = sourceImage {
                        // Center image to renderSize
                        let imgExtent = img.extent
                        
                        var baseScale: CGFloat = 1.0
                        if clip.textProperties == nil {
                            let scaleX = renderSize.width / imgExtent.width
                            let scaleY = renderSize.height / imgExtent.height
                            baseScale = min(abs(scaleX), abs(scaleY))
                        }
                        
                        let scaledWidth = imgExtent.width * baseScale
                        let scaledHeight = imgExtent.height * baseScale
                        let offsetX = (renderSize.width - scaledWidth) / 2.0
                        let offsetY = (renderSize.height - scaledHeight) / 2.0
                        
                        var transform = CGAffineTransform(translationX: -imgExtent.minX, y: -imgExtent.minY)
                        transform = transform.concatenating(CGAffineTransform(scaleX: baseScale, y: baseScale))
                        transform = transform.concatenating(CGAffineTransform(translationX: offsetX, y: offsetY))
                        
                        // Apply user transforms
                        let userScale = CGFloat(clip.transform.scale)
                        let userPosX = CGFloat(clip.transform.positionX)
                        let userPosY = -CGFloat(clip.transform.positionY)
                        let userRot = CGFloat(clip.transform.rotation) * .pi / 180.0
                        
                        let cx = renderSize.width / 2.0
                        let cy = renderSize.height / 2.0
                        
                        transform = transform.concatenating(CGAffineTransform(translationX: -cx, y: -cy))
                        transform = transform.concatenating(CGAffineTransform(scaleX: userScale, y: userScale))
                        transform = transform.concatenating(CGAffineTransform(rotationAngle: userRot))
                        transform = transform.concatenating(CGAffineTransform(translationX: cx, y: cy))
                        transform = transform.concatenating(CGAffineTransform(translationX: userPosX, y: userPosY))
                        
                        img = img.transformed(by: transform)
                        
                        let opacity = CGFloat(clip.transform.opacity)
                        if opacity < 1.0 {
                            let filter = CIFilter(name: "CIColorMatrix")!
                            filter.setValue(img, forKey: kCIInputImageKey)
                            filter.setValue(CIVector(x: opacity, y: 0, z: 0, w: 0), forKey: "inputRVector")
                            filter.setValue(CIVector(x: 0, y: opacity, z: 0, w: 0), forKey: "inputGVector")
                            filter.setValue(CIVector(x: 0, y: 0, z: opacity, w: 0), forKey: "inputBVector")
                            filter.setValue(CIVector(x: 0, y: 0, z: 0, w: opacity), forKey: "inputAVector")
                            if let outImg = filter.outputImage {
                                img = outImg
                            }
                        }
                        
                        finalImage = img.composited(over: finalImage)
                    }
                }
            }
            
            self.ciContext.render(finalImage, to: pixelBuffer)
            request.finish(withComposedVideoFrame: pixelBuffer)
        }
    }
}

extension NSColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        var hexColor = hex
        if hexColor.hasPrefix("#") {
            let start = hexColor.index(hexColor.startIndex, offsetBy: 1)
            hexColor = String(hexColor[start...])
        }
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                a = 1.0
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        }
        return nil
    }
}
