import Foundation

public enum TimelineError: Error {
    case sequenceNotFound
    case trackNotFound
    case clipNotFound
}

public class TimelineService {
    private var projectService: ProjectService
    
    public init(projectService: ProjectService) {
        self.projectService = projectService
    }
    
    private var project: Project? {
        return projectService.currentProject
    }
    
    public func addClip(_ clip: Clip, toTrack trackID: UUID, inSequence sequenceID: UUID) throws {
        guard var currentProject = project else { return }
        guard let seqIndex = currentProject.sequences.firstIndex(where: { $0.id == sequenceID }) else {
            throw TimelineError.sequenceNotFound
        }
        guard let trackIndex = currentProject.sequences[seqIndex].tracks.firstIndex(where: { $0.id == trackID }) else {
            throw TimelineError.trackNotFound
        }
        
        currentProject.sequences[seqIndex].tracks[trackIndex].clips.append(clip)
        projectService.updateCurrentProject(currentProject)
    }
    
    public func removeClip(id clipID: UUID, fromTrack trackID: UUID, inSequence sequenceID: UUID) {
        guard var currentProject = project else { return }
        guard let seqIndex = currentProject.sequences.firstIndex(where: { $0.id == sequenceID }) else { return }
        guard let trackIndex = currentProject.sequences[seqIndex].tracks.firstIndex(where: { $0.id == trackID }) else { return }
        
        currentProject.sequences[seqIndex].tracks[trackIndex].clips.removeAll { $0.id == clipID }
        projectService.updateCurrentProject(currentProject)
    }
    
    public func moveClip(id clipID: UUID, toTime newTime: Double, inTrack trackID: UUID, inSequence sequenceID: UUID) throws {
        guard var currentProject = project else { return }
        guard let seqIndex = currentProject.sequences.firstIndex(where: { $0.id == sequenceID }) else {
            throw TimelineError.sequenceNotFound
        }
        guard let trackIndex = currentProject.sequences[seqIndex].tracks.firstIndex(where: { $0.id == trackID }) else {
            throw TimelineError.trackNotFound
        }
        
        guard let clipIndex = currentProject.sequences[seqIndex].tracks[trackIndex].clips.firstIndex(where: { $0.id == clipID }) else {
            throw TimelineError.clipNotFound
        }
        
        currentProject.sequences[seqIndex].tracks[trackIndex].clips[clipIndex].timelineStart = newTime
        projectService.updateCurrentProject(currentProject)
    }
    
    public func moveClip(id clipID: UUID, toTime newTime: Double, fromTrack sourceTrackID: UUID, toTrack destinationTrackID: UUID, inSequence sequenceID: UUID) throws {
        guard var currentProject = project else { return }
        guard let seqIndex = currentProject.sequences.firstIndex(where: { $0.id == sequenceID }) else { throw TimelineError.sequenceNotFound }
        
        guard let sourceTrackIndex = currentProject.sequences[seqIndex].tracks.firstIndex(where: { $0.id == sourceTrackID }),
              let destTrackIndex = currentProject.sequences[seqIndex].tracks.firstIndex(where: { $0.id == destinationTrackID }) else {
            throw TimelineError.trackNotFound
        }
        
        guard let clipIndex = currentProject.sequences[seqIndex].tracks[sourceTrackIndex].clips.firstIndex(where: { $0.id == clipID }) else { throw TimelineError.clipNotFound }
        
        var clip = currentProject.sequences[seqIndex].tracks[sourceTrackIndex].clips.remove(at: clipIndex)
        clip.timelineStart = newTime
        currentProject.sequences[seqIndex].tracks[destTrackIndex].clips.append(clip)
        projectService.updateCurrentProject(currentProject)
    }
    
    public func getClip(id clipID: UUID, inTrack trackID: UUID, inSequence sequenceID: UUID) -> Clip? {
        guard let currentProject = project else { return nil }
        guard let sequence = currentProject.sequences.first(where: { $0.id == sequenceID }) else { return nil }
        guard let track = sequence.tracks.first(where: { $0.id == trackID }) else { return nil }
        return track.clips.first(where: { $0.id == clipID })
    }
    
    public func updateClip(_ clip: Clip, inTrack trackID: UUID, inSequence sequenceID: UUID) {
        guard var currentProject = project else { return }
        guard let seqIndex = currentProject.sequences.firstIndex(where: { $0.id == sequenceID }) else { return }
        guard let trackIndex = currentProject.sequences[seqIndex].tracks.firstIndex(where: { $0.id == trackID }) else { return }
        guard let clipIndex = currentProject.sequences[seqIndex].tracks[trackIndex].clips.firstIndex(where: { $0.id == clip.id }) else { return }
        
        currentProject.sequences[seqIndex].tracks[trackIndex].clips[clipIndex] = clip
        projectService.updateCurrentProject(currentProject)
    }
    
    public func addTrack(_ track: Track, toSequence sequenceID: UUID, atIndex index: Int? = nil) {
        guard var currentProject = project else { return }
        guard let seqIndex = currentProject.sequences.firstIndex(where: { $0.id == sequenceID }) else { return }
        
        if let index = index, index >= 0, index <= currentProject.sequences[seqIndex].tracks.count {
            currentProject.sequences[seqIndex].tracks.insert(track, at: index)
        } else {
            currentProject.sequences[seqIndex].tracks.append(track)
        }
        
        projectService.updateCurrentProject(currentProject)
    }
    
    public func getSequence(id: UUID) -> Sequence? {
        return project?.sequences.first(where: { $0.id == id })
    }
}
