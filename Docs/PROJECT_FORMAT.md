# Project Format

## 1. Purpose
The project file stores editing decisions and project metadata, not copies of source media.

## 2. Concept

Project owns:
- Timeline
- Cuts
- Trims
- Clip placement
- Effects references
- Transitions
- Text
- Keyframes
- Color adjustments
- Audio adjustments
- Sequence settings
- Markers

User owns:
- Source video
- Source audio
- Images
- Graphics

## 3. Example

```json
{
  "project": {
    "name": "My Video",
    "formatVersion": 1
  },
  "media": [
    {
      "id": "asset-001",
      "relativePath": "Footage/camera01.mov"
    }
  ],
  "timeline": {
    "tracks": []
  }
}
```

## 4. Versioning
The project format must include a format version.

Future application versions should provide migration paths when the format changes.

## 5. Missing Modules
A project containing optional module features must remain openable even when the module is unavailable.

Unavailable module data should be preserved rather than silently discarded.
