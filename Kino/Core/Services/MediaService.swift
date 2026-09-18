import Foundation
import AppKit
import AVFoundation
import UniformTypeIdentifiers

public class MediaService {
    public init() {}
    
    /// Creates a MediaAsset reference for a given local file URL without moving or copying the file.
    public func createMediaAsset(from originalURL: URL) throws -> MediaAsset {
        // Create security-scoped bookmark to persist access across app restarts
        var bookmarkData: Data? = nil
        var isImage = false
        do {
            let isSecurityScoped = originalURL.startAccessingSecurityScopedResource()
            bookmarkData = try originalURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let type = try? originalURL.resourceValues(forKeys: [.contentTypeKey]).contentType
            isImage = type?.conforms(to: .image) ?? false
            
            if isSecurityScoped {
                originalURL.stopAccessingSecurityScopedResource()
            }
        } catch {
            print("Failed to create bookmark: \(error)")
        }
        
        // Read metadata using AVFoundation
        let asset = AVURLAsset(url: originalURL)
        let duration = asset.duration.seconds.isNaN ? 0 : asset.duration.seconds
        
        let videoTracks = asset.tracks(withMediaType: .video)
        let audioTracks = asset.tracks(withMediaType: .audio)
        let hasVideo = !videoTracks.isEmpty
        let hasAudio = !audioTracks.isEmpty
        
        var resolutionWidth: Int? = nil
        var resolutionHeight: Int? = nil
        var frameRate: Double? = nil
        
        if let vTrack = videoTracks.first {
            let size = vTrack.naturalSize.applying(vTrack.preferredTransform)
            resolutionWidth = Int(abs(size.width))
            resolutionHeight = Int(abs(size.height))
            frameRate = Double(vTrack.nominalFrameRate)
        } else if isImage {
            if let nsImage = NSImage(contentsOf: originalURL) {
                resolutionWidth = Int(nsImage.size.width)
                resolutionHeight = Int(nsImage.size.height)
            }
        }
        
        var fileSizeBytes: Int64? = nil
        if let attrs = try? FileManager.default.attributesOfItem(atPath: originalURL.path),
           let size = attrs[.size] as? Int64 {
            fileSizeBytes = size
        }
        
        let metadata = MediaMetadata(
            duration: isImage ? 5.0 : duration,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isImage: isImage,
            resolutionWidth: resolutionWidth,
            resolutionHeight: resolutionHeight,
            frameRate: frameRate,
            fileSizeBytes: fileSizeBytes
        )
        
        return MediaAsset(originalURL: originalURL, bookmarkData: bookmarkData, metadata: metadata)
    }
    
    /// Registers a media asset into a project's media references.
    public func registerAsset(_ asset: MediaAsset, into project: inout Project) {
        if !project.mediaReferences.contains(where: { $0.id == asset.id }) {
            project.mediaReferences.append(asset)
        }
    }
    
    /// Verifies all media references in a project. Flags them as isMissing if the file cannot be found.
    public func verifyMediaReferences(in project: inout Project) {
        for i in 0..<project.mediaReferences.count {
            let asset = project.mediaReferences[i]
            var exists = false
            
            if let bookmark = asset.bookmarkData {
                var isStale = false
                if let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                    exists = FileManager.default.fileExists(atPath: url.path)
                    
                    if exists && isStale {
                        // Auto-update stale bookmark
                        let isSecurityScoped = url.startAccessingSecurityScopedResource()
                        if let newBookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                            project.mediaReferences[i].bookmarkData = newBookmark
                        }
                        if isSecurityScoped { url.stopAccessingSecurityScopedResource() }
                    }
                }
            } else {
                exists = FileManager.default.fileExists(atPath: asset.originalURL.path)
            }
            
            project.mediaReferences[i].isMissing = !exists
        }
    }
    
    /// Relinks a missing asset to a newly selected URL.
    public func relinkAsset(id: UUID, newURL: URL, into project: inout Project) throws {
        guard let index = project.mediaReferences.firstIndex(where: { $0.id == id }) else { return }
        
        let isSecurityScoped = newURL.startAccessingSecurityScopedResource()
        let bookmarkData = try newURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        if isSecurityScoped { newURL.stopAccessingSecurityScopedResource() }
        
        project.mediaReferences[index].originalURL = newURL
        project.mediaReferences[index].bookmarkData = bookmarkData
        project.mediaReferences[index].isMissing = false
    }
}

public class WaveformGenerator {
    public static func generateWaveform(for url: URL, size: CGSize) async -> NSImage? {
        return await Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: url)
            guard let track = asset.tracks(withMediaType: .audio).first else { return nil }
            
            do {
                let reader = try AVAssetReader(asset: asset)
                let outputSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: false
                ]
                
                let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
                reader.add(trackOutput)
                reader.startReading()
                
                var allSamples = [Float]()
                allSamples.reserveCapacity(50000)
                
                while reader.status == .reading {
                    autoreleasepool {
                        if let sampleBuffer = trackOutput.copyNextSampleBuffer(),
                           let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                            
                            let length = CMBlockBufferGetDataLength(blockBuffer)
                            var data = Data(count: length)
                            data.withUnsafeMutableBytes { buffer in
                                _ = CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: buffer.baseAddress!)
                            }
                            
                            data.withUnsafeBytes { ptr in
                                let int16Ptr = ptr.bindMemory(to: Int16.self)
                                let count = int16Ptr.count
                                let strideSize = max(1, count / 50) // Hanya ambil 50 sampel per buffer
                                for i in stride(from: 0, to: count, by: strideSize) {
                                    allSamples.append(abs(Float(int16Ptr[i]) / Float(Int16.max)))
                                }
                            }
                        }
                    }
                }
                
                guard !allSamples.isEmpty else { return nil }
                
                let targetCount = Int(size.width)
                var samples = [Float]()
                if allSamples.count > targetCount {
                    let chunk = max(1, allSamples.count / targetCount)
                    for i in 0..<targetCount {
                        let start = i * chunk
                        let end = min(start + chunk, allSamples.count)
                        var maxVal: Float = 0
                        for j in start..<end {
                            maxVal = max(maxVal, allSamples[j])
                        }
                        samples.append(maxVal)
                    }
                } else {
                    samples = allSamples
                }
                
                // Draw waveform
                let image = NSImage(size: size)
                image.lockFocus()
                
                guard let context = NSGraphicsContext.current?.cgContext else {
                    image.unlockFocus()
                    return nil
                }
                
                context.setFillColor(NSColor.green.cgColor)
                
                let sampleCount = samples.count
                let widthPerSample = size.width / CGFloat(sampleCount)
                
                for (index, sample) in samples.enumerated() {
                    let height = CGFloat(sample) * size.height
                    let rect = CGRect(x: CGFloat(index) * widthPerSample,
                                      y: (size.height - height) / 2.0,
                                      width: max(1, widthPerSample),
                                      height: max(1, height))
                    context.fill(rect)
                }
                
                image.unlockFocus()
                return image
            } catch {
                print("Failed to generate waveform: \(error)")
                return nil
            }
        }.value
    }
}

public class ThumbnailCache {
    public static let shared = ThumbnailCache()
    private var cache = [String: NSImage]()
    private let queue = DispatchQueue(label: "ThumbnailCacheQueue", attributes: .concurrent)
    
    public func getThumbnail(for key: String) -> NSImage? {
        var image: NSImage?
        queue.sync { image = cache[key] }
        return image
    }
    
    public func setThumbnail(_ image: NSImage, for key: String) {
        queue.async(flags: .barrier) {
            self.cache[key] = image
        }
    }
}
