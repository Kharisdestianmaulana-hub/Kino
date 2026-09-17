import SwiftUI

public struct ExportModalView: View {
    @EnvironmentObject var workspace: WorkspaceState
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Exporting Video...")
                .font(.headline)
            
            ProgressView(value: workspace.exportProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 300)
            
            Text("\(Int(workspace.exportProgress * 100))%")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Cancel") {
                workspace.cancelExport()
            }
        }
        .padding(30)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}
