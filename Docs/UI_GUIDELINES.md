# UI Guidelines

## 1. Purpose

Define interaction and layout rules for the native macOS video editor.

## 2. Design Principles

- Content first
- Professional and focused
- Minimal visual noise
- Consistent interaction
- Native macOS conventions
- Keyboard-first productivity
- Direct manipulation where appropriate
- Accessible by default

## 3. Main Workspace

The primary editing workspace should provide:

- Media Browser
- Viewer
- Inspector
- Timeline
- Toolbar / editing controls

The layout should prioritize the timeline and viewer while keeping project media and properties accessible.

## 4. Panels

Panels should:
- Have clear titles
- Maintain consistent spacing
- Support resizing where useful
- Preserve user layout preferences where appropriate
- Avoid unnecessary modal dialogs

## 5. Timeline UI

Timeline interactions must make these states visually clear:
- Selected clip
- Active track
- Playhead
- Marker
- Snapping
- Locked track
- Muted track
- Solo track
- Disabled / unavailable media

## 6. Inspector

The Inspector should expose properties relevant to the current selection.

Core properties should remain available without optional modules. Module-specific controls should appear only when the relevant module is installed and enabled.

## 7. Module UI

Installed modules may add:
- Inspector sections
- Effects controls
- Timeline tools
- Export options
- Commands

Module UI must follow the same design system as Core.

## 8. Empty and Error States

Every major area should have a useful empty state and an actionable error state.

Examples:
- No project open
- No media imported
- Missing media
- Module unavailable
- Export failed

## 9. Interaction Rules

- Double-click should follow native macOS expectations.
- Context menus should expose relevant actions.
- Drag and drop should be supported where it improves workflow.
- Destructive actions must be recoverable through Undo when possible.
- Long-running operations must communicate progress.

## 10. Appearance

Support:
- Light Mode
- Dark Mode

Use semantic system colors where possible instead of hard-coded appearance-specific values.

## 11. Accessibility

All interactive controls must have meaningful labels and support keyboard navigation where practical.
