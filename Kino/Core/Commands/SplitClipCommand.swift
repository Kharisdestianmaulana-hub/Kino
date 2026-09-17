import Foundation

public class SplitClipCommand: Command {
    public let name = "Split Clip"
    
    private let service: TimelineService
    private let sequenceID: UUID
    private let trackID: UUID
    private let originalClip: Clip
    private let splitTime: Double // Waktu di timeline
    
    private let leftClip: Clip
    private let rightClip: Clip
    
    public init(service: TimelineService, sequenceID: UUID, trackID: UUID, originalClip: Clip, splitTime: Double) {
        self.service = service
        self.sequenceID = sequenceID
        self.trackID = trackID
        self.originalClip = originalClip
        self.splitTime = splitTime
        
        let splitDuration = splitTime - originalClip.timelineStart
        
        self.leftClip = Clip(
            id: UUID(),
            mediaAssetID: originalClip.mediaAssetID,
            timelineStart: originalClip.timelineStart,
            sourceStart: originalClip.sourceStart,
            duration: splitDuration
        )
        
        self.rightClip = Clip(
            id: UUID(),
            mediaAssetID: originalClip.mediaAssetID,
            timelineStart: splitTime,
            sourceStart: originalClip.sourceStart + splitDuration,
            duration: originalClip.duration - splitDuration
        )
    }
    
    public func execute() throws {
        service.removeClip(id: originalClip.id, fromTrack: trackID, inSequence: sequenceID)
        try service.addClip(leftClip, toTrack: trackID, inSequence: sequenceID)
        try service.addClip(rightClip, toTrack: trackID, inSequence: sequenceID)
    }
    
    public func undo() {
        service.removeClip(id: leftClip.id, fromTrack: trackID, inSequence: sequenceID)
        service.removeClip(id: rightClip.id, fromTrack: trackID, inSequence: sequenceID)
        try? service.addClip(originalClip, toTrack: trackID, inSequence: sequenceID)
    }
    
    public func redo() throws {
        try execute()
    }
}
