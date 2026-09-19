import Foundation

public enum ProjectError: Error {
    case notFound
    case invalidFormat
    case saveFailed
}

public struct RecentProject: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public let lastModified: Date
    public var bookmarkData: Data?
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
        self.addOrUpdateRecentProject(project: project)
        return project
    }
    
    public func loadProject(from url: URL) throws -> Project {
        let data = try Data(contentsOf: url)
        do {
            let project = try decoder.decode(Project.self, from: data)
            self.currentProject = project
            UserDefaults.standard.set(project.id.uuidString, forKey: "LastProjectID")
            let bookmark = createBookmark(for: url)
            self.addOrUpdateRecentProject(project: project, bookmarkData: bookmark)
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
            let bookmark = createBookmark(for: url)
            self.addOrUpdateRecentProject(project: proj, bookmarkData: bookmark)
        } catch {
            throw ProjectError.saveFailed
        }
    }
    
    public func updateCurrentProject(_ project: Project) {
        self.currentProject = project
    }
    
    
    public func renameRecentProject(id: UUID, newName: String) {
        var recents = getRecentProjects()
        if let index = recents.firstIndex(where: { $0.id == id }) {
            recents[index].name = newName
            if let data = try? JSONEncoder().encode(recents) {
                UserDefaults.standard.set(data, forKey: "RecentProjects")
            }
        }
        
        // If there's an autosave, we should also rename the project internally
        if let proj = recoverAutosavedProject(for: id) {
            var updated = proj
            updated.metadata.name = newName
            autosaveProject(updated)
        }
    }
    
    public func deleteRecentProject(id: UUID) {
        var recents = getRecentProjects()
        recents.removeAll(where: { $0.id == id })
        if let data = try? JSONEncoder().encode(recents) {
            UserDefaults.standard.set(data, forKey: "RecentProjects")
        }
        
        // Also delete autosave file and thumbnail
        clearAutosave(for: id)
        let thumb = thumbnailURL(for: id)
        try? FileManager.default.removeItem(at: thumb)
    }

    public func createBookmark(for url: URL) -> Data? {
        do {
            return try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            print("Failed to create bookmark: \(error)")
            return nil
        }
    }
    
    public func resolveBookmark(data: Data) -> URL? {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                print("Bookmark is stale")
            }
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }

    public func getRecentProjects() -> [RecentProject] {
        guard let data = UserDefaults.standard.data(forKey: "RecentProjects"),
              let projects = try? decoder.decode([RecentProject].self, from: data) else {
            return []
        }
        return projects
    }
    
    public func addOrUpdateRecentProject(project: Project, bookmarkData: Data? = nil) {
        var recents = getRecentProjects()
        let existingBookmark = recents.first(where: { $0.id == project.id })?.bookmarkData
        recents.removeAll { $0.id == project.id }
        
        let finalBookmark = bookmarkData ?? existingBookmark
        let recent = RecentProject(id: project.id, name: project.metadata.name, lastModified: Date(), bookmarkData: finalBookmark)
        recents.insert(recent, at: 0)
        
        // Keep only top 10
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        
        if let data = try? encoder.encode(recents) {
            UserDefaults.standard.set(data, forKey: "RecentProjects")
        }
    }

    // MARK: - Autosave System
    
    private func autosaveDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Kino").appendingPathComponent("Autosaves")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    public func autosaveProject(_ project: Project) {
        let recents = getRecentProjects()
        if let recent = recents.first(where: { $0.id == project.id }),
           let bookmark = recent.bookmarkData,
           let url = resolveBookmark(data: bookmark) {
            
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try encoder.encode(project)
                try data.write(to: url, options: .atomic)
                addOrUpdateRecentProject(project: project, bookmarkData: bookmark)
                return
            } catch {
                print("Failed to autosave to .kino file: \(error)")
            }
        }
        
        // Fallback to legacy
        let url = autosaveDirectory().appendingPathComponent("\(project.id.uuidString).kino_autosave")
        do {
            let data = try encoder.encode(project)
            try data.write(to: url, options: .atomic)
            addOrUpdateRecentProject(project: project)
        } catch {
            print("Autosave failed: \(error)")
        }
    }
    
    
    public func thumbnailURL(for projectID: UUID) -> URL {
        return autosaveDirectory().appendingPathComponent("\(projectID.uuidString)_thumb.jpg")
    }

    public func hasAutosave(for projectID: UUID) -> Bool {
        let url = autosaveDirectory().appendingPathComponent("\(projectID.uuidString).kino_autosave")
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public func recoverAutosavedProject(for projectID: UUID) -> Project? {
        let recents = getRecentProjects()
        if let recent = recents.first(where: { $0.id == projectID }),
           let bookmark = recent.bookmarkData,
           let url = resolveBookmark(data: bookmark) {
            
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                return try decoder.decode(Project.self, from: data)
            } catch {
                try? "\(error)".write(to: URL(fileURLWithPath: "/tmp/kino_err2.txt"), atomically: true, encoding: .utf8)
            }
        }
        
        let url = autosaveDirectory().appendingPathComponent("\(projectID.uuidString).kino_autosave")
        do {
            let data = try Data(contentsOf: url)
            let project = try decoder.decode(Project.self, from: data)
            return project
        } catch {
            try? "\(error)".write(to: URL(fileURLWithPath: "/tmp/kino_err.txt"), atomically: true, encoding: .utf8)
            return nil
        }
    }
    
    public func clearAutosave(for projectID: UUID) {
        let url = autosaveDirectory().appendingPathComponent("\(projectID.uuidString).kino_autosave")
        try? FileManager.default.removeItem(at: url)
    }
}
