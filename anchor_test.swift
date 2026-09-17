import AppKit

let view = NSView()
view.wantsLayer = true
print(view.layer?.anchorPoint ?? CGPoint.zero)
