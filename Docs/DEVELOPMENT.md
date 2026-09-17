# Development

## 1. Requirements

Development requires:
- macOS
- Xcode version compatible with the selected deployment target
- Swift toolchain provided by Xcode

## 2. Project Setup

1. Clone or obtain the repository.
2. Open the Xcode project/workspace.
3. Select the macOS application target.
4. Build the project.
5. Run the application.

## 3. Architecture Rules

- Keep UI logic in the UI layer.
- Keep media processing out of SwiftUI views.
- Keep Core independent from optional modules.
- Use defined interfaces between systems.
- Keep source media immutable.
- Store edit decisions in the project model.

## 4. Development Order

Recommended implementation sequence:

1. App shell
2. Project system
3. Media management
4. Timeline model
5. Timeline UI
6. Playback
7. Basic editing commands
8. Rendering
9. Export
10. Cache
11. Module Manager
12. v1.0 modules

## 5. Debugging

Use Xcode diagnostics for:
- Crashes
- Memory
- Performance
- Concurrency
- Rendering

## 6. Documentation

Architecture-affecting changes should update the relevant documentation before or alongside implementation.

## 7. Local Data

Development-generated cache and temporary data should remain outside the source repository.
