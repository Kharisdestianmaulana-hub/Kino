import Foundation

public class AddClipCommand: Command {
    public let name = "Add Clip"
    
    private let service: TimelineService
    private let sequenceID: UUID
    private let trackID: UUID
    private let clip: Clip
    
    public init(service: TimelineService, sequenceID: UUID, trackID: UUID, clip: Clip) {
        self.service = service
        self.sequenceID = sequenceID
        self.trackID = trackID
        self.clip = clip
    }
    
    public func execute() throws {
        try service.addClip(clip, toTrack: trackID, inSequence: sequenceID)
    }
    
    public func undo() {
        service.removeClip(id: clip.id, fromTrack: trackID, inSequence: sequenceID)
    }
    
    public func redo() throws {
        try execute()
    }
}

public class MoveClipCommand: Command {
    public let name = "Move Clip"
    
    private let service: TimelineService
    private let sequenceID: UUID
    private let clipID: UUID
    private let oldStartTime: Double
    private let newStartTime: Double
    
    private let oldTrackID: UUID
    private var newTrackID: UUID?
    
    public init(service: TimelineService, sequenceID: UUID, trackID: UUID, clipID: UUID, oldStartTime: Double, newStartTime: Double) {
        self.service = service
        self.sequenceID = sequenceID
        self.oldTrackID = trackID
        self.clipID = clipID
        self.oldStartTime = oldStartTime
        self.newStartTime = newStartTime
    }
    
    public func execute() throws {
        guard let sequence = service.getSequence(id: sequenceID) else { return }
        guard let clip = service.getClip(id: clipID, inTrack: oldTrackID, inSequence: sequenceID) else { return }
        
        let epsilon = 0.001
        let duration = clip.duration
        
        // Find a suitable track (Auto-Overlay)
        var targetTrackID = oldTrackID
        
        guard let oldTrack = sequence.tracks.first(where: { $0.id == oldTrackID }) else { return }
        let trackType = oldTrack.type
        
        let compatibleTracks = sequence.tracks.filter { $0.type == trackType }
        var foundTrack = false
        
        for track in compatibleTracks {
            let overlaps = track.clips.contains { other in
                other.id != clipID &&
                !(newStartTime + duration <= other.timelineStart + epsilon || newStartTime >= other.timelineStart + other.duration - epsilon)
            }
            if !overlaps {
                targetTrackID = track.id
                foundTrack = true
                break
            }
        }
        
        if !foundTrack {
            let typeName = trackType == .video ? "Video" : "Audio"
            let newTrack = Track(name: "\(typeName) \(compatibleTracks.count + 1)", type: trackType)
            service.addTrack(newTrack, toSequence: sequenceID)
            targetTrackID = newTrack.id
        }
        
        self.newTrackID = targetTrackID
        
        try service.moveClip(id: clipID, toTime: newStartTime, fromTrack: oldTrackID, toTrack: targetTrackID, inSequence: sequenceID)
    }
    
    public func undo() {
        guard let newTrackID = newTrackID else { return }
        try? service.moveClip(id: clipID, toTime: oldStartTime, fromTrack: newTrackID, toTrack: oldTrackID, inSequence: sequenceID)
    }
    
    public func redo() throws {
        try execute()
    }
}

public class RemoveClipCommand: Command {
    public let name = "Remove Clip"
    
    private let service: TimelineService
    private let sequenceID: UUID
    private let trackID: UUID
    private let clipID: UUID
    private var removedClip: Clip?
    
    public init(service: TimelineService, sequenceID: UUID, trackID: UUID, clipID: UUID) {
        self.service = service
        self.sequenceID = sequenceID
        self.trackID = trackID
        self.clipID = clipID
    }
    
    public func execute() throws {
        removedClip = service.getClip(id: clipID, inTrack: trackID, inSequence: sequenceID)
        service.removeClip(id: clipID, fromTrack: trackID, inSequence: sequenceID)
    }
    
    public func undo() {
        guard let clip = removedClip else { return }
        try? service.addClip(clip, toTrack: trackID, inSequence: sequenceID)
    }
    
    public func redo() throws {
        try execute()
    }
}

public class TrimClipCommand: Command {
    public let name = "Trim Clip"
    
    private let service: TimelineService
    private let sequenceID: UUID
    private let trackID: UUID
    private let clipID: UUID
    
    private let oldTimelineStart: Double
    private let newTimelineStart: Double
    private let oldSourceStart: Double
    private let newSourceStart: Double
    private let oldDuration: Double
    private let newDuration: Double
    
    public init(service: TimelineService, sequenceID: UUID, trackID: UUID, clipID: UUID, oldTimelineStart: Double, newTimelineStart: Double, oldSourceStart: Double, newSourceStart: Double, oldDuration: Double, newDuration: Double) {
        self.service = service
        self.sequenceID = sequenceID
        self.trackID = trackID
        self.clipID = clipID
        self.oldTimelineStart = oldTimelineStart
        self.newTimelineStart = newTimelineStart
        self.oldSourceStart = oldSourceStart
        self.newSourceStart = newSourceStart
        self.oldDuration = oldDuration
        self.newDuration = newDuration
    }
    
    public func execute() throws {
        guard var clip = service.getClip(id: clipID, inTrack: trackID, inSequence: sequenceID) else { return }
        clip.timelineStart = newTimelineStart
        clip.sourceStart = newSourceStart
        clip.duration = newDuration
        service.updateClip(clip, inTrack: trackID, inSequence: sequenceID)
    }
    
    public func undo() {
        guard var clip = service.getClip(id: clipID, inTrack: trackID, inSequence: sequenceID) else { return }
        clip.timelineStart = oldTimelineStart
        clip.sourceStart = oldSourceStart
        clip.duration = oldDuration
        service.updateClip(clip, inTrack: trackID, inSequence: sequenceID)
    }
    
    public func redo() throws {
        try execute()
    }
}
