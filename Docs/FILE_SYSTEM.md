# File System Architecture

## 1. Purpose

Define how the application interacts with the user's filesystem.

## 2. Principles

- User owns source files.
- Do not silently copy source media.
- Do not silently move source media.
- Do not overwrite source media during normal editing.
- Make file locations visible and understandable.

## 3. Project Folder

A project may exist inside an existing user-selected folder.

The application should not require a rigid folder structure.

It may offer recommended folders such as:
- Footage
- Audio
- Images
- Graphics
- Exports
- Cache

## 4. References

Use relative paths where appropriate, supplemented by reliable file identity/access information for relinking.

## 5. File Watching

Monitor relevant project/media directories for:
- New files
- Removed files
- Renamed files
- Moved files
- Modification changes

## 6. Finder Integration

Support:
- Reveal in Finder
- Open Project Folder
- Drag and drop
- Import from Finder

## 7. Security

Respect macOS filesystem permissions and sandbox/security-scoped access requirements where applicable.

## 8. Destructive Operations

Operations that can permanently modify or delete user files require explicit user action and clear confirmation.
