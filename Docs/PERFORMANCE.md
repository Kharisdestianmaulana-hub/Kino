# Performance

## 1. Goals

The editor should remain responsive during normal editing workflows and degrade gracefully when media is too demanding for real-time playback.

## 2. Priorities

1. Timeline interaction responsiveness
2. Viewer responsiveness
3. Scrubbing responsiveness
4. Fast media browsing
5. Efficient background processing
6. Predictable export performance
7. Controlled memory usage

## 3. Performance Strategy

- Use background work for expensive operations.
- Avoid blocking the main UI thread.
- Reuse decoded and generated data where safe.
- Use cache for rebuildable derived data.
- Prefer incremental updates over full timeline recalculation.
- Release resources that are no longer needed.

## 4. Playback

When full-resolution playback cannot be maintained:
- Reduce preview quality.
- Use cached frames where appropriate.
- Allow proxy workflows when available.
- Keep timeline interaction responsive.

## 5. Timeline

Editing commands should update only affected state where practical.

Large timelines must not require unnecessary full-project recalculation for simple operations.

## 6. Media Browser

Thumbnail and waveform generation should run asynchronously.

Large folders should remain navigable without blocking the interface.

## 7. Rendering

Rendering should use appropriate hardware-accelerated Apple frameworks where supported.

## 8. Memory

The application should avoid loading entire media files into memory when streaming or partial access is sufficient.

## 9. Diagnostics

Development builds should provide performance diagnostics for:
- Timeline operations
- Playback
- Rendering
- Media loading
- Export
- Memory usage

## 10. Performance Regression

Major releases should test representative projects to detect regressions before release.
