//
//  KinoApp.swift
//  Kino
//
//  Created by Kharis Destian Maulana on 15/09/26.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        UserDefaults.standard.removeObject(forKey: "LastProjectID")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // Intersep saat pengguna klik tombol Quit/Close Window
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let workspace = WorkspaceState.shared
        guard workspace.hasUnsavedChanges else {
            return .terminateNow
        }
        
        let alert = NSAlert()
        alert.messageText = "Do you want to save the changes made to the document?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Don't Save")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // "Save" diklik
            let saved = workspace.saveProject()
            return saved ? .terminateNow : .terminateCancel
        } else if response == .alertSecondButtonReturn {
            // "Cancel" diklik
            return .terminateCancel
        } else {
            // "Don't Save" diklik
            return .terminateNow
        }
    }
    private func applyTheme(_ theme: String) {
        if theme == "dark" {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else if theme == "light" {
            NSApp.appearance = NSAppearance(named: .aqua)
        } else {
            NSApp.appearance = nil
        }
    }
}
@main
struct KinoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var workspace = WorkspaceState.shared
    
    @AppStorage("AppTheme") private var appTheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workspace)
                .preferredColorScheme(appTheme == "dark" ? .dark : (appTheme == "light" ? .light : nil))
                .onAppear {
                    applyTheme(appTheme)
                }
                .onChange(of: appTheme) { newTheme in
                    applyTheme(newTheme)
                }
        }
        .commands {
            CommandGroup(replacing: .saveItem) {
                Button("Open Project...") {
                    workspace.openProject()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save Project...") {
                    workspace.saveProject()
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    workspace.undo()
                }
                .keyboardShortcut("z", modifiers: .command)
                
                Button("Redo") {
                    workspace.redo()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }
            
            CommandMenu("Playback") {
                Button("Play/Pause") {
                    workspace.isPlaying.toggle()
                }
                .keyboardShortcut(.space, modifiers: [])
            }
            
            CommandMenu("Tools") {
                Button("Selection Tool") {
                    workspace.activeTool = .selection
                }
                .keyboardShortcut("v", modifiers: [])
                
                Button("Blade Tool") {
                    workspace.activeTool = .blade
                }
                .keyboardShortcut("b", modifiers: [])
                
                Button("Toggle Snapping") {
                    // Fitur snapping menyusul
                }
                .keyboardShortcut("n", modifiers: [])
            }
        }
    }
    private func applyTheme(_ theme: String) {
        if theme == "dark" {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else if theme == "light" {
            NSApp.appearance = NSAppearance(named: .aqua)
        } else {
            NSApp.appearance = nil
        }
    }
}