# Technology Stack

## Platform
- macOS 12 Monterey+
- Xcode
- Swift

## UI
- SwiftUI
- AppKit where native macOS functionality requires it

## Media
- AVFoundation
- AVKit where appropriate
- Core Media
- Core Video

## Rendering
- Metal
- Core Image where appropriate

## Filesystem
- FileManager
- Uniform Type Identifiers
- macOS file coordination / security-scoped access where required
- Filesystem event monitoring

## Data
- Project files stored in the user's project folder
- Codable-based project serialization initially
- Avoid making SwiftData a foundational dependency because macOS 12 is supported

## Architecture
- Protocol-oriented boundaries
- Command-based editing operations
- UndoManager integration
- Dependency injection for testability
