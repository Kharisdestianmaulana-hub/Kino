import XCTest
@testable import Kino

final class ProjectLifecycleTests: XCTestCase {
    func testProjectSaveAndLoad() throws {
        let service = ProjectService()
        let project = service.createProject(name: "Lifecycle Test")
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_project.kino")
        
        // Save
        try service.saveProject(project, to: tempURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
        
        // Load
        let newService = ProjectService()
        try newService.loadProject(from: tempURL)
        
        XCTAssertEqual(newService.currentProject?.id, project.id)
        XCTAssertEqual(newService.currentProject?.metadata.name, "Lifecycle Test")
        
        // Cleanup
        try FileManager.default.removeItem(at: tempURL)
    }
}
