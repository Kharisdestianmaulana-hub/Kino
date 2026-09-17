# Module API

## 1. Purpose

Define the conceptual contract between Core and optional modules.

## 2. Module Contract

A module should expose:
- Metadata
- Version
- Compatibility requirements
- Capabilities
- Lifecycle hooks
- UI contributions where supported
- Commands where supported
- Rendering contributions where supported

## 3. Core Services

Core may expose controlled services for:
- Project access
- Timeline access
- Media references
- Rendering
- Export
- Commands
- Notifications
- Settings
- Cache

## 4. Restrictions

Modules must not:
- Modify source media without explicit user action
- Delete project data
- Access unrelated private Core state
- Bypass module lifecycle rules
- Silently transmit user data

## 5. Versioning

The Module API must have its own compatibility version.

Breaking API changes require a documented migration or compatibility strategy.

## 6. Project Data

Modules may store module-specific project data through a defined extension mechanism.

That data must survive module uninstallation.

## 7. Future Public SDK

A public SDK should not be considered stable until the internal architecture has been validated through the v1.0 modules.
