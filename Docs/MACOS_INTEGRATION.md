# macOS Integration

## 1. Goal

Make the application feel native to macOS rather than like a cross-platform editor.

## 2. Integration Areas

- Native menus
- Keyboard shortcuts
- Finder
- Drag and drop
- Open/save dialogs
- Window management
- Full screen
- Accessibility
- Dark/Light appearance
- Security-scoped file access where required
- System notifications where appropriate

## 3. Finder

Provide:
- Reveal Media in Finder
- Reveal Project in Finder
- Open Project Folder

## 4. Native Controls

Prefer SwiftUI/AppKit controls that behave consistently with macOS conventions.

## 5. File Permissions

Handle permission failures clearly.

Do not silently request broad filesystem access when a narrower permission is sufficient.
