import SwiftUI

struct TestLayout: View {
    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
            ZStack {
                Rectangle().fill(Color.red).frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
    }
}
