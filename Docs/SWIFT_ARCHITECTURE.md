# Swift Architecture

## 1. Goal

Define the native Swift architecture for the macOS video editor.

## 2. Layers

```text
SwiftUI / AppKit
        ↓
Presentation
        ↓
Application Services
        ↓
Core Domain
        ↓
Infrastructure
        ↓
Apple Frameworks / File System
```

## 3. Core Rule

SwiftUI must not own business logic.

Views observe application state and issue commands.

## 4. Domain

The domain contains platform-independent concepts such as:
- Project
- MediaAsset
- Sequence
- Track
- Clip
- Marker
- Keyframe
- Module state

## 5. Application Layer

Coordinates workflows such as:
- Open project
- Save project
- Import media
- Relink media
- Execute editing commands
- Start playback
- Start export

## 6. Infrastructure

Infrastructure integrates with:
- AVFoundation
- AVKit
- Core Media
- Core Video
- Metal
- Core Image
- FileManager
- macOS security-scoped resources

## 7. Dependency Direction

```text
UI → Application → Domain
UI → Core Services
Infrastructure → Domain interfaces
Modules → Public Core APIs
```

Core must not depend on optional modules.
