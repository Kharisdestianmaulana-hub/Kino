import SwiftUI
import AppKit

public struct InspectorView: View {
    @EnvironmentObject var workspace: WorkspaceState
    
    public var body: some View {
        VStack(spacing: 0) {
            if workspace.selection == .none {
                EmptyStateView(
                    title: "Nothing Selected",
                    message: "Select a clip to inspect its properties.",
                    systemImage: "slider.horizontal.3"
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch workspace.selection {
                        case .project, .sequence, .track:
                            projectProperties
                        case .clip(let clipID):
                            if let clip = findClip(id: clipID) {
                                clipProperties(for: clip)
                            } else {
                                Text("Clip not found")
                                    .foregroundColor(.secondary)
                            }
                        case .mediaAsset(let assetID):
                            if let asset = workspace.project?.mediaReferences.first(where: { $0.id == assetID }) {
                                mediaAssetProperties(for: asset)
                            } else {
                                Text("Media not found")
                                    .foregroundColor(.secondary)
                            }
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private var projectProperties: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Project")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                if let project = workspace.project {
                    InspectorRow(title: "Name", value: project.metadata.name)
                    InspectorRow(title: "Resolution", value: "\(project.settings.resolutionWidth) x \(project.settings.resolutionHeight)")
                    InspectorRow(title: "Frame Rate", value: String(format: "%.2f fps", project.settings.frameRate))
                }
            }
        }
    }
    
    @ViewBuilder
    private func clipProperties(for clip: Clip) -> some View {
        if let seqID = workspace.selectedSequenceID,
           let project = workspace.project,
           let seq = project.sequences.first(where: { $0.id == seqID }),
           let track = seq.tracks.first(where: { $0.clips.contains(where: { $0.id == clip.id }) }) {
            
            ClipInspectorView(clip: clip, sequenceID: seqID, trackID: track.id)
        } else {
            Text("Clip not found")
        }
    }
    
    @ViewBuilder
    private func mediaAssetProperties(for asset: MediaAsset) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Media Asset")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                InspectorRow(title: "Name", value: asset.originalURL.lastPathComponent)
                InspectorRow(title: "Type", value: asset.metadata.isImage ? "Photo" : "Video/Audio")
                
                HStack {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: asset.isMissing ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundColor(asset.isMissing ? .red : .green)
                        Text(asset.isMissing ? "Offline" : "Online")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                if !asset.metadata.isImage && asset.metadata.duration > 0 {
                    let mins = Int(asset.metadata.duration) / 60
                    let secs = Int(asset.metadata.duration) % 60
                    InspectorRow(title: "Duration", value: String(format: "%02d:%02d", mins, secs))
                }
                
                if let w = asset.metadata.resolutionWidth, let h = asset.metadata.resolutionHeight {
                    InspectorRow(title: "Resolution", value: "\(w) × \(h)")
                }
                
                if let fps = asset.metadata.frameRate, fps > 0 {
                    InspectorRow(title: "Frame Rate", value: String(format: "%.2f fps", fps))
                }
                
                if let bytes = asset.metadata.fileSizeBytes {
                    InspectorRow(title: "File Size", value: ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("File Path")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(asset.originalURL.path)
                        .font(.caption2)
                        .lineLimit(3)
                        .truncationMode(.middle)
                        .textSelection(.enabled) // Agar path bisa dicopy oleh user
                }
            }
        }
    }

    private func findClip(id: UUID) -> Clip? {
        guard let project = workspace.project, let seqID = workspace.selectedSequenceID else { return nil }
        guard let seq = project.sequences.first(where: { $0.id == seqID }) else { return nil }
        for track in seq.tracks {
            if let clip = track.clips.first(where: { $0.id == id }) {
                return clip
            }
        }
        return nil
    }
}

// MARK: - Subcomponents

struct ClipInspectorView: View {
    @EnvironmentObject var workspace: WorkspaceState
    let clip: Clip
    let sequenceID: UUID
    let trackID: UUID
    
    @State private var transform: ClipTransform
    @State private var colorAdjustment: ColorAdjustment
    @State private var volume: Float
    @State private var textProperties: TextProperties?
    @State private var isEditing = false
    @State private var editStartClip: Clip? = nil
    
