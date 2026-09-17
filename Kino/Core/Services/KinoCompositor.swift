import AVFoundation
import CoreImage
import Foundation

@objc(KinoCompositor)
public class KinoCompositor: NSObject, AVVideoCompositing {
    public var sourcePixelBufferAttributes: [String : Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
    ]
    
    public var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
    ]
    
    private let renderContextQueue = DispatchQueue(label: "com.kino.compositor.renderContextQueue")
    private let renderingQueue = DispatchQueue(label: "com.kino.compositor.renderingQueue")
    private var renderContext: AVVideoCompositionRenderContext?
    private let ciContext = CIContext(options: [.cacheIntermediates: false])
    
    public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync {
            self.renderContext = newRenderContext
        }
    }
    
    public func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async {
            autoreleasepool {
                guard let renderContext = self.renderContext,
                      let outputBuffer = renderContext.newPixelBuffer() else {
                    request.finish(with: NSError(domain: "KinoCompositor", code: 0, userInfo: nil))
                    return
                }
                
                // TODO: Here we need to blend all source tracks!
                // But wait, the standard AVMutableVideoCompositionLayerInstruction ALREADY handles 
                // transformations and opacity if we don't use a custom compositor!
            }
        }
    }
}
