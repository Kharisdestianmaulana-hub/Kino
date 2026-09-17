import SwiftUI
import Combine
import UniformTypeIdentifiers
import AVFoundation

public enum SelectionState: Equatable {
    case none
    case project
    case sequence(UUID)
    case track(UUID)
    case clip(UUID)
    case mediaAsset(UUID)
}

public enum TimelineTool: Equatable {
    case selection
    case blade
}

public struct ActiveVideoClipContext: Equatable {
    public let clip: Clip
    public let trackID: UUID
    public let sequenceID: UUID
}

public class WorkspaceState: ObservableObject {
    public static let shared = WorkspaceState()
    
    public let projectService: ProjectService
    public let timelineService: TimelineService
    public let mediaService: MediaService
    public let commandManager: CommandManager
    public let exportService = ExportService()
    
    @Published public var project: Project?
    @Published public var selectedSequenceID: UUID?
    @Published public var selection: SelectionState = .none
    @Published public var playheadPosition: Double = 0.0
    @Published public var isPlaying: Bool = false
    @Published public var activeTool: TimelineTool = .selection
    @Published public var currentCompositionItem: AVPlayerItem? = nil
    @Published public var previewPresentationState: PreviewPresentationState = .identity
    
    // Export State
    @Published public var isExporting: Bool = false
    @Published public var exportProgress: Float = 0.0
    
    public init(
        projectService: ProjectService = ProjectService(),
        timelineService: TimelineService? = nil,
        mediaService: MediaService = MediaService(),
        commandManager: CommandManager = CommandManager()
    ) {
        self.projectService = projectService
        self.mediaService = mediaService
        self.commandManager = commandManager
        self.timelineService = timelineService ?? TimelineService(projectService: projectService)
        
        // Auto-recovery check
        if let lastIDString = UserDefaults.standard.string(forKey: "LastProjectID"),
           let lastID = UUID(uuidString: lastIDString),
           projectService.hasAutosave(for: lastID),
           let recovered = projectService.recoverAutosavedProject(for: lastID) {
            
            projectService.updateCurrentProject(recovered)
            self.project = recovered
            self.selectedSequenceID = recovered.sequences.first?.id
            print("Successfully recovered project from autosave.")
        } else {
            let newProject = self.projectService.createProject(name: "Untitled Project")
            var sequence = Sequence(name: "Sequence 1")
            sequence.tracks.append(Track(name: "V1", type: .video))
            sequence.tracks.append(Track(name: "A1", type: .audio))
            var projectWithSequence = newProject
            projectWithSequence.sequences.append(sequence)
            self.projectService.updateCurrentProject(projectWithSequence)
            
            self.project = projectWithSequence
            self.selectedSequenceID = sequence.id
        }
        
        // Bangun komposisi agar player siap menampilkan video saat aplikasi dibuka
        self.rebuildComposition()
    }
    
    public func refreshState() {
        self.project = projectService.currentProject
        self.updatePreviewPresentationState()
        self.rebuildComposition()
    }
    
    public func refreshProjectStateWithoutRebuildingPlayback() {
        self.project = projectService.currentProject
        self.updatePreviewPresentationState()
    }
    
    // Fallback/Alternatif jika Drag & Drop bermasalah: 
    // Menambahkan clip ke akhir track pertama secara otomatis
    public func appendAssetToTimeline(_ asset: MediaAsset) {
        guard let seqID = selectedSequenceID,
              let proj = project,
              let seq = proj.sequences.first(where: { $0.id == seqID }),
              let videoTrack = seq.tracks.first(where: { $0.type == .video }) else { return }
        
        let endTime = videoTrack.clips.map { $0.timelineStart + $0.duration }.max() ?? 0
        let duration = asset.metadata.duration > 0 ? asset.metadata.duration : 5.0
        
        let clip = Clip(mediaAssetID: asset.id, timelineStart: endTime, sourceStart: 0, duration: duration)
        let cmd = AddClipCommand(service: timelineService, sequenceID: seqID, trackID: videoTrack.id, clip: clip)
        execute(cmd)
    }
    