    init(clip: Clip, sequenceID: UUID, trackID: UUID) {
        self.clip = clip
        self.sequenceID = sequenceID
        self.trackID = trackID
        _transform = State(initialValue: clip.transform)
        _colorAdjustment = State(initialValue: clip.colorAdjustment ?? ColorAdjustment())
        _volume = State(initialValue: clip.volume)
        _textProperties = State(initialValue: clip.textProperties)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Clip")
                .font(.headline)
            
            if let _ = textProperties {
                VStack(alignment: .leading, spacing: 16) {
                    InspectorSectionHeader(title: "TEXT")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Text", text: Binding(
                            get: { textProperties?.text ?? "" },
                            set: { 
                                textProperties?.text = $0
                                commitTransform(editing: false)
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: textProperties?.text) { _ in commitTransform(editing: false) }
                        
                        InspectorSearchableFontPicker(
                            title: "Font",
                            selectedFont: Binding(
                                get: { textProperties?.fontName ?? "Helvetica" },
                                set: { 
                                    textProperties?.fontName = $0
                                    commitTransform(editing: false)
                                }
                            ),
                            currentText: textProperties?.text ?? ""
                        )
                        .padding(.vertical, 4)
                        
                        InspectorSliderField(title: "Font Size", value: Binding(
                            get: { textProperties?.fontSize ?? 100 },
                            set: { textProperties?.fontSize = $0 }
                        ), range: 10...500, suffix: "pt", multiplier: 1, onEditingChanged: commitTransform)
                        
                        InspectorColorPickerGroup(
                            hexColor: Binding(
                                get: { textProperties?.colorHex ?? "#FFFFFF" },
                                set: { textProperties?.colorHex = $0 }
                            ),
                            onCommit: { commitTransform(editing: false) }
                        )
                    }
                }
                
                Divider().opacity(0.5)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                InspectorSectionHeader(title: "TRANSFORM")
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Position")
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 4) {
                            InspectorNumberBox(
                                value: $transform.positionX,
                                suffix: "px",
                                prefix: "X",
                                displayMultiplier: 1,
                                decimals: 1,
                                dragStep: 1,
                                onEditingChanged: commitTransform
                            )
                            InspectorNumberBox(
                                value: $transform.positionY,
                                suffix: "px",
                                prefix: "Y",
                                displayMultiplier: 1,
                                decimals: 1,
                                dragStep: 1,
                                onEditingChanged: commitTransform
                            )
                        }
                    }
                    
                    InspectorSliderField(title: "Scale", value: $transform.scale, range: 0.1...3.0, suffix: "%", multiplier: 100, onEditingChanged: commitTransform)
                    InspectorSliderField(title: "Rotation", value: $transform.rotation, range: -180...180, suffix: "°", multiplier: 1, onEditingChanged: commitTransform)
                    InspectorSliderField(title: "Opacity", value: $transform.opacity, range: 0.0...1.0, suffix: "%", multiplier: 100, onEditingChanged: commitTransform)
                }
            }
            
            if textProperties == nil {
                Divider()
                    .opacity(0.5)
                
                VStack(alignment: .leading, spacing: 16) {
                    InspectorSectionHeader(title: "COLOR ADJUSTMENTS")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InspectorSliderField(title: "Brightness", value: $colorAdjustment.brightness, range: -1.0...1.0, suffix: "", multiplier: 1, decimals: 2, onEditingChanged: commitTransform)
                        InspectorSliderField(title: "Contrast", value: $colorAdjustment.contrast, range: 0.0...2.0, suffix: "", multiplier: 1, decimals: 2, onEditingChanged: commitTransform)
                        InspectorSliderField(title: "Saturation", value: $colorAdjustment.saturation, range: 0.0...2.0, suffix: "", multiplier: 1, decimals: 2, onEditingChanged: commitTransform)
                    }
                }
                
                Divider()
                    .opacity(0.5)
                
                VStack(alignment: .leading, spacing: 16) {
                    InspectorSectionHeader(title: "AUDIO")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InspectorSliderField(title: "Volume", value: Binding(
                            get: { Double(volume) },
                            set: { volume = Float($0) }
                        ), range: 0.0...2.0, suffix: "%", multiplier: 100, onEditingChanged: commitTransform)
                    }
                }
            }
        }
        .onChange(of: clip) { newClip in
            if !isEditing {
                transform = newClip.transform
                colorAdjustment = newClip.colorAdjustment ?? ColorAdjustment()
                volume = newClip.volume
                textProperties = newClip.textProperties
            }
        }
        .onChange(of: transform) { newTransform in
            if isEditing {
                var newClip = clip
                newClip.transform = newTransform
                newClip.colorAdjustment = colorAdjustment
                newClip.volume = volume
                newClip.textProperties = textProperties
                workspace.previewUpdateClipProperties(newClip, inTrack: trackID, inSequence: sequenceID)
            }
        }
        .onChange(of: colorAdjustment) { newColor in
            if isEditing {
                var newClip = clip
                newClip.transform = transform
                newClip.colorAdjustment = newColor
                newClip.volume = volume
                newClip.textProperties = textProperties
                workspace.previewUpdateClipProperties(newClip, inTrack: trackID, inSequence: sequenceID)
            }
        }
        .onChange(of: volume) { newVolume in
            if isEditing {
                var newClip = clip
                newClip.transform = transform
                newClip.colorAdjustment = colorAdjustment
                newClip.volume = newVolume
                newClip.textProperties = textProperties
                workspace.previewUpdateClipProperties(newClip, inTrack: trackID, inSequence: sequenceID)
            }
        }
    }
    
    private func commitTransform(editing: Bool) {
        if editing && !isEditing {
            editStartClip = clip
        }
        
        isEditing = editing
        var newClip = clip
        newClip.transform = transform
        newClip.colorAdjustment = colorAdjustment
        newClip.volume = volume
        newClip.textProperties = textProperties
        
        if editing {
            workspace.previewUpdateClipProperties(newClip, inTrack: trackID, inSequence: sequenceID)
        } else {
            let oldClip = editStartClip ?? clip
            let command = ModifyClipPropertiesCommand(
                service: workspace.timelineService,
                sequenceID: sequenceID,
                trackID: trackID,
                oldClip: oldClip,
                newClip: newClip
            )
            workspace.executeClipPropertiesCommand(command)
            editStartClip = nil
        }
    }
}

