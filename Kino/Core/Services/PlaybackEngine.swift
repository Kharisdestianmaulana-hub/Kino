import Foundation
import AVFoundation
import CoreGraphics
import CoreImage

#if canImport(AppKit)
import AppKit
#endif

public class PlaybackEngine {
    
    public init() {}
    
    // MARK: - Blank Carrier Video
    // AVFoundation skips calling our custom compositor when all composition tracks
    // only have empty time ranges (insertEmptyTimeRange). To render text clips, we need
    // real video frames on the track so AVFoundation invokes startRequest().
    // This generates a tiny black .mov (2 frames, ~few KB) used as a "carrier".
    
    private static var _blankCarrierURL: URL?
    
    private static func getBlankCarrierAsset(renderSize: CGSize) async -> AVURLAsset? {
        if let url = _blankCarrierURL, FileManager.default.fileExists(atPath: url.path) {
            return AVURLAsset(url: url)
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = Self._generateBlankCarrier(renderSize: renderSize)
                continuation.resume(returning: asset)
            }
        }
    }
    
    private static func _generateBlankCarrier(renderSize: CGSize) -> AVURLAsset? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("kino_blank_carrier.mov")
        try? FileManager.default.removeItem(at: url)
        
        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else {
            print("[PlaybackEngine] Failed to create AVAssetWriter for blank carrier")
            return nil
        }
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(renderSize.width),
            AVVideoHeightKey: Int(renderSize.height)
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        
        let pbAttrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: Int(renderSize.width),
            kCVPixelBufferHeightKey as String: Int(renderSize.height)
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: pbAttrs)
        
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, Int(renderSize.width), Int(renderSize.height), kCVPixelFormatType_32BGRA, nil, &pb)
        guard let pixelBuffer = pb else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        memset(CVPixelBufferGetBaseAddress(pixelBuffer)!, 0, CVPixelBufferGetDataSize(pixelBuffer))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        // 2 frames spanning 3600 seconds — file is tiny (~few KB)
        adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: 0, timescale: 600))
        while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.001) }
        adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: 3600 * 600, timescale: 600))
        
        input.markAsFinished()
        let sem = DispatchSemaphore(value: 0)
        writer.finishWriting { sem.signal() }
        sem.wait()
        
        guard writer.status == .completed else {
            print("[PlaybackEngine] Blank carrier failed: \(writer.error?.localizedDescription ?? "?")")
            return nil
        }
        _blankCarrierURL = url
        print("[PlaybackEngine] Blank carrier video created")
        return AVURLAsset(url: url)
    }
    
    @MainActor
    public func buildPlayerItem(for sequence: Sequence, using mediaReferences: [MediaAsset], renderSize: CGSize = CGSize(width: 1920, height: 1080), isExport: Bool = false) async -> AVPlayerItem? {
        let composition = AVMutableComposition()
        composition.naturalSize = renderSize
        
        let videoTracks = sequence.tracks.filter { $0.type == .video }
        var maxTimelineDuration: CMTime = .zero
        
        for (trackIndex, videoTrack) in videoTracks.enumerated() {
            let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            for (i, clip) in videoTrack.clips.enumerated() {
                if clip.textProperties != nil {
                    let targetTime = CMTime(seconds: clip.timelineStart, preferredTimescale: 600)
                    let dur = CMTime(seconds: clip.duration, preferredTimescale: 600)
                    // Insert real (black) video frames so AVFoundation calls our compositor
                    if let blankAsset = await PlaybackEngine.getBlankCarrierAsset(renderSize: renderSize),
                       let blankTrack = blankAsset.tracks(withMediaType: .video).first {
                        do {
                            try compVideoTrack?.insertTimeRange(
                                CMTimeRange(start: .zero, duration: dur),
                                of: blankTrack,
                                at: targetTime
                            )
                        } catch {
                            print("[PlaybackEngine] Carrier insert error: \(error)")
                            compVideoTrack?.insertEmptyTimeRange(CMTimeRange(start: targetTime, duration: dur))
                        }
                    } else {
                        compVideoTrack?.insertEmptyTimeRange(CMTimeRange(start: targetTime, duration: dur))
                    }
                    let endTime = CMTimeAdd(targetTime, dur)
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
                    
                    // Include any track that has a clip (video or text) in this segment.
                    // Text clips now have real carrier video on the composition track.
                    let hasClipContent = track.clips.contains { clip in
                        let clipEnd = clip.timelineStart + clip.duration
                        return (clip.timelineStart < end - 0.001 && clipEnd > start + 0.001)
                    }
                    
                    if hasClipContent {
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
    public func updateCompositions(for playerItem: AVPlayerItem, sequence: Sequence, using mediaReferences: [MediaAsset], renderSize: CGSize = CGSize(width: 1920, height: 1080)) {
        guard let composition = playerItem.asset as? AVMutableComposition else { return }
        
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
        
        let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, CGSize(width: renderSize.width, height: CGFloat.greatestFiniteMagnitude), nil)
        
        // Use the full render size so the text image is the same size as the canvas
        let canvasWidth = Int(renderSize.width)
        let canvasHeight = Int(renderSize.height)
        
        guard let context = CGContext(data: nil, width: canvasWidth, height: canvasHeight, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            print("[renderText] ERROR: Failed to create CGContext")
            return nil
        }
        
        context.clear(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        
        // Center the text frame within the full canvas
        let textWidth = min(textSize.width, renderSize.width)
        let textHeight = textSize.height
        let textX = (renderSize.width - textWidth) / 2.0
        let textY = (renderSize.height - textHeight) / 2.0
        
        let textRect = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        CTFrameDraw(frame, context)
        
        guard let cgImage = context.makeImage() else {
            print("[renderText] ERROR: makeImage() returned nil")
            return nil
        }
        
        print("[renderText] OK: text='\(text)' color=\(props.colorHex) canvas=\(canvasWidth)x\(canvasHeight) textSize=\(textSize)")
        return CIImage(cgImage: cgImage)
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
                        print("[Compositor] Found TEXT clip at track \(trackIndex), time \(currentTime), text='\(textProps.text)'")
                        sourceImage = self.renderText(textProps, renderSize: renderSize)
                        if sourceImage == nil {
                            print("[Compositor] WARNING: renderText returned nil!")
                        }
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
