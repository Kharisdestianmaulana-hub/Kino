import SwiftUI

public struct TimelineView: View {
    @EnvironmentObject var workspace: WorkspaceState
    
    private let trackHeaderWidth: CGFloat = 150.0
    private let timeScale: CGFloat = 10.0 // 10 piksel per detik
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Timeline
            HStack {
                Text("Timeline")
                    .font(.headline)
                
                Spacer()
                
                // Deretan Tools Editing
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Button(action: { workspace.undo() }) { Image(systemName: "arrow.uturn.backward") }
                            .buttonStyle(BorderlessButtonStyle())
                            .help("Undo (Cmd+Z)")
                        
                        Button(action: { workspace.redo() }) { Image(systemName: "arrow.uturn.forward") }
                            .buttonStyle(BorderlessButtonStyle())
                            .help("Redo (Shift+Cmd+Z)")
                    }
                    
                    Divider().frame(height: 14)
                    
                    HStack(spacing: 12) {
                        Button(action: { workspace.activeTool = .selection }) { 
                            Image(systemName: "cursorarrow") 
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .foregroundColor(workspace.activeTool == .selection ? .accentColor : .primary)
                        .help("Selection Tool (V)")
                        
                        Button(action: { workspace.activeTool = .blade }) { 
                            Image(systemName: "scissors") 
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .foregroundColor(workspace.activeTool == .blade ? .accentColor : .primary)
                        .help("Blade Tool (B)")
                        
                        Button(action: {}) { Image(systemName: "ruler") }
                            .buttonStyle(BorderlessButtonStyle())
                            .help("Toggle Snapping (N)")
                            
                        Divider().frame(height: 14)
                        
                        Button(action: { workspace.addTextClip() }) { 
                            Image(systemName: "textformat") 
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .keyboardShortcut("t", modifiers: .command)
                        .help("Add Text Clip (Cmd+T)")
                    }
                }
                .padding(.trailing, 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if let project = workspace.project,
               let sequenceID = workspace.selectedSequenceID,
               let sequence = project.sequences.first(where: { $0.id == sequenceID }) {
                
                ScrollView([.vertical, .horizontal]) {
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            // Ruler (Sekarang di dalam ScrollView agar sinkron dengan Clip)
                            TimelineRulerView(timeScale: timeScale)
                            
                            Divider()
                            
                            // Container Track
                            VStack(alignment: .leading, spacing: 2) {
                                let videoTracks = sequence.tracks.filter { $0.type == .video }
                                let audioTracks = sequence.tracks.filter { $0.type == .audio }
                                
                                // Video tracks (dibalik agar Video 2, 3 dsb muncul di ATAS Video 1)
                                ForEach(videoTracks.reversed()) { track in
                                    TrackView(track: track)
                                }
                                
                                if !videoTracks.isEmpty && !audioTracks.isEmpty {
                                    Divider().padding(.vertical, 4)
                                }
                                
                                // Audio tracks (urutan normal ke bawah)
                                ForEach(audioTracks) { track in
                                    TrackView(track: track)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .frame(minWidth: 2000, minHeight: 300, alignment: .topLeading)
                        }
                        
                        // Hit area transparan KHUSUS DI AREA RULER untuk scrubbing playhead
                        Color.white.opacity(0.001)
                            .frame(width: 2000, height: 24) // Hanya menutupi Ruler
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if workspace.isPlaying { workspace.isPlaying = false }
                                        let newTime = max(0, Double((value.location.x - trackHeaderWidth) / timeScale))
                                        workspace.playheadPosition = newTime
                                    }
                            )
                        
                        // Garis Playhead Merah dan Segitiga Terbalik di bagian atas
                        VStack(spacing: 0) {
                            Image(systemName: "arrowtriangle.down.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                                .offset(y: 4)
                            
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 1.5)
                                .frame(maxHeight: .infinity)
                        }
                        .offset(x: trackHeaderWidth + CGFloat(workspace.playheadPosition) * timeScale - 7)
                        .allowsHitTesting(false) // Jangan menghalangi interaksi ke Clip atau Ruler di bawahnya
                    }
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .onTapGesture {
                    // Cabut fokus dari TextField pencarian (jika ada) agar shortcut bekerja lagi!
                    NSApp.keyWindow?.makeFirstResponder(nil)
                    workspace.clearSelection()
                }
                
                // --- KUMPULAN SHORTCUT KEYBOARD TERSEMBUNYI ---
                Group {
                    Button("Delete Clip") {
                        if case .clip(let id) = workspace.selection,
                           let seqID = workspace.selectedSequenceID,
                           let seq = project.sequences.first(where: { $0.id == seqID }),
                           let track = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == id }) }),
                           let clip = track.clips.first(where: { $0.id == id }) {
                            
                            var commands: [Command] = []
                            
                            commands.append(RemoveClipCommand(
                                service: workspace.timelineService,
                                sequenceID: seqID,
                                trackID: track.id,
                                clipID: clip.id
                            ))
                            
                            // Hapus klip tertaut (misal: audio pasangannya) jika ada
                            if let linkedID = clip.linkedClipID,
                               let linkedTrack = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == linkedID }) }) {
                                commands.append(RemoveClipCommand(
                                    service: workspace.timelineService,
                                    sequenceID: seqID,
                                    trackID: linkedTrack.id,
                                    clipID: linkedID
                                ))
                            }
                            
                            if commands.count > 1 {
                                let composite = CompositeCommand(name: "Delete Linked Clips", commands: commands)
                                workspace.execute(composite)
                            } else {
                                workspace.execute(commands[0])
                            }
                            
                            workspace.clearSelection()
                        }
                    }
                    .keyboardShortcut(.delete, modifiers: [])
                    .opacity(0)
                }
            } else {
                EmptyStateView(
                    title: "No Sequence",
                    message: "Create a sequence to start editing.",
                    systemImage: "squares.below.rectangle"
                )
            }
        }
    }
}
