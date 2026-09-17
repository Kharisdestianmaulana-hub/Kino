# Timeline Data Structure

## 1. Goal

Define the internal representation of a non-destructive timeline.

## 2. Hierarchy

```text
Project
└── Sequence
    ├── Video Track
    │   ├── Clip
    │   └── Clip
    └── Audio Track
        ├── Clip
        └── Clip
```

## 3. Clip

A clip references a MediaAsset and stores edit decisions.

Conceptually:

```text
Clip
├── id
├── assetID
├── timelineStart
├── sourceStart
├── duration
├── speed
├── transform
├── opacity
├── audio
├── keyframes
└── moduleEffects
```

## 4. Time Representation

Use frame-accurate or rational media timing rather than floating-point seconds as the authoritative edit representation.

## 5. Track Ordering

Track order determines compositing order for video and mixing order for audio.

## 6. Overlap

Overlapping clips are valid.

The renderer determines how overlapping clips are composited.

## 7. Non-Destructive Editing

Trimming changes clip references and timing.

The source MediaAsset remains unchanged.

## 8. Future Extensions

The structure should be able to support:
- Compound clips
- Nested sequences
- Adjustment clips
- Advanced transitions
- Motion graphics
- Masks
