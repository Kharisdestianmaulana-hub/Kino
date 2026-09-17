# Export Pipeline

## 1. Purpose
Convert the non-destructive project timeline into a final media file.

## 2. Core Export
The Core application should support a practical baseline export without requiring optional modules.

Initial baseline:
- MP4
- H.264 video
- AAC audio
- User-selected resolution
- User-selected FPS
- Bitrate controls

## 3. Pipeline

Project
→ Timeline Evaluation
→ Frame Processing
→ Audio Processing
→ Encoding
→ File Output
→ Completion

## 4. Export Safety
Export must never overwrite source media by default.

## 5. Progress
Provide:
- Current progress
- Estimated state where possible
- Cancel
- Error reporting
- Output location

## 6. Optional Export Module
Advanced codecs, advanced encoding controls and specialized delivery formats may be provided by the Advanced Export module.

## 7. Export Queue
The architecture should allow multiple export jobs even if the first version exposes a simple queue.
