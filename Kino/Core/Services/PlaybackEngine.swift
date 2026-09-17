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
        
        let renderSize = CGSize(width: 1920, height: 1080) // Default HD
        
        // --- PROSES VIDEO TRACK ---
        // --- PROSES VIDEO TRACK ---
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
                        // Jika ini foto, sisipkan empty time range agar track komposisi tetap punya durasi
                        compVideoTrack?.insertEmptyTimeRange(CMTimeRange(start: targetTime, duration: duration))
                        
                        let endTime = CMTimeAdd(targetTime, duration)
                        if endTime > maxTimelineDuration {
                            maxTimelineDuration = endTime
                        }
                        // Note: Untuk merender foto secara utuh dalam AVVideoComposition biasa,
                        // kita butuh CALayer (AVVideoCompositionCoreAnimationTool) atau Custom Compositor.
                        // Karena arsitektur sekarang menggunakan layerInstructions murni,
                        // foto belum bisa dirender tanpa Custom Compositor. 
                        // TODO: Pindah ke Custom Compositor untuk mendukung gambar dan teks penuh.
                    }
                } catch {
                    print("[PlaybackEngine] Error inserting track \(trackIndex) clip \(i): \(error)")
                }
            }
        }
        
        let videoComposition = PlaybackEngine.buildVideoComposition(for: sequence, in: composition, using: mediaReferences, renderSize: renderSize, duration: maxTimelineDuration)
        
        // --- PROSES AUDIO TRACK ---
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
                            
                            // Amankan durasi audio jika track aslinya lebih pendek dari clip.duration
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
        
        print("[PlaybackEngine] buildPlayerItem DONE: compTracks=\(composition.tracks.count), compDuration=\(composition.duration.seconds)s")
        
        return playerItem
    }
    
    // Helper function untuk membangun video composition dengan layer instructions standar
    public static func buildVideoComposition(for sequence: Sequence, in composition: AVMutableComposition, using mediaReferences: [MediaAsset], renderSize: CGSize, duration: CMTime) -> AVMutableVideoComposition? {
        var allLayerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        
        let videoTracks = sequence.tracks.filter { $0.type == .video }
        let compVideoTracks = composition.tracks(withMediaType: .video)
        
        guard compVideoTracks.count == videoTracks.count else { return nil }
        
        for (trackIndex, videoTrack) in videoTracks.enumerated() {
            let compTrack = compVideoTracks[trackIndex]
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack)
            
            
            for clip in videoTrack.clips {
                guard let assetRef = mediaReferences.first(where: { $0.id == clip.mediaAssetID }) else { continue }
                guard let bookmark = assetRef.bookmarkData else { continue }
                var isStale = false
                guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { continue }
                
                let avAsset = AVURLAsset(url: url)
                guard let sourceTrack = avAsset.tracks(withMediaType: .video).first else { continue }
                
                let targetTime = CMTime(seconds: clip.timelineStart, preferredTimescale: 600)
                let sourceSize = sourceTrack.naturalSize
                let sourceTransform = sourceTrack.preferredTransform
                let extent = CGRect(origin: .zero, size: sourceSize).applying(sourceTransform)
                
                let scaleX = renderSize.width / extent.width
                let scaleY = renderSize.height / extent.height
                let baseScale = min(abs(scaleX), abs(scaleY))
                
                var finalTransform = sourceTransform
                finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
                finalTransform = finalTransform.concatenating(CGAffineTransform(scaleX: baseScale, y: baseScale))
                let scaledWidth = extent.width * baseScale
                let scaledHeight = extent.height * baseScale
                let offsetX = (renderSize.width - abs(scaledWidth)) / 2.0
                let offsetY = (renderSize.height - abs(scaledHeight)) / 2.0
                finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: offsetX, y: offsetY))
                
                let userScale = CGFloat(clip.transform.scale)
                let userPosX = CGFloat(clip.transform.positionX)
                let userPosY = -CGFloat(clip.transform.positionY) 
                
                let cx = renderSize.width / 2.0
                let cy = renderSize.height / 2.0
                finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: -cx, y: -cy))
                finalTransform = finalTransform.concatenating(CGAffineTransform(scaleX: userScale, y: userScale))
                finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: cx, y: cy))
                finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: userPosX, y: userPosY))
                
                layerInstruction.setTransform(finalTransform, at: targetTime)
                layerInstruction.setOpacity(Float(clip.transform.opacity), at: targetTime)
            }
            allLayerInstructions.append(layerInstruction)
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        mainInstruction.layerInstructions = allLayerInstructions.reversed()
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
        videoComposition.instructions = [mainInstruction]
        videoComposition.colorPrimaries = AVVideoColorPrimaries_ITU_R_709_2 as String
        videoComposition.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2 as String
        videoComposition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2 as String
        
        return videoComposition
    }
    
    @MainActor
    public func updateCompositions(for playerItem: AVPlayerItem, sequence: Sequence, using mediaReferences: [MediaAsset]) {
        guard let composition = playerItem.asset as? AVMutableComposition else { return }
        let renderSize = CGSize(width: 1920, height: 1080)
        let duration = composition.duration
        
        if let videoComposition = PlaybackEngine.buildVideoComposition(for: sequence, in: composition, using: mediaReferences, renderSize: renderSize, duration: duration) {
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
