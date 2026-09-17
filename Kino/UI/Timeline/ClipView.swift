import SwiftUI
import AVFoundation

public struct ClipView: View {
    public let clip: Clip
    public let trackType: TrackType
    public let timeScale: CGFloat
    @EnvironmentObject var workspace: WorkspaceState
    
    // State sementara untuk visualisasi saat di-drag
    @State private var dragOffset: CGFloat = 0
    @State private var thumbnail: NSImage? = nil
    
    private var asset: MediaAsset? {
        workspace.project?.mediaReferences.first(where: { $0.id == clip.mediaAssetID })
    }
    
    private var assetName: String {
        asset?.originalURL.lastPathComponent ?? "Clip"
    }
    
    private func loadThumbnail() async {
        let cacheKey = "\(clip.id.uuidString)_\(trackType.rawValue)"
        if let cached = ThumbnailCache.shared.getThumbnail(for: cacheKey) {
            await MainActor.run { self.thumbnail = cached }
            return
        }
        
        guard let asset = asset, let bookmark = asset.bookmarkData else { return }
              
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
        if trackType == .audio {
            if let waveform = await WaveformGenerator.generateWaveform(for: url, size: CGSize(width: 500, height: 60)) {
                ThumbnailCache.shared.setThumbnail(waveform, for: cacheKey)
                await MainActor.run { self.thumbnail = waveform }
            }
            return
        }
        
        if !asset.metadata.hasVideo { return }
        
        let avAsset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 200, height: 100)
        
        let time = CMTime(seconds: clip.sourceStart, preferredTimescale: 600)
        let timeValue = NSValue(time: time)
        
