import SwiftUI
import CoreVideo
import AVFoundation

enum HubTab: String, CaseIterable, Identifiable {
    case projects = "Projects"
    case modules = "Modules"
    case settings = "Settings"
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .projects: return "film"
        case .modules: return "puzzlepiece.extension"
        case .settings: return "gearshape"
        }
    }
}

struct ProjectHubView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var selectedTab: HubTab? = .projects
    @State private var showNewProjectModal = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Logo Header
                HStack(spacing: 12) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .cornerRadius(6)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
                    
                    Text("Kino")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                .padding(.top, 20)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                
                List(HubTab.allCases, selection: $selectedTab) { tab in
                    NavigationLink(
                        destination: Group {
                            switch tab {
                            case .projects:
                                ProjectsTabView(showNewProjectModal: $showNewProjectModal)
                            case .modules:
                                ModulesTabView()
                            case .settings:
                                SettingsTabView()
                            }
                        },
                        tag: tab,
                        selection: $selectedTab
                    ) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .font(.headline)
                            .padding(.vertical, 4)
                    }
                }
                .listStyle(SidebarListStyle())
            }
            .frame(minWidth: 200)
            
            // Default View if none selected
            Text("Select an item")
        }
        .frame(minWidth: 850, idealWidth: 850, maxWidth: .infinity, minHeight: 600, idealHeight: 600, maxHeight: .infinity)
        // Memastikan window bisa di-zoom/diperbesar (native macOS behavior)
        .sheet(isPresented: $showNewProjectModal) {
            NewProjectModalView(isPresented: $showNewProjectModal)
                .environmentObject(workspace)
        }
    }
}

struct ProjectsTabView: View {
    @Binding var showNewProjectModal: Bool
    @EnvironmentObject var workspace: WorkspaceState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Welcome to Kino")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    showNewProjectModal = true
                }) {
                    Label("New Project", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.top, 20)
            
            Text("Recent Projects")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 10)
            
            // Adaptive Grid agar membesar saat window di-zoom
            if workspace.recentProjects.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No recent projects yet.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Button("Create New Project") {
                            showNewProjectModal = true
                        }
                        .padding(.top, 5)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 20)], spacing: 20) {
                        ForEach(workspace.recentProjects) { proj in
                            ProjectCardView(id: proj.id, name: proj.name, lastModified: proj.lastModified)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(.horizontal, 40)
        .onAppear {
            workspace.loadRecentProjects()
        }
    }
}

struct ProjectCardView: View {
    let id: UUID
    let name: String
    let lastModified: Date
    @EnvironmentObject var workspace: WorkspaceState
    @State private var isRenaming = false
    @State private var newName = ""
    @State private var showCorruptAlert = false

    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .windowBackgroundColor))
                
                if let nsImage = NSImage(contentsOf: workspace.projectService.thumbnailURL(for: id)) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                }
            }
            .frame(height: 120)
            
            if isRenaming {
                TextField("Project Name", text: $newName, onCommit: {
                    workspace.renameRecentProject(id: id, newName: newName)
                    isRenaming = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onAppear { newName = name }
            } else {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            Text("Edited \(formatDate(lastModified))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onTapGesture(count: 2) {
            let success = workspace.openRecentProject(id: id)
            if !success {
                showCorruptAlert = true
            }
        }
        .alert(isPresented: $showCorruptAlert) {
            Alert(
                title: Text("Gagal Membuka Project"),
                message: Text("Project lama ini formatnya sudah usang atau file-nya hilang. Silakan klik kanan lalu pilih Delete, kemudian buat New Project baru."),
                dismissButton: .default(Text("OK"))
            )
        }
        .contextMenu {
            Button("Rename") {
                isRenaming = true
            }
            Button("Delete") {
                workspace.deleteRecentProject(id: id)
            }
        }
    }
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ModulesTabView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            Text("Module Manager")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Discover and install optional modules to expand Kino's capabilities.")
                .foregroundColor(.secondary)
            
            Spacer()
            Text("Coming Soon")
                .font(.title3)
            Spacer()
        }
        .padding(40)
    }
}

// MARK: - New Project Modal

enum ProjectOrientation: String, CaseIterable, Identifiable {
    case landscape = "Landscape (16:9)"
    case portrait = "Portrait (9:16)"
    case square = "Square (1:1)"
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .landscape: return "rectangle.ratio.16.to.9"
        case .portrait: return "rectangle.ratio.9.to.16"
        case .square: return "square"
        }
    }
}

enum ProjectResolutionQuality: String, CaseIterable, Identifiable {
    case uhd = "4K (UHD)"
    case fhd = "1080p (FHD)"
    case hd = "720p (HD)"
    var id: String { self.rawValue }
    
