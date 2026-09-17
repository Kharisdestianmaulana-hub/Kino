# Project File Format

## 1. Goal

Define the long-term project serialization strategy.

## 2. Format

The project format should be:
- Versioned
- Human-readable where practical
- Codable from Swift
- Migratable
- Resilient to missing optional modules

## 3. Conceptual Structure

```text
Project
├── formatVersion
├── projectID
├── metadata
├── mediaReferences
├── sequences
├── settings
└── moduleData
```

## 4. Media References

Store references rather than source media.

A reference may contain:
- Relative path
- File identity
- Volume identity
- Bookmark/access information
- Last known metadata

## 5. Module Data

Module-specific data must be namespaced by module identifier.

Example:

```text
moduleData
├── effects
├── transitions
└── professionalColor
```

## 6. Missing Modules

If a project contains data for an unavailable module:
- Preserve the raw project data
- Mark the feature unavailable
- Allow the rest of the project to open

## 7. Migration

Every incompatible project format change requires a migration path.

The application should retain the original project until migration succeeds.
