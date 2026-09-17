# Cache System

## 1. Purpose

Store temporary derived data that improves performance without becoming a required source of truth.

## 2. Cache Types

- Media thumbnails
- Audio waveforms
- Video preview frames
- Render cache
- Proxy data
- Analysis data

## 3. Principles

Cache is:
- Rebuildable
- Disposable
- Separate from source media
- Separate from essential project data

## 4. Location

The application should provide a predictable cache location and allow the user to change it where technically appropriate.

The project may also have a project-local Cache directory.

## 5. Cache Invalidation

Cache should be invalidated when relevant source properties change, including:
- File identity
- File modification state
- Timeline state
- Effect parameters
- Project settings
- Application/module version where required

## 6. User Controls

Provide:
- Cache size information
- Clear cache
- Clear unused cache
- Cache location
- Rebuild cache when needed

## 7. Safety

Clearing cache must never delete:
- Source media
- Project files
- Exported files
- User-created assets

## 8. Modules

Modules may create their own derived cache data, but it must follow Core cache lifecycle and safety rules.

## 9. Disk Usage

The application should communicate when cache usage becomes unusually large.
