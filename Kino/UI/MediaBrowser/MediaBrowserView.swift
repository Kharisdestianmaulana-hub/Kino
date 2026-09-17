import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct MediaBrowserView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var searchText = ""
    
    // Layout Grid adaptif
    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 16)]
    
    public var body: some View {
        VStack(spacing: 0) {
            Text("Media Browser")
                .font(.headline)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                KinoSearchTextField(text: $searchText, placeholder: "Search media...")
                    .frame(height: 18)
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            .padding(8)
            
            Divider()
            
            if let project = workspace.project {
                if project.mediaReferences.isEmpty {
                    EmptyStateView(
                        title: "No Media Assets",
                        message: "Import media to get started.",
                        systemImage: "square.grid.2x2",
                        actionTitle: "Import Media"
                    ) {
                        importMedia()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(project.mediaReferences) { asset in
                                MediaGridItemView(asset: asset)
                                    // Membuat media item ini dapat di-drag ke Timeline dengan aman
                                    .onDrag {
                                        let provider = NSItemProvider()
                                        provider.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { completion in
                                            completion(asset.id.uuidString.data(using: .utf8), nil)
                                            return nil
                                        }
                                        provider.suggestedName = asset.originalURL.lastPathComponent
                                        return provider
                                    }
                                    .onTapGesture {
                                        workspace.selection = .mediaAsset(asset.id)
                                    }
                            }
                        }
                        .padding(12)
                    }
                    
                    Divider()
                    Button(action: importMedia) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Import")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func importMedia() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.movie, .audio, .image, .video]
        }
        
        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    do {
                        let asset = try workspace.mediaService.createMediaAsset(from: url)
                        if var project = workspace.project {
                            workspace.mediaService.registerAsset(asset, into: &project)
                            workspace.projectService.updateCurrentProject(project)
                            workspace.refreshState()
                        }
                    } catch {
                        print("Failed to import \(url): \(error)")
                    }
                }
            }
        }
    }
}

struct KinoSearchTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.identifier = KinoTextFieldIdentifier.mediaSearch
        textField.delegate = context.coordinator
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let parent: KinoSearchTextField
        
        init(_ parent: KinoSearchTextField) {
            self.parent = parent
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            KinoTextFieldFocusState.focusedIdentifier = KinoTextFieldIdentifier.mediaSearch
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            if KinoTextFieldFocusState.focusedIdentifier == KinoTextFieldIdentifier.mediaSearch {
                KinoTextFieldFocusState.focusedIdentifier = nil
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) ||
                commandSelector == #selector(NSResponder.insertTab(_:)) ||
                commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                NSApp.keyWindow?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}
