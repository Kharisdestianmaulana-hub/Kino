import Foundation
import AVFoundation

let url = URL(fileURLWithPath: "/Users/riray/Movies/Record/Screen Shot 2026-09-17 at 11.38.57.png")
let asset = AVURLAsset(url: url)
print("Duration: \(asset.duration.seconds)")
print("Video Tracks: \(asset.tracks(withMediaType: .video).count)")
