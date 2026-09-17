# Export Architecture

## 1. Goal

Define the native export flow separately from timeline editing and preview.

## 2. Pipeline

```text
Project
  ↓
Export Settings
  ↓
Timeline Evaluation
  ↓
Render Graph
  ↓
Video / Audio Processing
  ↓
Encoder
  ↓
Container
  ↓
Output File
```

## 3. Core Export

Core should provide a practical baseline export workflow.

The initial baseline may include:
- H.264
- AAC
- Common MP4 output

## 4. Advanced Export Module

Advanced Export may add:
- Additional presets
- More codecs
- More containers
- Professional output controls
- Batch export
- Advanced metadata options

## 5. Safety

Export should never overwrite source media.

Existing output files require explicit overwrite handling.

## 6. Progress

Expose:
- Current phase
- Progress
- Estimated remaining work when reliable
- Cancel action
- Error state

## 7. Background Work

Export must not block the main UI thread.
