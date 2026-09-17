# Compatibility

## 1. Supported macOS

The minimum supported version is:

**macOS 12 Monterey**

The application should continue to support newer macOS versions unless a future major release intentionally changes the minimum requirement.

## 2. Architecture

Target:
- Apple Silicon
- Intel Macs where supported by the selected deployment strategy

## 3. API Policy

Core architecture must not depend on APIs introduced after macOS 12.

Newer APIs may be used conditionally when:
- A macOS 12-compatible fallback exists.
- The feature is not required for basic application operation.

## 4. Media Compatibility

Media support depends on Apple framework capabilities and the installed module set.

Core should provide a practical baseline media workflow.

Additional professional codecs and media workflows may be provided by the Pro Media / Codecs module.

## 5. Module Compatibility

Every module should declare:
- Minimum application version
- Maximum tested application version where useful
- Minimum macOS version
- Architecture requirements
- Dependencies

## 6. Project Compatibility

Project files must contain a format version.

When the project format changes, the application should provide migration logic where possible.

Projects should remain readable even when optional modules are unavailable. Module-specific data must not be silently discarded.

## 7. Testing Matrix

At minimum, test:
- macOS 12
- Latest supported macOS
- Apple Silicon
- Intel, if included in the release target

Test major project operations:
- Create
- Open
- Save
- Import
- Edit
- Playback
- Export
- Relink
- Module install/uninstall

## 8. Future Changes

Any decision to raise the minimum macOS version must be documented as a deliberate product/release decision rather than an accidental dependency.
