# Release Process

## 1. Release Stages

Development
→ Internal Testing
→ Release Candidate
→ Stable Release

## 2. Pre-Release Checklist

- Build succeeds
- Unit tests pass
- Integration tests pass
- UI tests pass where applicable
- Supported macOS versions tested
- Critical editing workflows tested
- Export tested
- Module lifecycle tested
- Project migration tested
- No known critical data-loss bugs

## 3. Release Candidate

A release candidate should remain stable long enough for focused regression testing.

## 4. Stable Release

A stable release should include:
- Application version
- Release notes
- Updated changelog
- Known issues where relevant
- Module compatibility information

## 5. Module Releases

Modules may be released independently when the module system supports it.

A module release must not silently invalidate existing projects.

## 6. Rollback

Release infrastructure should provide a recovery path when an application or module update fails.

## 7. Post-Release

Monitor:
- Crash reports
- Critical bugs
- Export failures
- Module installation failures
- Compatibility issues

Use findings to prioritize the next patch or feature release.
