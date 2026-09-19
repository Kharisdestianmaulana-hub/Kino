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
    @Published public var playheadPosition: Double = 0.0 {
        didSet {
            updatePreviewPresentationState()
        }
    }
    @Published public var isPlaying: Bool = false
    @Published public var activeTool: TimelineTool = .selection
    @Published public var currentCompositionItem: AVPlayerItem? = nil
    @Published public var previewPresentationState: PreviewPresentationState = .identity
    
    // Export State
    @Published public var isExporting: Bool = false
    @Published public var exportProgress: Float = 0.0
    @Published public var recentProjects: [RecentProject] = []
    
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
        
        // Project starts as nil so we show the ProjectHubView by default
        self.project = nil
        self.selectedSequenceID = nil
    }
    
    private func saveThumbnail(for proj: Project) {
        guard let item = self.currentCompositionItem else { return }
        let time = CMTime.zero
        let targetSize = CGSize(width: 320, height: 320)
        
        Task {
            if let cgImage = await self.playbackEngine.generateThumbnail(for: item, at: time, size: targetSize) {
                let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                if let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
                    let url = self.projectService.thumbnailURL(for: proj.id)
                    try? jpegData.write(to: url, options: .atomic)
                }
            }
        }
    }

    public func createNewProject(name: String, settings: ProjectSettings, folderURL: URL) {
        var newProject = self.projectService.createProject(name: name)
        newProject.settings = settings
        var sequence = Sequence(name: "Sequence 1")
        sequence.tracks.append(Track(name: "V1", type: .video))
        sequence.tracks.append(Track(name: "A1", type: .audio))
        newProject.sequences.append(sequence)
        
        let safeName = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        let fileURL = folderURL.appendingPathComponent("\(safeName).kino")
        
        do {
            let data = try JSONEncoder().encode(newProject)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to create initial .kino file: \(error)")
        }
        
        let bookmark = projectService.createBookmark(for: fileURL)
        projectService.addOrUpdateRecentProject(project: newProject, bookmarkData: bookmark)
        self.projectService.updateCurrentProject(newProject)
        
        self.projectURL = fileURL
        self.project = newProject
        self.selectedSequenceID = sequence.id
        self.rebuildComposition()
    }
    
    @discardableResult
    public func openRecentProject(id: UUID) -> Bool {
        if let recovered = projectService.recoverAutosavedProject(for: id) {
            projectService.updateCurrentProject(recovered)
            self.project = recovered
            self.selectedSequenceID = recovered.sequences.first?.id
            
            if let recent = projectService.getRecentProjects().first(where: { $0.id == id }),
               let bookmark = recent.bookmarkData,
               let url = projectService.resolveBookmark(data: bookmark) {
                self.projectURL = url
            }
            
            UserDefaults.standard.set(recovered.id.uuidString, forKey: "LastProjectID")
            self.rebuildComposition()
            return true
        } else {
            return false
        }
    }



    public func renameRecentProject(id: UUID, newName: String) {
        projectService.renameRecentProject(id: id, newName: newName)
        loadRecentProjects()
    }
    
    public func deleteRecentProject(id: UUID) {
        projectService.deleteRecentProject(id: id)
        loadRecentProjects()
    }
    public func loadRecentProjects() {
        self.recentProjects = projectService.getRecentProjects()
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
    
    public func addTextClip() {
        guard let seqID = selectedSequenceID,
              let proj = project,
              var seq = proj.sequences.first(where: { $0.id == seqID }) else { return }
        
        let videoTracks = seq.tracks.filter { $0.type == .video }
        var targetTrackID: UUID?
        
        // Find empty space in V2 or above
        for i in (1..<videoTracks.count).reversed() {
            let track = videoTracks[i]
            let overlaps = track.clips.contains { clip in
                let clipEnd = clip.timelineStart + clip.duration
                let newEnd = playheadPosition + 5.0
                return (playheadPosition < clipEnd) && (newEnd > clip.timelineStart)
            }
            if !overlaps {
                targetTrackID = track.id
                break
            }
        }
        
        // If no existing track >= V2 is free (or V2 doesn't exist), create one
        if targetTrackID == nil {
            let newTrackNum = videoTracks.count + 1
            let newTrack = Track(name: "V\(newTrackNum)", type: .video)
            
            if let lastVideoIndex = seq.tracks.lastIndex(where: { $0.type == .video }) {
                seq.tracks.insert(newTrack, at: lastVideoIndex + 1)
            } else {
                seq.tracks.insert(newTrack, at: 0)
            }
            
            var updatedProject = proj
            if let seqIdx = updatedProject.sequences.firstIndex(where: { $0.id == seqID }) {
                updatedProject.sequences[seqIdx] = seq
            }
            self.projectService.updateCurrentProject(updatedProject)
            self.project = updatedProject
            
            targetTrackID = newTrack.id
        }
        
        guard let trackID = targetTrackID else { return }
        
        let textProps = TextProperties()
        let clip = Clip(textProperties: textProps, timelineStart: playheadPosition, sourceStart: 0, duration: 5.0)
        let cmd = AddClipCommand(service: timelineService, sequenceID: seqID, trackID: trackID, clip: clip)
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
                    self.saveThumbnail(for: proj)
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
                    self.saveThumbnail(for: proj)
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
                    self.saveThumbnail(for: proj)
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
        
        guard project != nil else { return }
        
        // Verifikasi status file (isMissing)
        mediaService.verifyMediaReferences(in: &project!)
        
        for asset in project!.mediaReferences {
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
    
    public func relinkAsset(id: UUID) {
        guard project != nil else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try mediaService.relinkAsset(id: id, newURL: url, into: &project!)
                self.restoreSecurityBookmarks()
                self.rebuildComposition()
                self.hasUnsavedChanges = true
                print("Successfully relinked asset to \(url.lastPathComponent)")
            } catch {
                print("Failed to relink asset: \(error)")
            }
        }
    }
    public var isPlayheadOverMissingMedia: Bool {
        guard let project = project, let seqID = selectedSequenceID,
              let seq = project.sequences.first(where: { $0.id == seqID }) else { return false }
        
        for track in seq.tracks {
            for clip in track.clips {
                if playheadPosition >= clip.timelineStart && playheadPosition < clip.timelineStart + clip.duration {
                    if let assetID = clip.mediaAssetID,
                       let asset = project.mediaReferences.first(where: { $0.id == assetID }),
                       asset.isMissing {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    public func isPlayheadInGap() -> Bool {
        guard let seqID = selectedSequenceID, let seq = project?.sequences.first(where: { $0.id == seqID }) else { return true }
        let videoTracks = seq.tracks.filter { $0.type == .video }
        for track in videoTracks {
            for clip in track.clips {
                if playheadPosition >= clip.timelineStart && playheadPosition < clip.timelineStart + clip.duration {
                    return false
                }
            }
        }
        return true
    }

    // MARK: - Playback Engine
    public let playbackEngine = PlaybackEngine()
    
    public func updatePreviewPresentationState() {
        if let context = activeVideoClipContext(at: playheadPosition) {
            let localTime = playheadPosition - context.clip.timelineStart
            var t = context.clip.transform
            t.scale = context.clip.interpolatedValue(for: "scale", at: localTime, fallback: t.scale)
            t.positionX = context.clip.interpolatedValue(for: "positionX", at: localTime, fallback: t.positionX)
            t.positionY = context.clip.interpolatedValue(for: "positionY", at: localTime, fallback: t.positionY)
            t.rotation = context.clip.interpolatedValue(for: "rotation", at: localTime, fallback: t.rotation)
            t.opacity = context.clip.interpolatedValue(for: "opacity", at: localTime, fallback: t.opacity)
            previewPresentationState = PreviewPresentationState(transform: t)
        } else {
            previewPresentationState = .identity
        }
    }
    
    public func activeVideoClipContext(at time: Double) -> ActiveVideoClipContext? {
        guard let project = project,
              let seqID = selectedSequenceID,
              let seq = project.sequences.first(where: { $0.id == seqID }) else {
            return nil
        }
        
        let videoTracks = seq.tracks.filter { $0.type == .video }
        let epsilon: Double = 0.001
        
        // If a clip is already selected, check if it's still under the playhead
        if case .clip(let selectedID) = selection {
            for videoTrack in videoTracks {
                if let clip = videoTrack.clips.first(where: {
                    $0.id == selectedID &&
                    time >= ($0.timelineStart - epsilon) &&
                    time < ($0.timelineStart + $0.duration + epsilon)
                }) {
                    return ActiveVideoClipContext(clip: clip, trackID: videoTrack.id, sequenceID: seqID)
                }
            }
        }
        
        // Otherwise, find the topmost clip at the playhead (first track = topmost in UI)
        for videoTrack in videoTracks {
            if let clip = videoTrack.clips
                .sorted(by: { $0.timelineStart < $1.timelineStart })
                .first(where: {
                    time >= ($0.timelineStart - epsilon) &&
                    time < ($0.timelineStart + $0.duration + epsilon)
                }) {
                return ActiveVideoClipContext(clip: clip, trackID: videoTrack.id, sequenceID: seqID)
            }
        }
        
        return nil
    }
    
    public func previewUpdateClipProperties(_ clip: Clip, inTrack trackID: UUID, inSequence sequenceID: UUID) {
        timelineService.updateClip(clip, inTrack: trackID, inSequence: sequenceID)
        refreshProjectStateWithoutRebuildingPlayback()
        hasUnsavedChanges = true
        
        if let currentItem = currentCompositionItem, let proj = project, let seq = proj.sequences.first(where: { $0.id == sequenceID }) {
            Task { @MainActor in
                let renderSize = CGSize(width: proj.settings.resolutionWidth, height: proj.settings.resolutionHeight)
                self.playbackEngine.updateCompositions(for: currentItem, sequence: seq, using: proj.mediaReferences, renderSize: renderSize, frameRate: proj.settings.frameRate)
            }
        }
    }
    
    public func previewPresentationOnly(transform: ClipTransform) {
        previewPresentationState = PreviewPresentationState(transform: transform)
    }
    
    public func executeClipPropertiesCommand(_ command: ModifyClipPropertiesCommand) {
        do {
            try commandManager.execute(command)
            refreshProjectStateWithoutRebuildingPlayback()
            hasUnsavedChanges = true
            
            if let currentItem = currentCompositionItem, let proj = project, let seq = proj.sequences.first(where: { $0.id == selectedSequenceID }) {
                Task { @MainActor in
                    let renderSize = CGSize(width: proj.settings.resolutionWidth, height: proj.settings.resolutionHeight)
                    self.playbackEngine.updateCompositions(for: currentItem, sequence: seq, using: proj.mediaReferences, renderSize: renderSize, frameRate: proj.settings.frameRate)
                }
            }
            
            if let proj = project {
                DispatchQueue.global(qos: .background).async {
                    self.projectService.autosaveProject(proj)
                    self.saveThumbnail(for: proj)
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
        let renderSize = CGSize(width: project.settings.resolutionWidth, height: project.settings.resolutionHeight)
        
        Task {
            let item = await playbackEngine.buildPlayerItem(for: seq, using: project.mediaReferences, renderSize: renderSize, frameRate: project.settings.frameRate)
            
            await MainActor.run {
                self.currentCompositionItem = item
                self.updatePreviewPresentationState()
            }
        }
    }
    
        public func deleteMediaAsset(_ asset: MediaAsset) {
        if var project = self.project {
            project.mediaReferences.removeAll(where: { $0.id == asset.id })
            projectService.updateCurrentProject(project)
            refreshState()
            if selection == .mediaAsset(asset.id) {
                selection = .none
            }
        }
    }
    
    // MARK: - Export
    public func startExport() {
                guard let project = project,
              let seqID = selectedSequenceID,
              let seq = project.sequences.first(where: { $0.id == seqID }) else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.mpeg4Movie]
        panel.nameFieldStringValue = "\(project.metadata.name)_Export.mp4"
        
        if panel.runModal() == .OK, let url = panel.url {
            isExporting = true
            exportProgress = 0.0
            
            Task {
                do {
                    let renderSize = CGSize(width: project.settings.resolutionWidth, height: project.settings.resolutionHeight)
                    guard let item = await playbackEngine.buildPlayerItem(for: seq, using: project.mediaReferences, renderSize: renderSize, frameRate: project.settings.frameRate, isExport: true) else { return }
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
