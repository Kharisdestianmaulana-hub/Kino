# Media Pipeline

## 1. Goal

Define the flow from filesystem media to decoded frames/audio.

## 2. Pipeline

```text
Filesystem
   ↓
MediaAsset
   ↓
Metadata Analysis
   ↓
Asset Reader / Decoder
   ↓
Decoded Video / Audio
   ↓
Timeline
   ↓
Renderer / Audio Engine
```

## 3. Import

Import means creating a project reference to media.

It does not mean copying the original media into an internal library.

## 4. Metadata

Collect information such as:
- Duration
- Resolution
- Frame rate
- Audio channels
- Sample rate
- Codec/container information

## 5. Decoding

Use Apple's media frameworks where appropriate.

Decoding should happen asynchronously and should not block the main UI thread.

## 6. Offline Media

If a file becomes unavailable:
- Keep the MediaAsset
- Mark it offline
- Keep clips on the timeline
- Show a clear missing-media state
- Allow relinking

## 7. Cache

Decoded previews, thumbnails and analysis data may be cached.

Cache is disposable and never becomes the source of truth.
