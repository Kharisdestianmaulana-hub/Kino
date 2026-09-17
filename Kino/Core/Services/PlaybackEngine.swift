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
    public func buildPlayerItem(for sequence: Sequence, using mediaReferences: [MediaAsset]) async -> AVPlayerItem? {
        let composition = AVMutableComposition()
        composition.naturalSize = CGSize(width: 1920, height: 1080)
        let renderSize = CGSize(width: 1920, height: 1080)
        
        let videoTracks = sequence.tracks.filter { $0.type == .video }
        var maxTimelineDuration: CMTime = .zero
        
        for (trackIndex, videoTrack) in videoTracks.enumerated() {
            let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            for (i, clip) in videoTrack.clips.enumerated() {
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
                        _ = url.startAccessingSecurityScopedResource()
                        if let img = CIImage(contentsOf: url) {
                            imageCache[assetRef.id] = img
                        }
                    }
                }
            }
        }
        
        let videoComposition = AVMutableVideoComposition(asset: composition) { request in
            // Create a transparent background
            var finalImage = CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: renderSize))
            let currentTime = request.compositionTime.seconds
            
            // Render tracks from bottom to top
            for (trackIndex, videoTrack) in videoTracks.enumerated().reversed() {
                let compTrack = compVideoTracks[trackIndex]
                
                // Find clip at current time
                if let clip = videoTrack.clips.first(where: { currentTime >= $0.timelineStart && currentTime < $0.timelineStart + $0.duration }) {
                    
                    guard let assetRef = mediaReferences.first(where: { $0.id == clip.mediaAssetID }) else { continue }
                    
                    var sourceImage: CIImage? = nil
                    
                    if assetRef.metadata.isImage {
                        sourceImage = imageCache[assetRef.id]
                    } else {
                        sourceImage = request.sourceFrameByTrackID(compTrack.trackID)
                    }
                    
                    if var img = sourceImage {
                        // Center image to renderSize
                        let imgExtent = img.extent
                        let scaleX = renderSize.width / imgExtent.width
                        let scaleY = renderSize.height / imgExtent.height
                        let baseScale = min(abs(scaleX), abs(scaleY))
                        
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
                        
                        // Apply opacity
                        let opacity = CGFloat(clip.transform.opacity)
                        if opacity < 1.0 {
                            let filter = CIFilter(name: "CIColorMatrix")!
                            filter.setValue(img, forKey: kCIInputImageKey)
                            filter.setValue(CIVector(x: 0, y: 0, z: 0, w: opacity), forKey: "inputAVector")
                            if let outImg = filter.outputImage {
                                img = outImg
                            }
                        }
                        
                        finalImage = img.composited(over: finalImage)
                    }
                }
            }
            request.finish(with: finalImage, context: nil)
        }
        
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
        return videoComposition
    }
    
    @MainActor
    public func updateCompositions(for playerItem: AVPlayerItem, sequence: Sequence, using mediaReferences: [MediaAsset]) {
        guard let composition = playerItem.asset as? AVMutableComposition else { return }
        let renderSize = CGSize(width: 1920, height: 1080)
        let duration = composition.duration
        
        if let videoComposition = PlaybackEngine.buildVideoComposition(for: sequence, in: composition, using: mediaReferences, renderSize: renderSize, duration: duration) {
            // Langsung assign videoComposition (akan re-trigger render graph)
            playerItem.videoComposition = videoComposition
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
