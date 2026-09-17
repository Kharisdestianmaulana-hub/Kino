# Commands

## 1. Purpose

Commands represent user actions in the application and provide a consistent boundary between UI actions and Core operations.

## 2. Command Categories

### Project
- New Project
- Open Project
- Save
- Save As
- Close Project
- Revert
- Import Media

### Editing
- Select
- Move
- Cut
- Split
- Trim
- Ripple Delete
- Delete
- Duplicate
- Copy
- Paste
- Insert
- Overwrite
- Replace

### Timeline
- Add Track
- Delete Track
- Lock Track
- Mute Track
- Solo Track
- Toggle Snapping
- Add Marker
- Remove Marker
- Zoom

### Playback
- Play
- Pause
- Stop
- Seek
- Step Forward
- Step Backward
- Go to Start
- Go to End

### Export
- Start Export
- Cancel Export
- Open Export Location

### Modules
- Install Module
- Enable Module
- Disable Module
- Update Module
- Uninstall Module

## 3. Command Requirements

Commands should:
- Have a stable identifier.
- Be callable from UI controls.
- Be callable from menus.
- Support keyboard shortcuts where appropriate.
- Report failure clearly.
- Integrate with UndoManager when the operation is reversible.

## 4. Separation

SwiftUI views should trigger commands rather than directly manipulating deep Core state.

## 5. Future

Commands may later support:
- Command palette
- Macro workflows
- Automation
- Module-defined commands
