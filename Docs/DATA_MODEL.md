# Data Model

## 1. Purpose

Define the core entities used by the project, media, timeline and module systems.

## 2. Core Entities

### Project
Represents the editable project and stores:
- Project metadata
- Project format version
- Media references
- Sequences
- Timeline state
- Project settings
- Module-specific data

### Media Asset
Represents a source file owned by the user.

Stores:
- Stable asset ID
- Relative path when available
- File identity/reference information
- Media metadata
- Offline state

### Sequence
Represents an editable timeline.

Stores:
- Resolution
- Frame rate
- Duration
- Tracks
- Sequence settings

### Track
Represents a video or audio layer.

Stores:
- Track ID
- Track type
- Order
- Lock state
- Mute state
- Solo state

### Clip
Represents a non-destructive use of a media asset on a timeline.

Stores:
- Clip ID
- Source asset ID
- Source in/out
- Timeline position
- Duration
- Transform
- Audio properties
- Effects references
- Keyframes

### Marker
Represents a timeline annotation.

### Module State
Represents installed/enabled module information required by a project.

## 3. Source of Truth

Source media is not stored inside the project data.

The project is the source of truth for editing decisions.

The filesystem is the source of truth for source media.

## 4. IDs

Entities should use stable identifiers rather than relying only on filenames or array indexes.

## 5. Serialization

The model must support versioned serialization and migration.
