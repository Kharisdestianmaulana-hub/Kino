import SwiftUI

struct TestEmptyZStack: View {
    var body: some View {
        ZStack {
            // empty
        }
        .frame(width: 100, height: 100)
        .contentShape(Rectangle())
        .onTapGesture {
            print("Hit")
        }
    }
}
