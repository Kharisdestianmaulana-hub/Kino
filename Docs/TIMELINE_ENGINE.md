# Timeline Engine

## 1. Responsibilities
- Tracks
- Clips
- Timing
- Selection
- Editing commands
- Snapping
- Markers
- Keyframes
- Track state
- Sequence settings

## 2. Editing Model
Timeline operations are non-destructive.

Operations modify project state, not source files.

## 3. Core Operations
- Select
- Move
- Cut
- Split
- Trim
- Ripple delete
- Delete
- Duplicate
- Copy
- Paste
- Insert
- Overwrite
- Replace

## 4. Time Representation
Use frame-accurate internal timing. Avoid floating-point time calculations where precision could affect edit boundaries.

## 5. Undo / Redo
Editing commands should integrate with the native macOS UndoManager where appropriate.

## 6. Snapping
Snapping should support:
- Clip edges
- Playhead
- Markers
- Track boundaries
- Sequence start/end
