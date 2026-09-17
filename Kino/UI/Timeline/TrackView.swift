import SwiftUI
import UniformTypeIdentifiers

public struct TrackView: View {
    public let track: Track
    @EnvironmentObject var workspace: WorkspaceState
    private let timeScale: CGFloat = 10.0
    
    public var body: some View {
        HStack(spacing: 0) {
            TrackHeaderView(track: track)
            
            Divider()
            
            // Area Kosong Track tempat Clip ditaruh
            ZStack(alignment: .leading) {
                Color.black.opacity(0.15)
                
                ForEach(track.clips) { clip in
                    ClipView(clip: clip, trackType: track.type, timeScale: timeScale)
                }
            }
            .coordinateSpace(name: "TrackSpace")
            .frame(height: 60)
            .contentShape(Rectangle()) // PASTIKAN area drop merespon penuh
            // Menangkap klip yang di-drop dari Media Browser menggunakan UTI .plainText
            .onDrop(of: [UTType.plainText], isTargeted: nil) { providers, location in
                return handleDrop(providers: providers, location: location)
            }
        }
    }
    
    // Logika penerimaan Drag & Drop dari MediaBrowser
    private func handleDrop(providers: [NSItemProvider], location: CGPoint) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) else { return false }
        
        provider.loadDataRepresentation(forTypeIdentifier: UTType.plainText.identifier) { data, error in
            guard let data = data,
                  let idStr = String(data: data, encoding: .utf8),
                  let assetID = UUID(uuidString: idStr),
                  let project = workspace.project,
                  let asset = project.mediaReferences.first(where: { $0.id == assetID }),
                  let seqID = workspace.selectedSequenceID else { return }
            
            DispatchQueue.main.async {
                // Auto-Snap & Auto-Append Logic
                let startTime: Double
                if track.clips.isEmpty {
                    startTime = 0.0
                } else {
                    let lastClipEnd = track.clips.map { $0.timelineStart + $0.duration }.max() ?? 0.0
                    startTime = lastClipEnd
                }
                
                let duration = asset.metadata.duration > 0 ? asset.metadata.duration : 5.0
                
                var commands: [Command] = []
                
                let videoClipID = UUID()
                var audioClipID: UUID? = nil
                
                if asset.metadata.hasAudio {
                    audioClipID = UUID()
                }
                
                let videoClip = Clip(id: videoClipID, mediaAssetID: asset.id, timelineStart: startTime, sourceStart: 0, duration: duration, linkedClipID: audioClipID)
                commands.append(AddClipCommand(service: workspace.timelineService, sequenceID: seqID, trackID: track.id, clip: videoClip))
                
                if let aID = audioClipID {
                    let audioClip = Clip(id: aID, mediaAssetID: asset.id, timelineStart: startTime, sourceStart: 0, duration: duration, linkedClipID: videoClipID)
                    
                    let sequence = workspace.project?.sequences.first(where: { $0.id == seqID })
                    if let audioTrack = sequence?.tracks.first(where: { $0.type == .audio }) {
                        commands.append(AddClipCommand(service: workspace.timelineService, sequenceID: seqID, trackID: audioTrack.id, clip: audioClip))
                    } else {
                        // Jika belum ada track audio, buat satu
                        let newAudioTrack = Track(name: "Audio 1", type: .audio)
                        workspace.timelineService.addTrack(newAudioTrack, toSequence: seqID)
                        commands.append(AddClipCommand(service: workspace.timelineService, sequenceID: seqID, trackID: newAudioTrack.id, clip: audioClip))
                    }
                }
                
                if commands.count > 1 {
                    let composite = CompositeCommand(name: "Add Media", commands: commands)
                    workspace.execute(composite)
                } else if let first = commands.first {
                    workspace.execute(first)
                }
            }
        }
        return true
    }
}
