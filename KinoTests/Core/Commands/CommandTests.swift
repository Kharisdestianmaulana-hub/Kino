import XCTest
@testable import Kino

final class CommandTests: XCTestCase {
    func testExecuteUndoRedo() throws {
        let projectService = ProjectService()
        _ = projectService.createProject(name: "Test")
        let timelineService = TimelineService(projectService: projectService)
        
        var project = projectService.currentProject!
        var sequence = Sequence(name: "Seq1")
        let track = Track(name: "Track1", type: .video)
        sequence.tracks.append(track)
        project.sequences.append(sequence)
        projectService.updateCurrentProject(project)
        
        let clip = Clip(mediaAssetID: UUID(), timelineStart: 0, sourceStart: 0, duration: 10)
        let addCmd = AddClipCommand(service: timelineService, sequenceID: sequence.id, trackID: track.id, clip: clip)
        
        let commandManager = CommandManager()
        
        // Execute
        try commandManager.execute(addCmd)
        XCTAssertEqual(projectService.currentProject?.sequences[0].tracks[0].clips.count, 1)
        
        // Undo
        commandManager.undo()
        XCTAssertEqual(projectService.currentProject?.sequences[0].tracks[0].clips.count, 0)
        
        // Redo
        commandManager.redo()
        XCTAssertEqual(projectService.currentProject?.sequences[0].tracks[0].clips.count, 1)
    }
    
    func testModifyClipPropertiesUndoRedo() throws {
        let projectService = ProjectService()
        _ = projectService.createProject(name: "Test")
        let timelineService = TimelineService(projectService: projectService)
        
        var project = projectService.currentProject!
        var sequence = Sequence(name: "Seq1")
        let track = Track(name: "Track1", type: .video)
        sequence.tracks.append(track)
        project.sequences.append(sequence)
        projectService.updateCurrentProject(project)
        
        let originalClip = Clip(mediaAssetID: UUID(), timelineStart: 0, sourceStart: 0, duration: 10)
        try timelineService.addClip(originalClip, toTrack: track.id, inSequence: sequence.id)
        
        var modifiedClip = originalClip
        modifiedClip.transform = ClipTransform(positionX: 24, positionY: -12, scale: 1.5, rotation: 30, opacity: 0.5)
        
        let command = ModifyClipPropertiesCommand(
            service: timelineService,
            sequenceID: sequence.id,
            trackID: track.id,
            oldClip: originalClip,
            newClip: modifiedClip
        )
        let commandManager = CommandManager()
        
        try commandManager.execute(command)
        XCTAssertEqual(projectService.currentProject?.sequences[0].tracks[0].clips[0].transform, modifiedClip.transform)
        
        commandManager.undo()
        XCTAssertEqual(projectService.currentProject?.sequences[0].tracks[0].clips[0].transform, originalClip.transform)
        
        commandManager.redo()
        XCTAssertEqual(projectService.currentProject?.sequences[0].tracks[0].clips[0].transform, modifiedClip.transform)
    }
}
