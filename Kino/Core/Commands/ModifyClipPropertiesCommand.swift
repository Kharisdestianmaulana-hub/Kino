import Foundation

public class ModifyClipPropertiesCommand: Command {
    public let name = "Modify Clip"
    public let requiresPlaybackRebuild = false
    
    private let service: TimelineService
    private let sequenceID: UUID
    private let trackID: UUID
    
    private let oldClip: Clip
    private let newClip: Clip
    
    public init(service: TimelineService, sequenceID: UUID, trackID: UUID, oldClip: Clip, newClip: Clip) {
        self.service = service
        self.sequenceID = sequenceID
        self.trackID = trackID
        self.oldClip = oldClip
        self.newClip = newClip
    }
    
    public func execute() throws {
        // Karena TimelineService saat ini belum memiliki updateClip,
        // kita bisa remove oldClip lalu add newClip di waktu yang sama.
        // Atau kita tambahkan updateClip ke TimelineService.
        // Untuk amannya, kita panggil update.
        service.updateClip(newClip, inTrack: trackID, inSequence: sequenceID)
    }
    
    public func undo() {
        service.updateClip(oldClip, inTrack: trackID, inSequence: sequenceID)
    }
    
    public func redo() throws {
        try execute()
    }
}
