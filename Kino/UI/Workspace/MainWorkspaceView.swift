import SwiftUI
import AppKit

enum KinoTextFieldIdentifier {
    static let inspectorNumber = NSUserInterfaceItemIdentifier("KinoInspectorNumberField")
    static let mediaSearch = NSUserInterfaceItemIdentifier("KinoMediaSearchField")
}

final class KinoTextFieldFocusState {
    static var focusedIdentifier: NSUserInterfaceItemIdentifier?
}

public struct MainWorkspaceView: View {
    @EnvironmentObject var workspace: WorkspaceState
    
    public init() {}
    
    @State private var showMediaBrowser = true
    @State private var showInspector = true
    @State private var keyMonitor: Any?
    @FocusState private var isWorkspaceFocused: Bool
    
    public var body: some View {
        ZStack {
            VSplitView {
                // Bagian Atas: Media Browser, Viewer, Inspector
                HSplitView {
                    if showMediaBrowser {
                        MediaBrowserView()
                            .frame(minWidth: 200, idealWidth: 250, maxWidth: 350)
                    }
                    
                    ViewerView()
                        .frame(minWidth: 400, idealWidth: 800, maxWidth: .infinity)
                    
                    if showInspector {
                        InspectorView()
                            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                    }
                }
                .frame(minHeight: 300, idealHeight: 500)
                
                // Bagian Bawah: Timeline Membentang Penuh
                TimelineView()
                    .frame(minHeight: 200, idealHeight: 350, maxHeight: .infinity)
            }
            .focusable()
            .focused($isWorkspaceFocused)
            
            if workspace.isExporting {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                ExportModalView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation { showMediaBrowser.toggle() }
                }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Media Browser")
            }
            
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    if workspace.isSaving {
                        SavingIndicatorView()
                    }
                    
                    Button(action: {
                        workspace.addTextClip()
                    }) {
                        Image(systemName: "textformat")
                        Text("Text")
                    }
                    .keyboardShortcut("t", modifiers: .command)
                    .help("Add Text Clip (Cmd+T)")
                    
                    Button(action: {
                        workspace.startExport()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .help("Export Video")
                    
                    Button(action: {
                        withAnimation { showInspector.toggle() }
                    }) {
                        Image(systemName: "sidebar.right")
                    }
                    .help("Toggle Inspector")
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                isWorkspaceFocused = true
            }
            if keyMonitor == nil {
                keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    handleKeyDown(event)
                }
            }
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        // Jangan bajak Command shortcut seperti Cmd+Z, Cmd+S, dan menu bar app.
        if event.modifierFlags.contains(.command) {
            return event
        }
        
        let chars = event.charactersIgnoringModifiers?.lowercased()
        let firstResponder = NSApp.keyWindow?.firstResponder
        
        if firstResponder is NSTextView {
            if shouldRouteShortcutOutOfFocusedField(chars) {
                NSApp.keyWindow?.makeFirstResponder(nil)
            } else {
                return event
            }
        }
        
        return performWorkspaceShortcut(event, chars: chars)
    }
    
    private func shouldRouteShortcutOutOfFocusedField(_ chars: String?) -> Bool {
        guard let chars, isWorkspaceShortcutCharacter(chars) else { return false }
        
        switch KinoTextFieldFocusState.focusedIdentifier {
        case KinoTextFieldIdentifier.inspectorNumber, KinoTextFieldIdentifier.mediaSearch:
            return true
        default:
            return false
        }
    }
    
    private func isWorkspaceShortcutCharacter(_ chars: String) -> Bool {
        chars == " " || chars == "v" || chars == "b" || chars == "n"
    }
    
    private func performWorkspaceShortcut(_ event: NSEvent, chars: String?) -> NSEvent? {
        switch chars {
        case " ":
            workspace.isPlaying.toggle()
            return nil
        case "v":
            workspace.activeTool = .selection
            return nil
        case "b":
            workspace.activeTool = .blade
            return nil
        case "n":
            // toggle snapping
            return nil
        default:
            if event.keyCode == 51 {
                workspace.deleteSelectedClip()
                return nil
            }
            return event
        }
    }
}

// Komponen Animasi "Saving..."
struct SavingIndicatorView: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Saving" + String(repeating: ".", count: dotCount))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            ProgressView()
                .controlSize(.small)
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}
