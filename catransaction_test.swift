import AppKit

let view = NSView()
view.wantsLayer = true
CATransaction.begin()
CATransaction.setDisableActions(true)
view.layer?.transform = CATransform3DMakeScale(2, 2, 1)
CATransaction.commit()
print("Success")
