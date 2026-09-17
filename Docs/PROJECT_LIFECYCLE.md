# Project Lifecycle

## 1. Lifecycle

New
→ Configure
→ Open
→ Edit
→ Save
→ Close
→ Reopen

## 2. New Project

User may:
- Create a new folder
- Select an existing folder
- Choose sequence settings

The application should not force users to reorganize existing assets.

## 3. Opening

When opening a project:
1. Validate project format.
2. Load project metadata.
3. Resolve media references.
4. Detect unavailable modules.
5. Restore timeline state.
6. Prepare preview/cache data.

## 4. Saving

Saving should persist:
- Project metadata
- Media references
- Timeline
- Edit decisions
- Sequence settings
- Module-specific project data

It must not copy source media into the project file.

## 5. Autosave

Autosave should create recoverable project state without modifying source media.

## 6. Closing

The application should warn about unsaved changes when required.

## 7. Recovery

After an unexpected shutdown, the application should provide a recovery workflow when recoverable autosave data exists.
