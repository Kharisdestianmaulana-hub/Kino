import SwiftUI
import AVFoundation

public struct MediaGridItemView: View {
    public let asset: MediaAsset
    @EnvironmentObject var workspace: WorkspaceState
    @State private var thumbnail: NSImage? = nil
    
    public init(asset: MediaAsset) {
        self.asset = asset
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.4))
                    .aspectRatio(16/9, contentMode: .fit)
                
                if let img = thumbnail {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if asset.metadata.hasVideo {
                    Image(systemName: "film")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                } else {
                    HStack(spacing: 3) {
                        ForEach(0..<8, id: \.self) { _ in
                            Capsule()
                                .fill(Color.accentColor.opacity(0.8))
                                .frame(width: 4, height: CGFloat.random(in: 10...30))
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    if !asset.metadata.isImage && asset.metadata.duration > 0 {
                        HStack {
                            Spacer()
                            Text(formatDuration(asset.metadata.duration))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                                .foregroundColor(.white)
                        }
                        .padding(4)
                    }
                }
            }
            
            Text(asset.originalURL.lastPathComponent)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(workspace.selection == .mediaAsset(asset.id) ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(workspace.selection == .mediaAsset(asset.id) ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onHover { isHovering in
            if isHovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .onTapGesture {
            workspace.selection = .mediaAsset(asset.id)
        }
        // Fallback jika Drag & Drop gagal di environment OS user:
        .contextMenu {
            Button("Add to Timeline") {
                workspace.appendAssetToTimeline(asset)
            }
            Button(role: .destructive) {
                workspace.deleteMediaAsset(asset)
            } label: {
                Label("Delete Media", systemImage: "trash")
            }
        }
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        let cacheKey = asset.id.uuidString
        if let cached = ThumbnailCache.shared.getThumbnail(for: cacheKey) {
            await MainActor.run { self.thumbnail = cached }
            return
        }
        
        guard let bookmark = asset.bookmarkData else { return }
        
        let ext = asset.originalURL.pathExtension.lowercased()
        let isImage = ["png", "jpg", "jpeg", "heic", "tiff"].contains(ext)
        
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { return }
        
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        if isImage {
            if let nsImage = NSImage(contentsOf: url) {
                ThumbnailCache.shared.setThumbnail(nsImage, for: cacheKey)
                await MainActor.run { self.thumbnail = nsImage }
            }
            return
        }
        
        if !asset.metadata.hasVideo { return }
        
        let avAsset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 300, height: 300)
        
        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            ThumbnailCache.shared.setThumbnail(nsImage, for: cacheKey)
            await MainActor.run {
                self.thumbnail = nsImage
            }
        } catch {
            print("Failed to generate thumbnail: \(error)")
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
