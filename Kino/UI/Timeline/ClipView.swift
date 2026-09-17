import SwiftUI
import AVFoundation

public struct ClipView: View {
    public let clip: Clip
    public let trackType: TrackType
    public let timeScale: CGFloat
    @EnvironmentObject var workspace: WorkspaceState
    
    // State sementara untuk visualisasi saat di-drag
    enum DragMode {
        case move
        case trimLeft
        case trimRight
        case none
    }
    @State private var dragMode: DragMode = .none
    @State private var dragOffset: CGFloat = 0
    @State private var trimOffset: CGFloat = 0
    @State private var thumbnail: NSImage? = nil
    
    private var asset: MediaAsset? {
        workspace.project?.mediaReferences.first(where: { $0.id == clip.mediaAssetID })
    }
    
    private var assetName: String {
        if let text = clip.textProperties?.text {
            return text.isEmpty ? "Empty Text" : text
        }
        return asset?.originalURL.lastPathComponent ?? "Clip"
    }
    
    private func loadThumbnail() async {
        if clip.textProperties != nil { return } // Text clips don't have file thumbnails
        
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
        var currentDuration: Double {
            if dragMode == .trimLeft {
                return max(0.1, clip.duration - Double(trimOffset / timeScale))
            } else if dragMode == .trimRight {
                return max(0.1, clip.duration + Double(trimOffset / timeScale))
            }
            return clip.duration
        }
        
        var currentTimelineStart: Double {
            if dragMode == .trimLeft {
                return min(clip.timelineStart + clip.duration - 0.1, clip.timelineStart + Double(trimOffset / timeScale))
            }
            return clip.timelineStart
        }
        
        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(clip.textProperties != nil ? Color.purple.opacity(0.4) : Color.gray.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                )
            
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
        .frame(width: max(CGFloat(currentDuration) * timeScale, 5))
        .overlay(
            ZStack {
                // Selection Border
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, lineWidth: 2)
                }
                
                HStack(spacing: 0) {
                    // Left edge hover detection
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                        
                        if isSelected {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 4)
                        }
                    }
                    .frame(width: 10)
                    .onHover { isHovering in
                        if isHovering && workspace.activeTool != .blade {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    
                    // Center hover detection
                    Rectangle()
                        .fill(Color.clear)
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
                    
                    // Right edge hover detection
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                        
                        if isSelected {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 4)
                        }
                    }
                    .frame(width: 10)
                    .onHover { isHovering in
                        if isHovering && workspace.activeTool != .blade {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
            }
        )
        .task {
            await loadThumbnail()
        }
        .offset(x: (CGFloat(currentTimelineStart) * timeScale) + dragOffset)

        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("TrackSpace"))
                .onChanged { value in
                    if workspace.activeTool == .blade { return }
                    
                    if !isSelected {
                        workspace.selectClip(id: clip.id)
                    }
                    
                    if dragMode == .none {
                        let clipLeftEdge = CGFloat(clip.timelineStart) * timeScale
                        let clipRightEdge = clipLeftEdge + CGFloat(clip.duration) * timeScale
                        
                        if abs(value.startLocation.x - clipLeftEdge) <= 10 {
                            dragMode = .trimLeft
                        } else if abs(value.startLocation.x - clipRightEdge) <= 10 {
                            dragMode = .trimRight
                        } else {
                            dragMode = .move
                        }
                    }
                    
                    if dragMode == .move {
                        dragOffset = value.translation.width
                    } else {
                        trimOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    if abs(value.translation.width) < 2 && abs(value.translation.height) < 2 {
                        dragOffset = 0
                        trimOffset = 0
                        dragMode = .none
                        
                        if workspace.activeTool == .blade {
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
                        if let seqID = workspace.selectedSequenceID,
                           let seq = workspace.project?.sequences.first(where: { $0.id == seqID }),
                           let track = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == clip.id }) }) {
                            
                            var commands: [Command] = []
                            
                            if dragMode == .move {
                                let additionalTime = Double(value.translation.width / timeScale)
                                let newStartTime = max(0, clip.timelineStart + additionalTime)
                                
                                commands.append(MoveClipCommand(
                                    service: workspace.timelineService,
                                    sequenceID: seqID,
                                    trackID: track.id,
                                    clipID: clip.id,
                                    oldStartTime: clip.timelineStart,
                                    newStartTime: newStartTime
                                ))
                                
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
                                
                            } else if dragMode == .trimLeft || dragMode == .trimRight {
                                let diffTime = Double(value.translation.width / timeScale)
                                
                                var newDuration = clip.duration
                                var newTimelineStart = clip.timelineStart
                                var newSourceStart = clip.sourceStart
                                
                                if dragMode == .trimLeft {
                                    let maxTrim = clip.duration - 0.1
                                    let actualTrim = min(maxTrim, diffTime)
                                    
                                    newTimelineStart += actualTrim
                                    newSourceStart += actualTrim
                                    newDuration -= actualTrim
                                } else {
                                    let actualTrim = max(-clip.duration + 0.1, diffTime)
                                    newDuration += actualTrim
                                }
                                
                                commands.append(TrimClipCommand(
                                    service: workspace.timelineService,
                                    sequenceID: seqID,
                                    trackID: track.id,
                                    clipID: clip.id,
                                    oldTimelineStart: clip.timelineStart,
                                    newTimelineStart: newTimelineStart,
                                    oldSourceStart: clip.sourceStart,
                                    newSourceStart: newSourceStart,
                                    oldDuration: clip.duration,
                                    newDuration: newDuration
                                ))
                                
                                if let linkedID = clip.linkedClipID,
                                   let linkedTrack = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == linkedID }) }),
                                   let linkedClip = linkedTrack.clips.first(where: { $0.id == linkedID }) {
                                    
                                    var linkedNewDuration = linkedClip.duration
                                    var linkedNewTimelineStart = linkedClip.timelineStart
                                    var linkedNewSourceStart = linkedClip.sourceStart
                                    
                                    if dragMode == .trimLeft {
                                        let actualTrim = newTimelineStart - clip.timelineStart
                                        linkedNewTimelineStart += actualTrim
                                        linkedNewSourceStart += actualTrim
                                        linkedNewDuration -= actualTrim
                                    } else {
                                        let actualTrim = newDuration - clip.duration
                                        linkedNewDuration += actualTrim
                                    }
                                    
                                    commands.append(TrimClipCommand(
                                        service: workspace.timelineService,
                                        sequenceID: seqID,
                                        trackID: linkedTrack.id,
                                        clipID: linkedID,
                                        oldTimelineStart: linkedClip.timelineStart,
                                        newTimelineStart: linkedNewTimelineStart,
                                        oldSourceStart: linkedClip.sourceStart,
                                        newSourceStart: linkedNewSourceStart,
                                        oldDuration: linkedClip.duration,
                                        newDuration: linkedNewDuration
                                    ))
                                }
                            }
                            
                            if commands.count > 1 {
                                let composite = CompositeCommand(name: dragMode == .move ? "Move Linked Clips" : "Trim Linked Clips", commands: commands)
                                workspace.execute(composite)
                            } else if commands.count == 1 {
                                workspace.execute(commands[0])
                            }
                        }
                        
                        dragOffset = 0
                        trimOffset = 0
                        dragMode = .none
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
