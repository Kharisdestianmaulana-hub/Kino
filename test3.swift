import AppKit

let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
if let img = NSImage(systemSymbolName: "arrow.turn.up.forward", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
    print("Found symbol")
} else {
    print("No symbol")
}
