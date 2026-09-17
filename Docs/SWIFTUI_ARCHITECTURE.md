# SwiftUI Architecture

## 1. Goal

Define how SwiftUI is used without allowing UI concerns to leak into the editing engine.

## 2. Main Workspace

The application workspace may contain:

```text
Navigation / Project Browser
        │
Media Browser ─ Viewer ─ Inspector
        │
      Timeline
        │
      Status Bar
```

## 3. View Responsibilities

Views should:
- Display state
- Receive user interaction
- Dispatch commands
- Present errors and progress

Views should not:
- Directly manipulate timeline internals
- Perform media decoding
- Perform rendering
- Perform export encoding

## 4. State

Use observable application state for UI-facing state.

Long-lived domain state belongs to Core services/models.

## 5. AppKit

AppKit may be used where it provides better native behavior, including:
- Advanced window management
- Menu integration
- Keyboard event handling
- Specialized timeline/viewer interaction
- Finder/macOS integration

## 6. Performance

Avoid putting high-frequency playback or timeline rendering state into unnecessarily broad SwiftUI view hierarchies.

Use targeted state updates.
