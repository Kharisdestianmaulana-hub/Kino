# Architecture

## 1. Architecture Goals
- Maintainable
- Modular
- Testable
- Native to macOS
- Compatible with macOS 12+
- Clear separation between UI, media processing, project data, and modules

## 2. High-Level Architecture

App
→ UI Layer
→ Application/Core Layer
→ Media & Timeline Systems
→ Rendering / Export
→ Filesystem
→ Optional Modules

## 3. Core Layers

### Presentation
SwiftUI views, macOS commands, menus, panels, inspectors and user interaction.

### Application
Project orchestration, commands, undo/redo, state management and module coordination.

### Media
Asset discovery, metadata, media references, file watching and relinking.

### Timeline
Sequences, tracks, clips, transitions, markers, timing and edit operations.

### Playback
Timeline-to-preview evaluation and AVFoundation-based playback.

### Rendering
Frame evaluation, compositing, effects and preview rendering.

### Export
Final timeline evaluation and output encoding.

### Storage
Project serialization, autosave, cache and filesystem references.

## 4. Non-Destructive Model
The source asset is immutable from the editor's perspective. Timeline state describes how source media should be interpreted and rendered.

## 5. Module Boundary
Modules must communicate with Core through a defined API instead of directly modifying internal Core state.

## 6. macOS Compatibility
Avoid making APIs introduced after macOS 12 a mandatory architectural dependency.


## 7. Modular Product Roadmap

The architecture supports 14 optional modules. v1.0 targets six modules:
- Effects
- Transitions
- Advanced Subtitles
- Professional Color
- Audio Pro
- Advanced Export

Eight additional modules remain future roadmap items:
- Motion Graphics
- Pro Media / Codecs
- Masking & Tracking
- AI Tools
- Advanced Proxy
- Social Media Presets
- Templates
- Integrations

The Core must not require future modules to function.
