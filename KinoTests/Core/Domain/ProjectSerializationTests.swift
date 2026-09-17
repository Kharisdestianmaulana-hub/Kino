import XCTest
@testable import Kino

final class ProjectSerializationTests: XCTestCase {
    func testProjectSerializationLossless() throws {
        // Create project
        var project = Project(metadata: ProjectMetadata(name: "Test Project"), settings: ProjectSettings())
        
        // Add Media Reference
        let url = URL(fileURLWithPath: "/Users/fake/Documents/video.mp4")
        let asset = MediaAsset(originalURL: url, metadata: MediaMetadata(duration: 10, hasVideo: true, hasAudio: true))
        project.mediaReferences.append(asset)
        
        // Add Sequence & Track & Clip
        var sequence = Sequence(name: "Main Sequence")
        var track = Track(name: "V1", type: .video)
        let transform = ClipTransform(positionX: 10, positionY: -20, scale: 1.25, rotation: 15, opacity: 0.75)
        let clip = Clip(mediaAssetID: asset.id, timelineStart: 0, sourceStart: 0, duration: 5, transform: transform)
        track.clips.append(clip)
        sequence.tracks.append(track)
        project.sequences.append(sequence)
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(project)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedProject = try decoder.decode(Project.self, from: data)
        
        // Compare
        XCTAssertEqual(decodedProject.id, project.id)
        XCTAssertEqual(decodedProject.metadata.name, "Test Project")
        XCTAssertEqual(decodedProject.mediaReferences.count, 1)
        XCTAssertEqual(decodedProject.mediaReferences.first?.originalURL.path, "/Users/fake/Documents/video.mp4")
        XCTAssertEqual(decodedProject.sequences.count, 1)
        XCTAssertEqual(decodedProject.sequences.first?.tracks.first?.clips.first?.duration, 5)
        XCTAssertEqual(decodedProject.sequences.first?.tracks.first?.clips.first?.transform, transform)
    }
}
