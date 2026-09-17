import XCTest
@testable import Kino

final class MediaAssetTests: XCTestCase {
    func testMediaAssetCreation() {
        let url = URL(fileURLWithPath: "/Users/test/video.mov")
        let metadata = MediaMetadata(duration: 15.0, hasVideo: true, hasAudio: true)
        let asset = MediaAsset(originalURL: url, metadata: metadata)
        
        XCTAssertEqual(asset.originalURL, url)
        XCTAssertEqual(asset.metadata.duration, 15.0)
    }
}
