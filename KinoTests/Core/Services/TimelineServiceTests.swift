import XCTest
@testable import Kino

final class TimelineServiceTests: XCTestCase {
    func testAddMoveRemoveClip() throws {
        let projectService = ProjectService()
        _ = projectService.createProject(name: "Test")
        let timelineService = TimelineService(projectService: projectService)
        
        var project = projectService.currentProject!
        var sequence = Sequence(name: "Seq")
        let track = Track(name: "Video", type: .video)
        sequence.tracks.append(track)
        project.sequences.append(sequence)
        projectService.updateCurrentProject(project)
        
        let clip = Clip(mediaAssetID: UUID(), timelineStart: 0, sourceStart: 0, duration: 5)
        
        // Add
        try timelineService.addClip(clip, toTrack: track.id, inSequence: sequence.id)
        XCTAssertEqual(projectService.currentProject?.sequences.first?.tracks.first?.clips.count, 1)
        
        // Move
        try timelineService.moveClip(id: clip.id, toTime: 10.0, inTrack: track.id, inSequence: sequence.id)
        XCTAssertEqual(projectService.currentProject?.sequences.first?.tracks.first?.clips.first?.timelineStart, 10.0)
        
        // Remove
        timelineService.removeClip(id: clip.id, fromTrack: track.id, inSequence: sequence.id)
        XCTAssertEqual(projectService.currentProject?.sequences.first?.tracks.first?.clips.count, 0)
    }
}
