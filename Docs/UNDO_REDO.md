# Undo & Redo

## 1. Purpose

Protect users from accidental editing changes and provide a predictable editing workflow.

## 2. Core Principle

All reversible editing operations should support Undo.

## 3. Examples

Undoable operations include:
- Move clip
- Trim clip
- Split clip
- Delete clip
- Add track
- Change volume
- Change transform
- Change text
- Add marker
- Change effect settings

## 4. Grouping

Multiple low-level changes caused by one user interaction should appear as one logical Undo action.

## 5. Persistence

Undo history does not need to survive application restart in v1.0 unless explicitly implemented.

Project state itself must always be safely saved.

## 6. Modules

Module actions that modify project state should integrate with the same undo architecture.

## 7. Safety

Undo must never restore a destructive modification to source media because source media is not modified by normal editing operations.
