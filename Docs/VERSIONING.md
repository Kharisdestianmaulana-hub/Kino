# Versioning

## 1. Application Version

Use semantic versioning as the conceptual model:

MAJOR.MINOR.PATCH

Example:
- 1.0.0 — initial stable release
- 1.1.0 — feature release
- 1.1.1 — bug fix release

## 2. Major Version

Increment when there are significant breaking product or project-format changes.

## 3. Minor Version

Increment for backward-compatible features and modules.

## 4. Patch Version

Increment for:
- Bug fixes
- Security fixes
- Small compatibility fixes
- Performance fixes without behavior changes

## 5. Project Format

Project format versioning is independent from application versioning.

A project-format migration must be explicit and testable.

## 6. Modules

Modules have their own versions.

A module update must declare compatibility with the application Core version where necessary.

## 7. Compatibility

The application should avoid breaking existing projects unnecessarily.

When breaking changes are unavoidable, provide migration or a clear compatibility policy.
