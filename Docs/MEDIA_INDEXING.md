# Media Indexing

## 1. Purpose

Provide fast media browsing while keeping the filesystem as the source of truth.

## 2. Index

The application may maintain a lightweight metadata index containing:
- File path/reference
- File identity
- Metadata
- Thumbnail reference
- Waveform reference
- Last known modification information

## 3. No Media Duplication

The index must not become a duplicate media library.

It stores metadata and references, not original media contents.

## 4. Scanning

Folder scans should be:
- Incremental
- Asynchronous
- Cancellable
- Resumable where practical

## 5. Changes

Detect:
- New media
- Removed media
- Renamed media
- Moved media
- Modified media

## 6. Rebuild

The index must be rebuildable from the filesystem.

If the index is deleted or corrupted, source media and projects must remain safe.
