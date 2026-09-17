# Module System

## 1. Purpose

Optional functionality is distributed as installable modules so the Core application remains lightweight while the product can grow into a larger editing ecosystem.

## 2. Module Policy

- Core functionality is always installed and cannot be uninstalled.
- Optional modules can be downloaded and installed.
- Optional modules can be enabled or disabled.
- Optional modules can be updated.
- Optional modules can be uninstalled.
- Uninstalling a module must not delete user source media or project files.

## 3. Complete Module Roadmap

| # | Module | v1.0 | Removable |
|---|---|:---:|:---:|
| 1 | Effects | Yes | Yes |
| 2 | Transitions | Yes | Yes |
| 3 | Advanced Subtitles | Yes | Yes |
| 4 | Professional Color | Yes | Yes |
| 5 | Audio Pro | Yes | Yes |
| 6 | Advanced Export | Yes | Yes |
| 7 | Motion Graphics | Future | Yes |
| 8 | Pro Media / Codecs | Future | Yes |
| 9 | Masking & Tracking | Future | Yes |
| 10 | AI Tools | Future | Yes |
| 11 | Advanced Proxy | Future | Yes |
| 12 | Social Media Presets | Future | Yes |
| 13 | Templates | Future | Yes |
| 14 | Integrations | Future | Yes |

**v1.0 target: Core + 6 modules.**

## 4. Module Lifecycle

Available
→ Download
→ Install
→ Validate
→ Enable
→ Load
→ Use
→ Disable
→ Uninstall

## 5. Module Metadata

Each module should define:
- Unique identifier
- Display name
- Version
- Minimum application version
- Minimum macOS version
- Dependencies
- Capabilities
- Installation metadata

## 6. Core Responsibilities

The Core Module Manager provides:
- Discovery
- Download
- Installation
- Validation
- Version checking
- Updates
- Enable / disable state
- Dependency handling
- Removal
- Compatibility checks
- Module settings

## 7. Isolation

Modules must communicate with Core through defined interfaces and must not rely on private Core implementation details.

## 8. Project Compatibility

A project containing features from an unavailable module must remain openable.

Module-specific data must be preserved when a module is disabled or uninstalled. The application should show that the required module is unavailable and allow the user to reinstall it.

## 9. Future Ecosystem

A public module SDK may be introduced after the internal module architecture is stable.
