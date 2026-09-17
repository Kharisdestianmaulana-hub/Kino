# Module Runtime

## 1. Goal

Define how optional modules are loaded without compromising Core.

## 2. Lifecycle

```text
Available
   ↓
Download
   ↓
Install
   ↓
Validate
   ↓
Enable
   ↓
Load
   ↓
Use
   ↓
Disable
   ↓
Uninstall
```

## 3. Core Boundary

Core owns the Module Manager.

Modules receive only supported public interfaces.

## 4. Validation

Before activation, validate:
- Module identity
- Version
- API compatibility
- Platform compatibility
- Package integrity
- Required capabilities

## 5. Failure Isolation

If a module fails:
- Core remains usable
- The project remains openable
- Module features become unavailable
- Module-specific project data remains preserved

## 6. Storage

Module binaries and resources should live outside source-media folders.

Uninstalling a module must not remove:
- Source media
- Project files
- User exports
- Module project data

## 7. Security

Only trusted/validated module packages should be activated.

Arbitrary third-party executable code should not be loaded without an explicit security model.

## 8. Public SDK

The internal runtime should be stabilized first.

A public module SDK should be introduced only after real v1.0 modules validate the architecture.