// MARK: - Reusable UI Controls

struct InspectorSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .kerning(0.5)
    }
}



struct InspectorRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}

struct InspectorValueField: View {
    let title: String
    @Binding var value: Double
    let suffix: String
    var onEditingChanged: (Bool) -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            
            InspectorNumberBox(
                value: $value,
                suffix: suffix,
                displayMultiplier: 1,
                decimals: 1,
                dragStep: 1,
                onEditingChanged: onEditingChanged
            )
        }
    }
}

struct InspectorSliderField: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let suffix: String
    let multiplier: Double
    var decimals: Int = 0
    var customDragStep: Double? = nil
    var onEditingChanged: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                
                InspectorNumberBox(
                    value: $value,
                    suffix: suffix,
                    displayMultiplier: multiplier,
                    decimals: decimals,
                    range: range,
                    dragStep: dragStep,
                    onEditingChanged: onEditingChanged
                )
            }
            
            Slider(value: $value, in: range, onEditingChanged: onEditingChanged)
                .controlSize(.small)
        }
    }
    
    private var dragStep: Double {
        if let custom = customDragStep { return custom }
        switch title {
        case "Scale", "Opacity", "Volume", "Brightness", "Contrast", "Saturation":
            return 0.01
        case "Rotation":
            return 1
        default:
            return 1
        }
    }
}

struct InspectorNumberBox: View {
    @Binding var value: Double
    let suffix: String
    var prefix: String? = nil
    let displayMultiplier: Double
    let decimals: Int
    var range: ClosedRange<Double>? = nil
    let dragStep: Double
    var onEditingChanged: (Bool) -> Void
    
    @State private var text: String = ""
    @State private var isEditing = false
    
    private var formattedExternalValue: String {
        format(value * displayMultiplier)
    }
    