        generator.generateCGImagesAsynchronously(forTimes: [timeValue]) { requestedTime, cgImage, actualTime, result, error in
            if let image = cgImage {
                let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
                ThumbnailCache.shared.setThumbnail(nsImage, for: cacheKey)
                DispatchQueue.main.async {
                    self.thumbnail = nsImage
                }
            } else {
                print("Failed to generate thumbnail for clip: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    private var isSelected: Bool {
        if case .clip(let id) = workspace.selection {
            return id == clip.id || id == clip.linkedClipID
        }
        return false
    }
    
    public var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
            
            GeometryReader { geo in
                if trackType == .video {
                    if let thumb = thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .opacity(isSelected ? 0.9 : 0.7)
                    }
                } else {
                    if let thumb = thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .opacity(isSelected ? 0.9 : 0.7)
                    } else {
                        // Placeholder loading
                        Path { path in
                            let w = geo.size.width
                            let h = geo.size.height
                            path.move(to: CGPoint(x: 0, y: h/2))
                            path.addLine(to: CGPoint(x: w, y: h/2))
                        }
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        .opacity(isSelected ? 0.9 : 0.7)
                    }
                }
            }.clipShape(RoundedRectangle(cornerRadius: 4))
            
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            
            VStack(alignment: .leading) {
                Text(assetName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                
                Spacer(minLength: 0)
            }
            .padding(4)
        }
        .frame(width: max(CGFloat(clip.duration) * timeScale, 5))
        .offset(x: (CGFloat(clip.timelineStart) * timeScale) + dragOffset)
        .onHover { isHovering in
            if isHovering { 
                if workspace.activeTool == .blade {
                    NSCursor.crosshair.push() 
                } else {
                    NSCursor.pointingHand.push()
                }
            } else { 
                NSCursor.pop() 
            }
        }
        .task {
            await loadThumbnail()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("TrackSpace"))
                .onChanged { value in
                    // Jika tool Blade, abaikan drag visual
                    if workspace.activeTool == .blade { return }
                    
                    if !isSelected {
                        workspace.selectClip(id: clip.id)
                    }
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    // Jika pergerakan sangat kecil (sekadar klik)
                    if abs(value.translation.width) < 2 && abs(value.translation.height) < 2 {
                        dragOffset = 0
                        if workspace.activeTool == .blade {
                            // value.startLocation.x sekarang 100% relatif terhadap titik nol Track (bukan Clip!)
                            let splitTimelineTime = Double(value.startLocation.x / timeScale)
                            
                            if splitTimelineTime > clip.timelineStart + 0.1 && splitTimelineTime < clip.timelineStart + clip.duration - 0.1 {
                                if let seqID = workspace.selectedSequenceID,
                                   let seq = workspace.project?.sequences.first(where: { $0.id == seqID }),
                                   let track = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == clip.id }) }) {
                                    
                                    let command = SplitClipCommand(
                                        service: workspace.timelineService,
                                        sequenceID: seqID,
                                        trackID: track.id,
                                        originalClip: clip,
                                        splitTime: splitTimelineTime
                                    )
                                    workspace.execute(command)
                                    workspace.activeTool = .selection 
                                }
                            }
                        } else {
                            workspace.selectClip(id: clip.id)
                        }
                    } else if workspace.activeTool == .selection {
                        // Logika Move Clip
                        let additionalTime = Double(value.translation.width / timeScale)
                        let newStartTime = max(0, clip.timelineStart + additionalTime)
                        dragOffset = 0
                        
                        if let seqID = workspace.selectedSequenceID,
                           let seq = workspace.project?.sequences.first(where: { $0.id == seqID }),
                           let track = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == clip.id }) }) {
                            
                            var commands: [Command] = []
                            
                            commands.append(MoveClipCommand(
                                service: workspace.timelineService,
                                sequenceID: seqID,
                                trackID: track.id,
                                clipID: clip.id,
                                oldStartTime: clip.timelineStart,
                                newStartTime: newStartTime
                            ))
                            
                            // Cek Linked Clip
                            if let linkedID = clip.linkedClipID,
                               let linkedTrack = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == linkedID }) }),
                               let linkedClip = linkedTrack.clips.first(where: { $0.id == linkedID }) {
                                
                                let linkedNewStartTime = max(0, linkedClip.timelineStart + additionalTime)
                                commands.append(MoveClipCommand(
                                    service: workspace.timelineService,
                                    sequenceID: seqID,
                                    trackID: linkedTrack.id,
                                    clipID: linkedID,
                                    oldStartTime: linkedClip.timelineStart,
                                    newStartTime: linkedNewStartTime
                                ))
                            }
                            
                            if commands.count > 1 {
                                let composite = CompositeCommand(name: "Move Linked Clips", commands: commands)
                                workspace.execute(composite)
                            } else {
                                workspace.execute(commands[0])
                            }
                        }
                    }
                }
        )
        .contextMenu {
            if clip.linkedClipID != nil {
                Button("Unlink Clip") {
                    if let seqID = workspace.selectedSequenceID,
                       let seq = workspace.project?.sequences.first(where: { $0.id == seqID }),
                       let track = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == clip.id }) }) {
                        
                        var newClip = clip
                        newClip.linkedClipID = nil
                        
                        var commands: [Command] = [
                            ModifyClipPropertiesCommand(service: workspace.timelineService, sequenceID: seqID, trackID: track.id, oldClip: clip, newClip: newClip)
                        ]
                        
                        if let linkedID = clip.linkedClipID,
                           let linkedTrack = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == linkedID }) }),
                           var linkedClip = linkedTrack.clips.first(where: { $0.id == linkedID }) {
                            let oldLinkedClip = linkedClip
                            linkedClip.linkedClipID = nil
                            commands.append(ModifyClipPropertiesCommand(service: workspace.timelineService, sequenceID: seqID, trackID: linkedTrack.id, oldClip: oldLinkedClip, newClip: linkedClip))
                        }
                        
                        workspace.execute(CompositeCommand(name: "Unlink Clips", commands: commands))
                    }
                }
            }
        }
    }
}
