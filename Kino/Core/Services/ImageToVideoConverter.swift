import Foundation
import AVFoundation
import AppKit

public class ImageToVideoConverter {
    public static func convert(imageURL: URL, duration: Double, completion: @escaping (URL?) -> Void) {
        guard let image = NSImage(contentsOf: imageURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(nil)
            return
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        assetWriter.add(writerInput)
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        let mediaInputQueue = DispatchQueue(label: "mediaInputQueue")
        
        writerInput.requestMediaDataWhenReady(on: mediaInputQueue) {
            if writerInput.isReadyForMoreMediaData {
                var pixelBuffer: CVPixelBuffer?
                CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                
                if let buffer = pixelBuffer {
                    CVPixelBufferLockBaseAddress(buffer, [])
                    let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                            width: width,
                                            height: height,
                                            bitsPerComponent: 8,
                                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                            space: CGColorSpaceCreateDeviceRGB(),
                                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
                    
                    context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                    CVPixelBufferUnlockBaseAddress(buffer, [])
                    
                    // Append 1st frame at 0
                    pixelBufferAdaptor.append(buffer, withPresentationTime: .zero)
                    
                    // Append 2nd frame at duration to hold the frame
                    let endTime = CMTime(seconds: duration, preferredTimescale: 600)
                    pixelBufferAdaptor.append(buffer, withPresentationTime: endTime)
                }
                
                writerInput.markAsFinished()
                assetWriter.finishWriting {
                    DispatchQueue.main.async {
                        completion(outputURL)
                    }
                }
            }
        }
    }
}
