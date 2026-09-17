# Command Architecture

## 1. Purpose

Provide a consistent architecture for user actions, undo/redo and UI integration.

## 2. Command Concept

A command represents one logical user operation.

Examples:
- Split Clip
- Move Clip
- Delete Clip
- Add Track
- Change Volume
- Add Marker

## 3. Command Lifecycle

Create
→ Validate
→ Execute
→ Register Undo
→ Update State
→ Notify UI

## 4. Requirements

Commands should:
- Be deterministic
- Validate their inputs
- Modify Core state through defined interfaces
- Support undo when reversible
- Produce predictable results
- Be testable without SwiftUI

## 5. UI Integration

SwiftUI controls and menus invoke commands rather than directly modifying deep model state.

## 6. Modules

Optional modules may register module-specific commands through the Module API.

## 7. Batch Operations

The architecture should support grouping multiple operations into one logical undo action.

## 8. Future

The command system may later support:
- Command palette
- Macros
- Automation
- Scriptable workflows
