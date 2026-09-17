import SwiftUI
import AVKit
import AVFoundation
import AppKit

public struct PreviewPresentationState: Equatable {
    public static let identity = PreviewPresentationState()
    
    public var transform: ClipTransform
    
    public init(transform: ClipTransform = ClipTransform()) {
        self.transform = transform
    }
}

// Wrapper untuk mematikan kontrol bawaan macOS agar tidak dobel
struct NativeVideoPlayer: NSViewRepresentable {
    let player: AVPlayer
    
    init(player: AVPlayer) {
        self.player = player
    }
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.videoGravity = .resizeAspect
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }
}

public struct ViewerView: View {
    @EnvironmentObject var workspace: WorkspaceState
    @State private var player = AVPlayer()
    @State private var previewImage: NSImage? = nil
    @State private var localDragTransform: ClipTransform? = nil
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("Viewer").font(.headline)
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            GeometryReader { proxy in
                let canvasRect = canvasRectForViewer(in: proxy.size)
                
                ZStack {
                    Color.black
                        .contentShape(Rectangle())
                        .onTapGesture {
                            workspace.clearSelection()
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                    
                    // Jangan di-destroy saat dragging, agar tidak flicker saat kembali!
                                            ZStack {
                            NativeVideoPlayer(player: player)
                            if workspace.isPlayheadInGap() {
                                Color.black
                            }
                        }
                        .frame(width: canvasRect.width, height: canvasRect.height)
                        .scaleEffect(CGFloat(activePresentationState.transform.scale))
                        .rotationEffect(.degrees(activePresentationState.transform.rotation))
                        .position(
                            x: canvasRect.midX + CGFloat(activePresentationState.transform.positionX),
                            y: canvasRect.midY + CGFloat(activePresentationState.transform.positionY)
                        )
                        .transaction { $0.animation = nil }
                        .allowsHitTesting(false)
                    
                    if let img = previewImage {
                        // Tutupi layar dengan hitam agar video asli yang tertinggal di belakang tidak tembus pandang
                        Color.black
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ViewerTransformOverlay(localDragTransform: $localDragTransform)
                    }
                }
            }
            
            HStack(spacing: 24) {
                Button(action: {
                    workspace.playheadPosition = 0
                    if !workspace.isPlaying { updatePlayer(forceTimeline: true) }
                }) { Image(systemName: "backward.end.fill") }
                    .buttonStyle(PlainButtonStyle())
                
                Button(action: togglePlayback) { 
                    Image(systemName: workspace.isPlaying ? "pause.fill" : "play.fill").font(.title2) 
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) { Image(systemName: "forward.end.fill") }
                    .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .onChange(of: workspace.playheadPosition) { _ in
            workspace.updatePreviewPresentationState()
            if !workspace.isPlaying { updatePlayer(forceTimeline: true) }
        }
        .onChange(of: workspace.selection) { _ in
            workspace.updatePreviewPresentationState()
            if !workspace.isPlaying { updatePlayer(forceTimeline: false) }
        }
        .onChange(of: workspace.isPlaying) { playing in
            if playing {
                updatePlayer(forceTimeline: true)
                player.play()
            } else {
                player.pause()
                updatePlayer(forceTimeline: true)
            }
        }
        // Listener utama: tangkap perubahan item komposisi baru (saat drag selesai)
        .onChange(of: workspace.currentCompositionItem) { item in
            updatePlayer(forceTimeline: true)
            // Hilangkan overlay saat komposisi asli sudah matang
            self.previewImage = nil
        }
        // Pasang item saat viewer pertama kali dimuat di layar
        .onAppear {
            updatePlayer(forceTimeline: true)
        }
        // Menjalankan garis merah secara otomatis saat diputar!
        .onReceive(Timer.publish(every: 1.0/30.0, on: .main, in: .common).autoconnect()) { _ in
            if workspace.isPlaying {
                workspace.playheadPosition += 1.0/30.0
            }
        }
    }
    
    private func togglePlayback() {
        workspace.isPlaying.toggle()
    }
    
    private func canvasRectForViewer(in size: CGSize) -> CGRect {
        guard let settings = workspace.project?.settings,
              settings.resolutionWidth > 0,
              settings.resolutionHeight > 0 else {
            return CGRect(origin: .zero, size: size)
        }
        
        let aspect = CGFloat(settings.resolutionWidth) / CGFloat(settings.resolutionHeight)
        var width = size.width
        var height = width / aspect
        
        if height > size.height {
            height = size.height
            width = height * aspect
        }
        
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }
    
    private var activePresentationState: PreviewPresentationState {
        if let drag = localDragTransform {
            return PreviewPresentationState(transform: drag)
        }
        if case .mediaAsset = workspace.selection {
            return .identity
        }
        return workspace.previewPresentationState
    }
    
    
    private func updatePlayer(forceTimeline: Bool) {
        let isImage = { (url: URL) -> Bool in
            let ext = url.pathExtension.lowercased()
            return ["png", "jpg", "jpeg", "heic", "tiff"].contains(ext)
        }
        
        if !forceTimeline, case .mediaAsset(let assetID) = workspace.selection {
            if let asset = workspace.project?.mediaReferences.first(where: { $0.id == assetID }),
               let bookmark = asset.bookmarkData {
                
                var isStale = false
                guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { return }
                
                _ = url.startAccessingSecurityScopedResource()
                
                if isImage(url) {
                    if let nsImage = NSImage(contentsOf: url) {
                        self.previewImage = nsImage
                        self.player.replaceCurrentItem(with: nil)
                    }
                } else {
                    self.previewImage = nil
                    let currentAssetURL = (player.currentItem?.asset as? AVURLAsset)?.url
                    if currentAssetURL != url {
                        let playerItem = AVPlayerItem(url: url)
                        player.replaceCurrentItem(with: playerItem)
                        if workspace.isPlaying { player.play() }
                    }
                }
            }
            return
        }
        
        // Jika berada di mode timeline, gunakan komposisi utuh dari WorkspaceState!
        self.previewImage = nil
        
        if let compositionItem = workspace.currentCompositionItem {
            if player.currentItem !== compositionItem {
                player.replaceCurrentItem(with: compositionItem)
                if workspace.isPlaying { player.play() }
            }
            
            if !workspace.isPlaying {
                let targetTime = CMTime(seconds: workspace.playheadPosition, preferredTimescale: 600)
                player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        } else {
            player.replaceCurrentItem(with: nil)
        }
    }
    
    private func formatTimecode(_ seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        let frames = Int((seconds.truncatingRemainder(dividingBy: 1)) * 60)
        return String(format: "%02d:%02d:%02d:%02d", hrs, mins, secs, frames)
    }
}

private struct ViewerTransformOverlay: View {
    @Binding var localDragTransform: ClipTransform?
    @EnvironmentObject var workspace: WorkspaceState
    @State private var interaction: ViewerTransformInteraction?
    @State private var currentDragTransform: ClipTransform?
    @State private var lastPreviewTransform: ClipTransform?
    @State private var lastPreviewTimestamp: CFTimeInterval = 0
    
    private let handleSize: CGFloat = 11
    private let rotateHandleSize: CGFloat = 30
    private let previewMinimumInterval: CFTimeInterval = 1.0 / 45.0
    
    var body: some View {
        GeometryReader { proxy in
            if let context = workspace.activeVideoClipContext(at: workspace.playheadPosition),
               let canvasRect = canvasRect(in: proxy.size) {
                let transform = localDragTransform ?? workspace.previewPresentationState.transform
                let isSelected = workspace.selection == .clip(context.clip.id)
                let _ = print("[DEBUG Overlay] Context clip: \(context.clip.id), Selection: \(workspace.selection), isSelected: \(isSelected)")
                
                ZStack {
                    selectionSurface(context: context, transform: transform, rect: canvasRect, isSelected: isSelected)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
    
        private func getMediaSize(for context: ActiveVideoClipContext, inside rect: CGRect) -> CGSize {
        // Use the project render size (same as KinoVideoCompositor) to match the actual rendered frame
        guard let settings = workspace.project?.settings,
              settings.resolutionWidth > 0,
              settings.resolutionHeight > 0 else {
            return rect.size
        }
        
        let resW = CGFloat(settings.resolutionWidth)
        let resH = CGFloat(settings.resolutionHeight)
        let scaleX = rect.width / resW
        let scaleY = rect.height / resH
        let baseScale = min(scaleX, scaleY)
        
        return CGSize(width: resW * baseScale, height: resH * baseScale)
    }
    
    @ViewBuilder
    private func selectionSurface(
        context: ActiveVideoClipContext,
        transform: ClipTransform,
        rect: CGRect,
        isSelected: Bool
    ) -> some View {
        let mediaSize = getMediaSize(for: context, inside: rect)
        let scaledWidth = mediaSize.width * CGFloat(transform.scale)
        let scaledHeight = mediaSize.height * CGFloat(transform.scale)
        
        ZStack {
            // Hitbox area untuk frame video yang mengikuti skala
            Rectangle()
                .fill(Color.white.opacity(0.01))
                .frame(width: scaledWidth, height: scaledHeight)
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture().onEnded {
                        workspace.selectClip(id: context.clip.id)
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                )
            
            if isSelected {
                Rectangle()
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: scaledWidth, height: scaledHeight)
                    .shadow(color: .black.opacity(0.65), radius: 1, x: 0, y: 0)
                
                ForEach(ViewerTransformCorner.allCases) { corner in
                    scaleHandle(corner: corner, context: context, rect: rect, scale: transform.scale)
                }
            }
        }
        .rotationEffect(.degrees(transform.rotation))
        .position(
            x: rect.midX + CGFloat(transform.positionX),
            y: rect.midY + CGFloat(transform.positionY)
        )
        .transaction { transaction in
            transaction.animation = nil
        }
    }
    
    private func scaleHandleOffset(for corner: ViewerTransformCorner, context: ActiveVideoClipContext, rect: CGRect, scale: Double) -> CGSize {
        let mediaSize = getMediaSize(for: context, inside: rect)
        return CGSize(
            width: (mediaSize.width / 2 * CGFloat(scale)) * corner.xSign,
            height: (mediaSize.height / 2 * CGFloat(scale)) * corner.ySign
        )
    }

    private func scaleHandle(corner: ViewerTransformCorner, context: ActiveVideoClipContext, rect: CGRect, scale: Double) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .overlay(Circle().stroke(Color.black.opacity(0.55), lineWidth: 0.5))
            .offset(scaleHandleOffset(for: corner, context: context, rect: rect, scale: scale))
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if interaction == nil {
                            beginInteractionIfNeeded(.scale(corner), context: context, transform: workspace.previewPresentationState.transform)
                        }
                        updateScale(with: value.translation, corner: corner, context: context, rect: rect)
                    }
                    .onEnded { _ in
                        commitInteraction(context: context)
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
    

    
    private func beginInteractionIfNeeded(
        _ kind: ViewerTransformInteraction.Kind,
        context: ActiveVideoClipContext,
        transform: ClipTransform
    ) {
        guard interaction == nil else { return }
        interaction = ViewerTransformInteraction(kind: kind, oldClip: context.clip, startTransform: transform)
        workspace.selectClip(id: context.clip.id)
    }
    
    private func updateScale(
        with translation: CGSize,
        corner: ViewerTransformCorner,
        context: ActiveVideoClipContext,
        rect: CGRect
    ) {
        guard let interaction else { return }
        
        let vector = transformedUnitVector(for: corner, rotation: interaction.startTransform.rotation)
        let projectedDistance = translation.width * vector.dx + translation.height * vector.dy
                let mediaSize = getMediaSize(for: context, inside: rect)
        let halfDiagonal = max(1, hypot(mediaSize.width, mediaSize.height) / 2)
        let nextScale = max(0.05, interaction.startTransform.scale + Double(projectedDistance / halfDiagonal))
        
        var nextTransform = interaction.startTransform
        nextTransform.scale = nextScale
        preview(context: context, transform: nextTransform)
    }
    

    private func preview(context: ActiveVideoClipContext, transform: ClipTransform) {
        currentDragTransform = transform
        localDragTransform = transform
    }
    
    private func commitInteraction(context: ActiveVideoClipContext) {
        guard let interaction else { return }
        
        var newClip = context.clip
        let finalTransform = currentDragTransform ?? workspace.previewPresentationState.transform
        newClip.transform = finalTransform
        
        let command = ModifyClipPropertiesCommand(
            service: workspace.timelineService,
            sequenceID: context.sequenceID,
            trackID: context.trackID,
            oldClip: interaction.oldClip,
            newClip: newClip
        )
        workspace.executeClipPropertiesCommand(command)
        currentDragTransform = nil
        lastPreviewTransform = nil
        lastPreviewTimestamp = 0
        localDragTransform = nil
        self.interaction = nil
    }
    
    private func canvasRect(in size: CGSize) -> CGRect? {
        guard let settings = workspace.project?.settings,
              settings.resolutionWidth > 0,
              settings.resolutionHeight > 0 else {
            return nil
        }
        
        let aspect = CGFloat(settings.resolutionWidth) / CGFloat(settings.resolutionHeight)
        var width = size.width
        var height = width / aspect
        
        if height > size.height {
            height = size.height
            width = height * aspect
        }
        
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }
    
    private func transformedUnitVector(for corner: ViewerTransformCorner, rotation: Double) -> CGVector {
        let length = sqrt(corner.xSign * corner.xSign + corner.ySign * corner.ySign)
        let x = corner.xSign / length
        let y = corner.ySign / length
        let radians = CGFloat(rotation) * .pi / 180
        let cosValue = cos(radians)
        let sinValue = sin(radians)
        
        return CGVector(
            dx: x * cosValue - y * sinValue,
            dy: x * sinValue + y * cosValue
        )
    }
}

private extension ClipTransform {
    func isVisuallyClose(to other: ClipTransform) -> Bool {
        abs(scale - other.scale) < 0.003 &&
        abs(rotation - other.rotation) < 0.15 &&
        abs(positionX - other.positionX) < 0.25 &&
        abs(positionY - other.positionY) < 0.25 &&
        abs(opacity - other.opacity) < 0.003
    }
}

private struct ViewerTransformInteraction {
    enum Kind: Equatable {
        case scale(ViewerTransformCorner)
    }
    
    let kind: Kind
    let oldClip: Clip
    let startTransform: ClipTransform
}

private enum ViewerTransformCorner: CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
    
    var id: Self { self }
    
    var xSign: CGFloat {
        switch self {
        case .topLeft, .bottomLeft:
            return -1
        case .topRight, .bottomRight:
            return 1
        }
    }
    
    var ySign: CGFloat {
        switch self {
        case .topLeft, .topRight:
            return -1
        case .bottomLeft, .bottomRight:
            return 1
        }
    }
}

private final class ViewerRotateCursor {
    static let shared = NSCursor(image: ViewerRotateCursor.makeImage(), hotSpot: NSPoint(x: 9, y: 9))
    
    private static func makeImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: image.size).fill()
        
        let path = NSBezierPath()
        path.lineWidth = 1.8
        path.lineCapStyle = .round
        path.appendArc(
            withCenter: NSPoint(x: 9, y: 9),
            radius: 5.5,
            startAngle: 35,
            endAngle: 315,
            clockwise: true
        )
        NSColor.white.setStroke()
        path.stroke()
        
        let arrow = NSBezierPath()
        arrow.move(to: NSPoint(x: 14.5, y: 6.5))
        arrow.line(to: NSPoint(x: 16.5, y: 2.5))
        arrow.line(to: NSPoint(x: 12.2, y: 3.2))
        arrow.close()
        NSColor.white.setFill()
        arrow.fill()
        
        NSColor.black.withAlphaComponent(0.75).setStroke()
        path.lineWidth = 0.6
        path.stroke()
        
        image.unlockFocus()
        return image
    }
}