    public func execute(_ command: Command) {
        do {
            try commandManager.execute(command)
            refreshState()
            self.hasUnsavedChanges = true // Tandai kotor
            if let proj = project {
                DispatchQueue.global(qos: .background).async {
                    self.projectService.autosaveProject(proj)
                }
            }
        } catch {
            print("Command Execution Error: \(error)")
        }
    }
    
    public func undo() {
        commandManager.undo()
        if commandManager.lastActionRequiresPlaybackRebuild {
            refreshState()
        } else {
            refreshProjectStateWithoutRebuildingPlayback()
        }
        if let proj = project {
            DispatchQueue.global(qos: .background).async {
                self.projectService.autosaveProject(proj)
            }
        }
    }
    
    public func redo() {
        commandManager.redo()
        if commandManager.lastActionRequiresPlaybackRebuild {
            refreshState()
        } else {
            refreshProjectStateWithoutRebuildingPlayback()
        }
        if let proj = project {
            DispatchQueue.global(qos: .background).async {
                self.projectService.autosaveProject(proj)
            }
        }
    }
    
    public func selectClip(id: UUID) {
        selection = .clip(id)
    }
    
    public func clearSelection() {
        selection = .none
    }
    
    public func deleteSelectedClip() {
        if case .clip(let id) = selection,
           let seqID = selectedSequenceID,
           let seq = project?.sequences.first(where: { $0.id == seqID }),
           let track = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == id }) }),
           let clip = track.clips.first(where: { $0.id == id }) {
            
            let command = RemoveClipCommand(
                service: timelineService,
                sequenceID: seqID,
                trackID: track.id,
                clipID: clip.id
            )
            execute(command)
            clearSelection()
        }
    }
    
    @Published public var projectURL: URL? = nil
    @Published public var isSaving: Bool = false
    @Published public var hasUnsavedChanges: Bool = false // Lacak status kotor
    
    // MARK: - Save / Load Project
    
    @discardableResult
    public func saveProject() -> Bool {
        guard let project = project else { return false }
        
        // Jika project sudah punya lokasi file (sudah pernah disave/diload), langsung overwrite
        if let existingURL = projectURL {
            isSaving = true
            do {
                try projectService.saveProject(project, to: existingURL)
                self.hasUnsavedChanges = false
                print("Project silently saved to \(existingURL)")
            } catch {
                print("Failed to save project: \(error)")
            }
            
            // Hilangkan badge saving perlahan
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.isSaving = false
            }
            return true
        }
        
        // Jika belum (Untitled), minta lokasi baru
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "kino")!].compactMap { $0 }
        panel.nameFieldStringValue = project.metadata.name + ".kino"
        
        if panel.runModal() == .OK, let url = panel.url {
            isSaving = true
            do {
                try projectService.saveProject(project, to: url)
                self.projectURL = url
                self.hasUnsavedChanges = false
                print("Project saved to \(url)")
            } catch {
                print("Failed to save project: \(error)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.isSaving = false
            }
            return true
        }
        
        return false
    }
    
    public func openProject() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "kino")!].compactMap { $0 }
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let loadedProject = try projectService.loadProject(from: url)
                self.project = loadedProject
                self.projectURL = url
                self.selectedSequenceID = loadedProject.sequences.first?.id
                self.playheadPosition = 0
                self.hasUnsavedChanges = false // Project baru load = bersih
                self.clearSelection()
                self.restoreSecurityBookmarks()
                self.rebuildComposition()
                print("Project loaded from \(url)")
            } catch {
                print("Failed to open project: \(error)")
            }
        }
    }
    
    private var activeSecurityURLs: [URL] = []
    
    private func restoreSecurityBookmarks() {
        for url in activeSecurityURLs {
            url.stopAccessingSecurityScopedResource()
        }
        activeSecurityURLs.removeAll()
        
        guard let project = project else { return }
        for asset in project.mediaReferences {
            if let bookmark = asset.bookmarkData {
                var isStale = false
                if let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                    if url.startAccessingSecurityScopedResource() {
                        activeSecurityURLs.append(url)
                    }
                }
            }
        }
    }
    
    // MARK: - Playback Engine
    public let playbackEngine = PlaybackEngine()
    
    public func updatePreviewPresentationState() {
        if let context = activeVideoClipContext(at: playheadPosition) {
            previewPresentationState = PreviewPresentationState(transform: context.clip.transform)
        } else {
            previewPresentationState = .identity
        }
    }
    
    public func activeVideoClipContext(at time: Double) -> ActiveVideoClipContext? {
        guard let project = project,
              let seqID = selectedSequenceID,
              let seq = project.sequences.first(where: { $0.id == seqID }),
              let videoTrack = seq.tracks.first(where: { $0.type == .video }) else {
            return nil
        }
        
        let epsilon: Double = 0.001
        let clip = videoTrack.clips
            .sorted { $0.timelineStart < $1.timelineStart }
            .first {
                time >= ($0.timelineStart - epsilon) && time < ($0.timelineStart + $0.duration + epsilon)
            }
        
        guard let clip else {
            print("[DEBUG] activeVideoClipContext at \(time) returned nil. Clips: \(videoTrack.clips.map { "\($0.id): start=\($0.timelineStart) dur=\($0.duration)" })")
            return nil
        }
        
        return ActiveVideoClipContext(clip: clip, trackID: videoTrack.id, sequenceID: seqID)
    }
    
    public func previewUpdateClipProperties(_ clip: Clip, inTrack trackID: UUID, inSequence sequenceID: UUID) {
        timelineService.updateClip(clip, inTrack: trackID, inSequence: sequenceID)
        refreshProjectStateWithoutRebuildingPlayback()
        hasUnsavedChanges = true
    }
    
    public func previewPresentationOnly(transform: ClipTransform) {
        previewPresentationState = PreviewPresentationState(transform: transform)
    }
    
    public func executeClipPropertiesCommand(_ command: ModifyClipPropertiesCommand) {
        do {
            try commandManager.execute(command)
            refreshProjectStateWithoutRebuildingPlayback()
            hasUnsavedChanges = true
            if let proj = project {
                DispatchQueue.global(qos: .background).async {
                    self.projectService.autosaveProject(proj)
                }
            }
        } catch {
            print("Command Execution Error: \(error)")
        }
    }
    
    public func rebuildComposition() {
        guard let project = project,
              let seqID = selectedSequenceID,
              let seq = project.sequences.first(where: { $0.id == seqID }) else {
            self.currentCompositionItem = nil
            return
        }
        
        Task {
            let item = await playbackEngine.buildPlayerItem(for: seq, using: project.mediaReferences)
            await MainActor.run {
                self.currentCompositionItem = item
                self.updatePreviewPresentationState()
            }
        }
    }
    
    // MARK: - Export
    public func startExport() {
        guard let item = currentCompositionItem, let project = project else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.mpeg4Movie]
        panel.nameFieldStringValue = "\(project.metadata.name)_Export.mp4"
        
        if panel.runModal() == .OK, let url = panel.url {
            isExporting = true
            exportProgress = 0.0
            
            Task {
                do {
                    try await exportService.export(item: item, to: url) { progress in
                        DispatchQueue.main.async {
                            self.exportProgress = progress
                        }
                    }
                    print("Export completed to \(url.path)")
                } catch {
                    print("Export failed: \(error)")
                }
                
                await MainActor.run {
                    self.isExporting = false
                }
            }
        }
    }
    
    public func cancelExport() {
        exportService.cancel()
        isExporting = false
    }
}
