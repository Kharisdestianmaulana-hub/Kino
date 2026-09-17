import Foundation

public enum ProjectError: Error {
    case notFound
    case invalidFormat
    case saveFailed
}

public class ProjectService {
    public private(set) var currentProject: Project?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {
        encoder.outputFormatting = .prettyPrinted
    }
    
    public func createProject(name: String, settings: ProjectSettings = ProjectSettings()) -> Project {
        let metadata = ProjectMetadata(name: name)
        let project = Project(metadata: metadata, settings: settings)
        self.currentProject = project
        UserDefaults.standard.set(project.id.uuidString, forKey: "LastProjectID")
        return project
    }
    
    public func loadProject(from url: URL) throws -> Project {
        let data = try Data(contentsOf: url)
        do {
            let project = try decoder.decode(Project.self, from: data)
            self.currentProject = project
            UserDefaults.standard.set(project.id.uuidString, forKey: "LastProjectID")
            return project
        } catch {
            throw ProjectError.invalidFormat
        }
    }
    
    public func saveProject(_ project: Project, to url: URL) throws {
        var proj = project
        proj.metadata.modificationDate = Date()
        
        do {
            let data = try encoder.encode(proj)
            try data.write(to: url, options: .atomic)
            self.currentProject = proj
            clearAutosave(for: proj.id) // Hapus autosave setelah save manual sukses
            UserDefaults.standard.set(proj.id.uuidString, forKey: "LastProjectID")
        } catch {
            throw ProjectError.saveFailed
        }
    }
    
    public func updateCurrentProject(_ project: Project) {
        self.currentProject = project
    }
    
    // MARK: - Autosave System
    
    private func autosaveDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Kino").appendingPathComponent("Autosaves")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    public func autosaveProject(_ project: Project) {
        let url = autosaveDirectory().appendingPathComponent("\(project.id.uuidString).kino_autosave")
        do {
            let data = try encoder.encode(project)
            try data.write(to: url, options: .atomic)
            print("Autosaved project to \(url.path)")
        } catch {
            print("Failed to autosave project: \(error)")
        }
    }
    
    public func hasAutosave(for projectID: UUID) -> Bool {
        let url = autosaveDirectory().appendingPathComponent("\(projectID.uuidString).kino_autosave")
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public func recoverAutosavedProject(for projectID: UUID) -> Project? {
        let url = autosaveDirectory().appendingPathComponent("\(projectID.uuidString).kino_autosave")
        do {
            let data = try Data(contentsOf: url)
            let project = try decoder.decode(Project.self, from: data)
            return project
        } catch {
            return nil
        }
    }
    
    public func clearAutosave(for projectID: UUID) {
        let url = autosaveDirectory().appendingPathComponent("\(projectID.uuidString).kino_autosave")
        try? FileManager.default.removeItem(at: url)
    }
}
