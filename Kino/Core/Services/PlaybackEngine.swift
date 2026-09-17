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
        
        var allLayerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        
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
                    if let sourceTrack = avAsset.tracks(withMediaType: .video).first {
                        let sourceTime = CMTime(seconds: clip.sourceStart, preferredTimescale: 600)
                        let duration = CMTime(seconds: clip.duration, preferredTimescale: 600)
                        let timeRange = CMTimeRange(start: sourceTime, duration: duration)
                        let targetTime = CMTime(seconds: clip.timelineStart, preferredTimescale: 600)
                        
                        try compVideoTrack?.insertTimeRange(timeRange, of: sourceTrack, at: targetTime)
                        
                        let endTime = CMTimeAdd(targetTime, duration)
                        if endTime > maxTimelineDuration {
                            maxTimelineDuration = endTime
                        }
                        
                        // -- BUILD LAYER INSTRUCTION --
                        if let validCompTrack = compVideoTrack {
                            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: validCompTrack)
                            
                            let sourceSize = sourceTrack.naturalSize
                            let sourceTransform = sourceTrack.preferredTransform
                            let extent = CGRect(origin: .zero, size: sourceSize).applying(sourceTransform)
                            let renderW: CGFloat = 1920.0
                            let renderH: CGFloat = 1080.0
                            let scaleX = renderW / extent.width
                            let scaleY = renderH / extent.height
                            let baseScale = min(abs(scaleX), abs(scaleY))
                            
                            var finalTransform = sourceTransform
                            finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
                            finalTransform = finalTransform.concatenating(CGAffineTransform(scaleX: baseScale, y: baseScale))
                            let scaledWidth = extent.width * baseScale
                            let scaledHeight = extent.height * baseScale
                            let offsetX = (renderW - abs(scaledWidth)) / 2.0
                            let offsetY = (renderH - abs(scaledHeight)) / 2.0
                            finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: offsetX, y: offsetY))
                            
                            // Terapkan user transform (Scale & Position)
                            let userScale = CGFloat(clip.transform.scale)
                            let userPosX = CGFloat(clip.transform.positionX)
                            // AVFoundation Y is inverted
                            let userPosY = -CGFloat(clip.transform.positionY) 
                            
                            // Putar dan skala dari tengah
                            let cx = renderW / 2.0
                            let cy = renderH / 2.0
                            finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: -cx, y: -cy))
                            finalTransform = finalTransform.concatenating(CGAffineTransform(scaleX: userScale, y: userScale))
                            finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: cx, y: cy))
                            
                            // Geser
                            finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: userPosX, y: userPosY))
                            
                            layerInstruction.setTransform(finalTransform, at: .zero)
                            layerInstruction.setOpacity(Float(clip.transform.opacity), at: .zero)
                            
                            allLayerInstructions.append(layerInstruction)
                        }
                    }
                } catch {
                    print("[PlaybackEngine] Error inserting track \(trackIndex) clip \(i): \(error)")
                }
            }
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: maxTimelineDuration)
        
        // Membalik urutan agar track yang dibuat paling baru (index terbesar) berada di PALING ATAS
        mainInstruction.layerInstructions = allLayerInstructions.reversed()
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 60)
        if !allLayerInstructions.isEmpty {
            videoComposition.instructions = [mainInstruction]
        }
        
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
        
        if !allLayerInstructions.isEmpty {
            videoComposition.colorPrimaries = AVVideoColorPrimaries_ITU_R_709_2 as String
            videoComposition.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2 as String
            videoComposition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2 as String
            playerItem.videoComposition = videoComposition
        }
        
        print("[PlaybackEngine] buildPlayerItem DONE: compTracks=\(composition.tracks.count), compDuration=\(composition.duration.seconds)s")
        
        return playerItem
    }
    
    // Solusi Ultimate Anti-Flicker: Update transform langsung ke item yang sedang jalan
    @MainActor
    public func updateCompositions(for playerItem: AVPlayerItem, sequence: Sequence, using mediaReferences: [MediaAsset]) {
        guard let composition = playerItem.asset as? AVMutableComposition else { return }
        let renderSize = CGSize(width: 1920, height: 1080)
        
        let videoComp = AVMutableVideoComposition(asset: composition) { request in
            let time = request.compositionTime
            
            var activeClip: Clip?
            if let videoTrack = sequence.tracks.first(where: { $0.type == .video }) {
                activeClip = videoTrack.clips.first(where: {
                    let start = CMTime(seconds: $0.timelineStart, preferredTimescale: 600)
                    let end = CMTime(seconds: $0.timelineStart + $0.duration, preferredTimescale: 600)
                    return time >= start && time < end
                })
            }
            
            var image = request.sourceImage
            let extent = image.extent
            
            if !extent.isEmpty && !extent.isInfinite {
                let renderW: CGFloat = 1920.0
                let renderH: CGFloat = 1080.0
                
                let scaleX = renderW / extent.width
                let scaleY = renderH / extent.height
                let baseScale = min(scaleX, scaleY)
                
                var baseTransform = CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y)
                baseTransform = baseTransform.scaledBy(x: baseScale, y: baseScale)
                
                let scaledWidth = extent.width * baseScale
                let scaledHeight = extent.height * baseScale
                let offsetX = (renderW - scaledWidth) / 2.0
                let offsetY = (renderH - scaledHeight) / 2.0
                
                image = image.transformed(by: baseTransform)
                image = image.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
                
                if let clip = activeClip {
                    let scale = CGFloat(clip.transform.scale)
                    let rotation = CGFloat(clip.transform.rotation) * .pi / 180.0
                    let tx = CGFloat(clip.transform.positionX)
                    let ty = CGFloat(clip.transform.positionY)
                    let opacity = CGFloat(clip.transform.opacity)
                    
                    let centerX = renderW / 2.0
                    let centerY = renderH / 2.0
                    
                    var userTransform = CGAffineTransform.identity
                    userTransform = userTransform.translatedBy(x: centerX, y: centerY)
                    userTransform = userTransform.scaledBy(x: scale, y: scale)
                    userTransform = userTransform.rotated(by: rotation)
                    userTransform = userTransform.translatedBy(x: -centerX, y: -centerY)
                    userTransform = userTransform.translatedBy(x: tx, y: ty)
                    
                    image = image.transformed(by: userTransform)
                    
                    if opacity < 1.0 {
                        if let filter = CIFilter(name: "CIColorMatrix") {
                            filter.setValue(image, forKey: "inputImage")
                            let alphaVector = CIVector(x: 0, y: 0, z: 0, w: opacity)
                            filter.setValue(alphaVector, forKey: "inputAVector")
                            if let output = filter.outputImage {
                                image = output
                            }
                        }
                    }
                }
            }
            
            let blueBg = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 1920, height: 1080))
            let finalImage = image.composited(over: blueBg)
            
            request.finish(with: finalImage, context: nil)
        }
        
        videoComp.colorPrimaries = AVVideoColorPrimaries_ITU_R_709_2 as String
        videoComp.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2 as String
        videoComp.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2 as String
        videoComp.renderSize = renderSize
        // TAHAP A: Matikan videoComposition untuk jalur Preview agar playback murni menggunakan AVPlayer (tanpa bug black screen)
        // playerItem.videoComposition = videoComp
        
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
