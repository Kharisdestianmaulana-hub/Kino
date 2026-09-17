import SwiftUI

public struct TrackHeaderView: View {
    public let track: Track
    
    public init(track: Track) {
        self.track = track
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(track.type.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            HStack(spacing: 6) {
                Button(action: {}) { Image(systemName: "eye") }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.secondary)
                    .help("Toggle Visibility")
                
                Button(action: {}) { Image(systemName: "lock") }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.secondary)
                    .help("Lock Track")
            }
        }
        .padding(.horizontal, 8)
        .frame(width: 150, height: 60, alignment: .leading)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