    var shortName: String {
        switch self {
        case .uhd: return "4K"
        case .fhd: return "1080p"
        case .hd: return "720p"
        }
    }
}

struct NewProjectModalView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var workspace: WorkspaceState
    
    @State private var projectName: String = "Untitled Project"
    @State private var orientation: ProjectOrientation = .landscape
    @State private var resolution: ProjectResolutionQuality = .fhd
    @State private var fps: Double = 30.0
    
    @State private var recommendedFPS: Double = 30.0
    @State private var recommendedRes: ProjectResolutionQuality = .fhd
    
    @AppStorage("DefaultSaveLocation") private var defaultSaveLocationPath: String = ""
    @AppStorage("DefaultFPS") private var defaultFPS: Double = 30.0
    @AppStorage("DefaultResolution") private var defaultRes: String = "fhd"
    @AppStorage("DefaultCanvasColor") private var defaultCanvasColor: String = "black"
    @State private var selectedLocation: URL?
    
    @State private var bgColor: String = "black"
    
    let fpsOptions: [Double] = [24, 25, 30, 60, 120]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Project")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Form Content
            Form {
                Section {
                    TextField("Project Name", text: $projectName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                Section(header: Text("Video Format").font(.headline).padding(.top, 10)) {
                    // Orientation Segmented Control
                    Picker("Orientation", selection: $orientation) {
                        ForEach(ProjectOrientation.allCases) { ori in
                            Text(ori.rawValue).tag(ori)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 8)
                    
                    // Resolution Dropdown
                    HStack {
                        Picker("Resolution", selection: $resolution) {
                            ForEach(ProjectResolutionQuality.allCases) { res in
                                HStack {
                                    Text(res.rawValue)
                                    if res == recommendedRes {
                                        Text(" (✨ Recommended)")
                                    }
                                }
                                .tag(res)
                            }
                        }
                    }
                    
                    // FPS Dropdown
                    HStack {
                        Picker("Frame Rate", selection: $fps) {
                            ForEach(fpsOptions, id: \.self) { rate in
                                HStack {
                                    Text("\(Int(rate)) fps")
                                    if rate == recommendedFPS {
                                        Text(" (✨ Recommended)")
                                    }
                                }
                                .tag(rate)
                            }
                        }
                        
                        if fps > 60 {
                            Text("⚠️ May cause lag on standard 60Hz displays")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else if resolution == .uhd && fps >= 60 && recommendedRes != .uhd {
                            Text("⚠️ 4K 60fps might be heavy for this Mac")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Picker("Canvas Color", selection: $bgColor) {
                        Text("Black").tag("black")
                        Text("White").tag("white")
                    }
                }
                
                Section(header: Text("Save Location").font(.headline).padding(.top, 10)) {
                    HStack {
                        Text(selectedLocation?.path ?? "Choose Folder...")
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Choose Folder...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.canCreateDirectories = true
                            if panel.runModal() == .OK, let url = panel.url {
                                selectedLocation = url
                                defaultSaveLocationPath = url.path
                            }
                        }
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Footer Actions
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create Project") {
                    createProject()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 500)
        .onAppear {
            scanHardwareAndRecommend()
            
            // Override with defaults from Settings
            fps = defaultFPS
            bgColor = defaultCanvasColor
            if defaultRes == "fhd" { resolution = .fhd }
            else if defaultRes == "uhd" { resolution = .uhd }
            else { resolution = .hd }
            
            if defaultSaveLocationPath.isEmpty {
                selectedLocation = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            } else {
                selectedLocation = URL(fileURLWithPath: defaultSaveLocationPath)
            }
        }
    }
    
    private func scanHardwareAndRecommend() {
        // Simple hardware scan (RAM check)
        let memorySize = ProcessInfo.processInfo.physicalMemory
        let memoryGB = Double(memorySize) / (1024 * 1024 * 1024)
        
        // Cek arsitektur Apple Silicon vs Intel
        var size: Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let machineString = String(cString: machine)
        
        let isAppleSilicon = machineString.hasPrefix("Mac") || machineString.hasPrefix("Apple") || ProcessInfo.processInfo.hostName.contains("Mac") 
        // Note: hw.machine di ARM macOS sering muncul Mac... ini simplifikasi saja
        
        if memoryGB >= 16 {
            // Mac dengan RAM 16GB+
            recommendedRes = .uhd
            recommendedFPS = 60.0
        } else if memoryGB >= 8 && isAppleSilicon {
            // Mac Apple Silicon RAM 8GB (cukup tangguh)
            recommendedRes = .fhd
            recommendedFPS = 60.0
        } else {
            // Intel lama atau RAM kecil
            recommendedRes = .fhd
            recommendedFPS = 30.0
        }
        
        // Apply recommendations by default
        self.resolution = recommendedRes
        self.fps = recommendedFPS
    }
    
    private func createProject() {
        // Kalkulasi ukuran render berdasarkan orientasi dan kualitas
        var baseWidth: Int
        var baseHeight: Int
        
        switch resolution {
        case .uhd:
            baseWidth = 3840
            baseHeight = 2160
        case .fhd:
            baseWidth = 1920
            baseHeight = 1080
        case .hd:
            baseWidth = 1280
            baseHeight = 720
        }
        
        var finalWidth = baseWidth
        var finalHeight = baseHeight
        
        switch orientation {
        case .landscape:
            break // tetapkan
        case .portrait:
            finalWidth = baseHeight
            finalHeight = baseWidth
        case .square:
            finalWidth = baseHeight
            finalHeight = baseHeight
        }
        
        let settings = ProjectSettings(
            frameRate: fps,
            resolutionWidth: finalWidth,
            resolutionHeight: finalHeight,
            backgroundColor: bgColor
        )
        
        guard let loc = selectedLocation else { return }
        workspace.createNewProject(name: projectName, settings: settings, folderURL: loc)
        isPresented = false
    }
}


struct SettingsTabView: View {
    @AppStorage("DefaultSaveLocation") private var defaultSaveLocationPath: String = ""
    @AppStorage("AppTheme") private var appTheme: String = "system"
    @AppStorage("DefaultFPS") private var defaultFPS: Double = 30.0
    @AppStorage("DefaultResolution") private var defaultRes: String = "fhd"
    @AppStorage("DefaultCanvasColor") private var defaultCanvasColor: String = "black"
    @AppStorage("HardwareAcceleration") private var hardwareAcceleration: Bool = true
    
    @State private var cacheSize: String = "Calculating..."
    
    var body: some View {
        Form {
            Section(header: Text("Storage & Locations").font(.headline)) {
                HStack {
                    Text("Default Save Location:")
                    Spacer()
                    Text(defaultSaveLocationPath.isEmpty ? "Documents" : URL(fileURLWithPath: defaultSaveLocationPath).lastPathComponent)
                        .foregroundColor(.secondary)
                    Button("Change...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = true
                        if panel.runModal() == .OK, let url = panel.url {
                            defaultSaveLocationPath = url.path
                        }
                    }
                }
                
                HStack {
                    Text("Thumbnail Cache:")
                    Spacer()
                    Text(cacheSize)
                        .foregroundColor(.secondary)
                    Button("Clear Cache") {
                        clearCache()
                    }
                }
            }
            
            Divider().padding(.vertical)
            
            Section(header: Text("Appearance").font(.headline)) {
                Picker("App Theme", selection: $appTheme) {
                    Text("System Default").tag("system")
                    Text("Light Mode").tag("light")
                    Text("Dark Mode").tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Divider().padding(.vertical)
            
            Section(header: Text("Editor Defaults").font(.headline)) {
                Picker("Default Frame Rate", selection: $defaultFPS) {
                    Text("24 fps").tag(24.0)
                    Text("25 fps").tag(25.0)
                    Text("30 fps").tag(30.0)
                    Text("60 fps").tag(60.0)
                }
                
                Picker("Default Resolution", selection: $defaultRes) {
                    Text("1080p (FHD)").tag("fhd")
                    Text("4K (UHD)").tag("uhd")
                    Text("720p (HD)").tag("hd")
                }
                
                Picker("Default Canvas Color", selection: $defaultCanvasColor) {
                    Text("Black").tag("black")
                    Text("White").tag("white")
                }
                
                Toggle("Hardware Acceleration (Metal)", isOn: $hardwareAcceleration)
                    .help("Utilize Apple Silicon GPU for faster playback and rendering.")
            }
            
            Divider().padding(.vertical)
            
            Section(header: Text("About Kino").font(.headline)) {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "film")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                    Text("Kino")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Version 1.0.0 Alpha")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("© 2026 Studio Kharis. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding()
        .frame(maxWidth: 600)
        .onAppear {
            calculateCacheSize()
        }
    }
    
    private func calculateCacheSize() {
        let fileManager = FileManager.default
        let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let autosaveDir = supportDir.appendingPathComponent("Kino/Autosaves")
        
        var totalSize: Int64 = 0
        if let enumerator = fileManager.enumerator(at: autosaveDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        self.cacheSize = formatter.string(fromByteCount: totalSize)
    }
    
    private func clearCache() {
        let fileManager = FileManager.default
        let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let autosaveDir = supportDir.appendingPathComponent("Kino/Autosaves")
        
        if let enumerator = fileManager.enumerator(at: autosaveDir, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                // Hanya hapus thumbnail dan autosave usang (bukan file .kino)
                if fileURL.pathExtension == "jpg" || fileURL.pathExtension == "kino_autosave" {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }
        calculateCacheSize()
    }
}
