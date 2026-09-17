import SwiftUI

public struct TimelineRulerView: View {
    public let timeScale: CGFloat
    
    public init(timeScale: CGFloat) {
        self.timeScale = timeScale
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Placeholder for track headers width
            Color.clear
                .frame(width: 150)
            
            Divider()
            
            // Ruler
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    Color(NSColor.windowBackgroundColor)
                    
                    // Draw ticks
                    Path { path in
                        let width = geo.size.width
                        let step = timeScale * 5 // Every 5 seconds tick
                        for x in stride(from: 0, to: width, by: step) {
                            path.move(to: CGPoint(x: x, y: 15))
                            path.addLine(to: CGPoint(x: x, y: 24))
                        }
                    }
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                }
            }
            .frame(height: 24)
        }
        .frame(height: 24)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
