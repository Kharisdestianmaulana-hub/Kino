# Product Requirements Document (PRD)

## 1. Product Overview

A lightweight, native macOS video editor built with Swift and SwiftUI. The application uses a filesystem-first, non-destructive editing workflow and a modular feature architecture.

> **Project Status Note:** This PRD outlines the target requirements for the v1.0 release. Kino is currently in active development. While the Core editing workflow is stable and functional, the modular architecture and advanced features described here are still being built.

## 2. Product Principles

- Native macOS experience
- Filesystem-first media management
- Non-destructive editing
- Lightweight Core
- Modular advanced features
- Fast and predictable workflow
- Clear and consistent UI

## 3. Target Platform

- macOS 12 Monterey and newer
- Native Apple Silicon and Intel support where technically feasible

## 4. Core Product

The Core is always installed and cannot be uninstalled. It must provide a complete basic editing workflow without requiring optional modules.

Core areas:
- Project management
- Media browser and import
- Media relinking and missing-media detection
- Timeline editing
- Video and audio tracks
- Playback and scrubbing
- Basic audio
- Basic transform
- Basic color adjustment
- Basic text
- Basic keyframes
- Basic export
- Autosave and recovery
- Cache management
- Native macOS integration
- Keyboard shortcuts

## 5. Media Philosophy

Source media belongs to the user. The application must not create a hidden duplicate media library for source assets.

The project stores references and edit decisions. Original video, audio, image, and graphic files remain in the user's chosen project/asset folders.

Editing is non-destructive: timeline operations never overwrite the original source media.

## 6. Optional Module Roadmap

The product defines 14 optional modules.

### v1.0 — 6 Modules

| # | Module | Release |
|---|---|---|
| 1 | Effects | v1.0 |
| 2 | Transitions | v1.0 |
| 3 | Advanced Subtitles | v1.0 |
| 4 | Professional Color | v1.0 |
| 5 | Audio Pro | v1.0 |
| 6 | Advanced Export | v1.0 |

### Future — 8 Modules

| # | Module | Release |
|---|---|---|
| 7 | Motion Graphics | Future |
| 8 | Pro Media / Codecs | Future |
| 9 | Masking & Tracking | Future |
| 10 | AI Tools | Future |
| 11 | Advanced Proxy | Future |
| 12 | Social Media Presets | Future |
| 13 | Templates | Future |
| 14 | Integrations | Future |

All 14 modules are part of the product roadmap. Only the first 6 are targeted for implementation in v1.0.

## 7. Module Requirements

Optional modules must support:
- Installation
- Validation
- Enable / disable
- Versioning
- Updates
- Compatibility checks
- Uninstallation

Uninstalling a module must never delete source media or project files.

## 8. v1.0 Scope

v1.0 consists of:
- The complete Core
- The module management system
- Six initial optional modules

The architecture must be designed so future modules can be added without restructuring the Core.

## 9. Out of Scope for v1.0

The following are not required to ship in v1.0:
- Motion Graphics module
- Pro Media / Codecs module
- Masking & Tracking module
- AI Tools module
- Advanced Proxy module
- Social Media Presets module
- Templates module
- Integrations module
- Full cloud collaboration
- Mandatory cloud storage
- Full professional compositing suite

## 10. Success Criteria

- A user can complete a basic edit without installing any optional module.
- Source media is not duplicated by the application.
- Projects can detect and recover missing media.
- Modules can be installed, enabled, disabled, updated, and uninstalled.
- Uninstalling a module does not destroy project data.
- The application provides a native macOS workflow.
- The v1.0 architecture can accept future modules without breaking existing projects.
