import XCTest
@testable import Kino

final class MediaServiceTests: XCTestCase {
    func testCreateAndRegisterAssetDoesNotCopy() throws {
        let service = MediaService()
        let url = URL(fileURLWithPath: "/tmp/fake_source_video.mp4")
        
        // Create an asset reference
        let asset = try service.createMediaAsset(from: url)
        
        // Verify it points to the exact same URL (no internal bundle path)
        XCTAssertEqual(asset.originalURL.path, "/tmp/fake_source_video.mp4")
        
        let projectService = ProjectService()
        var project = projectService.createProject(name: "Test")
        
        // Register it
        service.registerAsset(asset, into: &project)
        
        XCTAssertEqual(project.mediaReferences.count, 1)
        XCTAssertEqual(project.mediaReferences.first?.originalURL.path, "/tmp/fake_source_video.mp4")
    }
}
