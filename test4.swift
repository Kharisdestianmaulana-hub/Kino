import SwiftUI

struct TestView: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color.blue).frame(width: 100, height: 100)
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 40, height: 40)
                .position(x: -20, y: -20)
                .onHover { print("Hovered \($0)") }
        }
        .frame(width: 100, height: 100)
    }
}
