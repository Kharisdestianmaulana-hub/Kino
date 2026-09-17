# App Lifecycle

## 1. Startup

On launch:
1. Initialize Core.
2. Load application settings.
3. Initialize module manager.
4. Restore recent projects.
5. Prepare UI.
6. Process pending recovery state if required.

## 2. Project Opening

Project opening should happen asynchronously when possible.

The UI should remain responsive and show progress for expensive operations.

## 3. Background / Foreground

The application should handle macOS application lifecycle events without corrupting project state.

## 4. Termination

Before termination:
- Flush important project state
- Finish or safely stop critical operations
- Persist autosave/recovery information when required

## 5. Unexpected Termination

Recovery information should allow the user to restore recent work without changing source media.

## 6. Multiple Projects

The architecture should allow future support for multiple open projects/documents where the macOS document model makes this appropriate.