    private var textBinding: Binding<String> {
        Binding(
            get: {
                if isEditing {
                    return text
                }
                return formattedExternalValue
            },
            set: { newValue in
                text = newValue
                if let parsed = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                    value = clamped(parsed / displayMultiplier)
                }
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let prefix = prefix {
                Text(prefix)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 12, alignment: .center)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            InspectorNumberTextField(
                text: textBinding,
                onEditingChanged: handleEditingChanged,
                onSubmit: finishEditing,
                onDragBegan: beginDragEditing,
                onDragChanged: updateDragEditing,
                onDragEnded: finishEditing
            )
            .frame(minWidth: 35, idealWidth: 45, maxWidth: 50)
            
            Text(suffix)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 15, alignment: .leading)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .onChange(of: value) { newValue in
            if !isEditing {
                text = format(newValue * displayMultiplier)
            }
        }
        .onAppear {
            text = formattedExternalValue
        }
    }
    
    private func handleEditingChanged(_ editing: Bool) {
        isEditing = editing
        if editing {
            text = formattedExternalValue
            onEditingChanged(true)
        } else {
            finishEditing()
        }
    }
    
    private func beginDragEditing() {
        if !isEditing {
            isEditing = true
            text = formattedExternalValue
            onEditingChanged(true)
        }
    }
    
    private func updateDragEditing(deltaX: Double) {
        beginDragEditing()
        let nextValue = clamped(value + deltaX * dragStep)
        value = nextValue
        text = format(nextValue * displayMultiplier)
    }
    
    private func finishEditing() {
        guard isEditing else { return }
        
        if let parsed = Double(text.replacingOccurrences(of: ",", with: ".")) {
            value = clamped(parsed / displayMultiplier)
        }
        text = formattedExternalValue
        isEditing = false
        onEditingChanged(false)
        NSApp.keyWindow?.makeFirstResponder(nil)
    }
    
    private func clamped(_ candidate: Double) -> Double {
        guard let range = range else { return candidate }
        return min(max(candidate, range.lowerBound), range.upperBound)
    }
    
    private func format(_ number: Double) -> String {
        if decimals == 0 {
            return String(format: "%.0f", number)
        }
        return String(format: "%.\(decimals)f", number)
    }
}

struct InspectorNumberTextField: NSViewRepresentable {
    @Binding var text: String
    var onEditingChanged: (Bool) -> Void
    var onSubmit: () -> Void
    var onDragBegan: () -> Void
    var onDragChanged: (Double) -> Void
    var onDragEnded: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> InspectorDraggableTextField {
        let textField = InspectorDraggableTextField()
        textField.identifier = KinoTextFieldIdentifier.inspectorNumber
        textField.delegate = context.coordinator
        textField.onDragBegan = onDragBegan
        textField.onDragChanged = onDragChanged
        textField.onDragEnded = onDragEnded
        textField.isBordered = false
        textField.drawsBackground = false
        textField.alignment = .right
        textField.focusRingType = .none
        textField.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        return textField
    }
    
    func updateNSView(_ nsView: InspectorDraggableTextField, context: Context) {
        nsView.onDragBegan = onDragBegan
        nsView.onDragChanged = onDragChanged
        nsView.onDragEnded = onDragEnded
        
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let parent: InspectorNumberTextField
        
        init(_ parent: InspectorNumberTextField) {
            self.parent = parent
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            KinoTextFieldFocusState.focusedIdentifier = KinoTextFieldIdentifier.inspectorNumber
            parent.onEditingChanged(true)
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            if KinoTextFieldFocusState.focusedIdentifier == KinoTextFieldIdentifier.inspectorNumber {
                KinoTextFieldFocusState.focusedIdentifier = nil
            }
            parent.onSubmit()
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) ||
                commandSelector == #selector(NSResponder.insertTab(_:)) ||
                commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}

final class InspectorDraggableTextField: NSTextField {
    var onDragBegan: (() -> Void)?
    var onDragChanged: ((Double) -> Void)?
    var onDragEnded: (() -> Void)?
    
    private let dragThreshold: CGFloat = 2
    private var isScrubbingCursor = false
    
    deinit {
        endCursorScrub()
    }
    
