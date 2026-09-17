import Foundation
import AVFoundation

public enum ExportError: Error {
    case missingComposition
    case failed
    case cancelled
}

public class ExportService {
    private var exportSession: AVAssetExportSession?
    
    public init() {}
    
    @MainActor
    public func export(item: AVPlayerItem, to url: URL, progress: @escaping (Float) -> Void) async throws {
        guard let asset = item.asset as? AVComposition else {
            throw ExportError.missingComposition
        }
        
        // Buat export session (H.264 MP4 1080p Preset)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.failed
        }
        
        self.exportSession = session
        session.outputURL = url
        session.outputFileType = .mp4
        session.videoComposition = item.videoComposition
        session.audioMix = item.audioMix
        
        // Jalankan timer untuk progress
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            progress(session.progress)
        }
        
        await session.export()
        timer.invalidate()
        
        if session.status == .failed {
            throw session.error ?? ExportError.failed
        } else if session.status == .cancelled {
            throw ExportError.cancelled
        }
    }
    
    public func cancel() {
        exportSession?.cancelExport()
    }
}
