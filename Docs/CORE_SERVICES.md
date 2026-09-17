# Core Services

## 1. Purpose

Define the main services that make Core a usable standalone editor.

## 2. ProjectService

Responsibilities:
- Create project
- Open project
- Save project
- Close project
- Autosave
- Recovery
- Project migration

## 3. MediaService

Responsibilities:
- Import references
- Scan folders
- Resolve media
- Detect missing media
- Relink media
- Read metadata

## 4. TimelineService

Responsibilities:
- Manage sequences
- Manage tracks
- Manage clips
- Execute editing operations
- Maintain markers and keyframes

## 5. PlaybackService

Responsibilities:
- Play
- Pause
- Scrub
- Seek
- Step frames
- Synchronize audio/video

## 6. RenderService

Responsibilities:
- Evaluate timeline
- Build render operations
- Render preview
- Render cached frames

## 7. ExportService

Responsibilities:
- Validate export
- Evaluate timeline
- Encode output
- Report progress
- Cancel export

## 8. ModuleService

Responsibilities:
- Discover modules
- Install
- Validate
- Enable
- Disable
- Uninstall
- Check compatibility

## 9. CacheService

Responsibilities:
- Generate cache
- Read cache
- Invalidate cache
- Clear cache
- Manage storage limits

## 10. Services Rule

Services should expose clear interfaces and avoid becoming a single global god object.