    override func mouseDown(with event: NSEvent) {
        guard let window = window else {
            super.mouseDown(with: event)
            return
        }
        
        let startLocation = event.locationInWindow
        var isDragging = false
        
        while true {
            guard let nextEvent = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else {
                if isDragging {
                    onDragEnded?()
                    endCursorScrub()
                }
                break
            }
            
            switch nextEvent.type {
            case .leftMouseDragged:
                let location = nextEvent.locationInWindow
                let distance = hypot(location.x - startLocation.x, location.y - startLocation.y)
                
                if !isDragging && distance >= dragThreshold {
                    isDragging = true
                    beginCursorScrub()
                    onDragBegan?()
                }
                
                if isDragging {
                    if nextEvent.deltaX != 0 {
                        onDragChanged?(Double(nextEvent.deltaX))
                    }
                }
                
            case .leftMouseUp:
                if isDragging {
                    onDragEnded?()
                    endCursorScrub()
                } else {
                    selectText(nil)
                }
                return
                
            default:
                break
            }
        }
    }
    
    private func beginCursorScrub() {
        guard !isScrubbingCursor else { return }
        isScrubbingCursor = true
        CGAssociateMouseAndMouseCursorPosition(boolean_t(0))
        NSCursor.hide()
    }
    
    private func endCursorScrub() {
        guard isScrubbingCursor else { return }
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
        NSCursor.unhide()
        isScrubbingCursor = false
    }
}

struct InspectorSearchableFontPicker: View {
    let title: String
    @Binding var selectedFont: String
    var currentText: String
    @State private var isPresented = false
    @State private var searchText = ""
    
    private let allFonts = NSFontManager.shared.availableFontFamilies
    
    var filteredFonts: [String] {
        if searchText.isEmpty {
            return allFonts
        } else {
            return allFonts.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: {
                isPresented.toggle()
                searchText = ""
            }) {
                HStack {
                    Text(selectedFont)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
                .frame(maxWidth: 160)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $isPresented, arrowEdge: .trailing) {
                VStack(spacing: 0) {
                    TextField("Search font...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Divider()
                    
                    List(filteredFonts, id: \.self) { font in
                        Button(action: {
                            selectedFont = font
                            isPresented = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(font)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    let previewText = currentText.isEmpty ? "Aa Bb Cc" : currentText
                                    Text(previewText)
                                        .font(.custom(font, size: 16))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                Spacer()
                                if selectedFont == font {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(width: 260, height: 300)
                }
            }
        }
    }
}

struct InspectorColorPickerGroup: View {
    @Binding var hexColor: String
    var onCommit: () -> Void
    
    private let presetColors: [String] = [
        "#FFFFFF", // White
        "#000000", // Black
        "#8E8E93", // Gray
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#34C759", // Green
        "#00C7BE", // Teal
        "#32ADE6", // Cyan
        "#007AFF", // Blue
        "#AF52DE", // Purple
        "#FF2D55"  // Pink
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Color")
                    .frame(width: 80, alignment: .leading)
                
                FullWidthColorWell(color: Binding(
                    get: {
                        if let nsColor = NSColor(hex: hexColor) {
                            return Color(nsColor)
                        }
                        return Color.white
                    },
                    set: { newColor in
                        updateHex(from: newColor)
                    }
                ))
                .frame(height: 24)
            }
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(presetColors, id: \.self) { hex in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor(hex: hex) ?? .white))
                        .frame(height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    hexColor.uppercased() == hex ? Color.accentColor : Color(NSColor.separatorColor).opacity(0.5),
                                    lineWidth: hexColor.uppercased() == hex ? 2.5 : 1
                                )
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hexColor = hex
                            onCommit()
                        }
                }
            }
        }
    }
    
    private func updateHex(from color: Color) {
        guard let nsColor = NSColor(color).usingColorSpace(.deviceRGB) else { return }
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        let hex = String(format: "#%02X%02X%02X", r, g, b)
        hexColor = hex
        onCommit()
    }
}

struct FullWidthColorWell: NSViewRepresentable {
    @Binding var color: Color
    
    func makeNSView(context: Context) -> NSColorWell {
        let well = NSColorWell()
        well.target = context.coordinator
        well.action = #selector(Coordinator.colorChanged(_:))
        return well
    }
    
    func updateNSView(_ nsView: NSColorWell, context: Context) {
        nsView.color = NSColor(color)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: FullWidthColorWell
        init(_ parent: FullWidthColorWell) { self.parent = parent }
        
        @objc func colorChanged(_ sender: NSColorWell) {
            parent.color = Color(sender.color)
        }
    }
}
