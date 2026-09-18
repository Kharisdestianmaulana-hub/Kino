# Testing

## 1. Goal

Maintain a stable editing experience while Core and optional modules evolve independently.

> **Project Status Note:** This testing strategy outlines the target QA architecture for v1.0. As a small, active open-source project, our current automated test coverage (found in `KinoTests` and `KinoUITests`) is basic, and we heavily rely on manual testing for critical paths. We are incrementally building towards this automated ideal.

## 2. Test Layers

### Unit Tests
Test:
- Project models
- Timeline calculations
- Commands
- Serialization
- Media references
- Module metadata
- Export configuration

### Integration Tests
Test:
- Project loading and saving
- Media discovery
- Relinking
- Timeline operations
- Playback integration
- Rendering
- Export
- Module lifecycle

### UI Tests
Test:
- Project creation
- Media import
- Timeline editing
- Playback
- Inspector
- Module Manager
- Export workflow
- Error states

## 3. Critical Scenarios

Every release should verify:
- Create project
- Open project
- Save project
- Import media
- Edit media
- Undo / redo
- Playback
- Export
- Close and reopen project
- Missing media
- Relink media
- Module install
- Module enable / disable
- Module uninstall
- Project with unavailable module

## 4. Compatibility Testing

Test supported macOS versions and supported CPU architectures.

## 5. Regression Testing

Every bug fix should include a regression test when practical.

## 6. Performance Testing

Representative projects should be used to detect:
- Playback regressions
- Timeline slowdowns
- Memory growth
- Export regressions

## 7. Test Data

Use synthetic or appropriately licensed media for automated testing.

Do not place private user media in the repository.
