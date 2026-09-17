import SwiftUI

struct TestView: View {
    var body: some View {
        ZStack {
            Color.black.onTapGesture { print("Background") }
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 100, height: 100)
                .onTapGesture { print("Foreground") }
        }
        .frame(width: 200, height: 200)
    }
}
