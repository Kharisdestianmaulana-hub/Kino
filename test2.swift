import Foundation
import CoreGraphics

let sourceSize = CGSize(width: 2880, height: 1800)
let sourceTransform = CGAffineTransform.identity
let extent = CGRect(origin: .zero, size: sourceSize).applying(sourceTransform)

let renderW: CGFloat = 1920.0
let renderH: CGFloat = 1080.0

let scaleX = renderW / extent.width
let scaleY = renderH / extent.height
let baseScale = min(scaleX, scaleY)

var finalTransform = sourceTransform
finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
finalTransform = finalTransform.concatenating(CGAffineTransform(scaleX: baseScale, y: baseScale))

let scaledWidth = extent.width * baseScale
let scaledHeight = extent.height * baseScale
let offsetX = (renderW - scaledWidth) / 2.0
let offsetY = (renderH - scaledHeight) / 2.0

finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: offsetX, y: offsetY))

print("final: \(finalTransform)")
