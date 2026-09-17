# Error Handling

## 1. Principles

Errors should be:
- Understandable
- Actionable
- Recoverable where possible
- Non-destructive
- Consistent

## 2. Error Categories

### Project Errors
- Cannot open project
- Corrupt project data
- Unsupported project version
- Migration failure

### Media Errors
- Missing file
- Unsupported format
- Permission denied
- File moved
- File renamed
- Media unavailable

### Module Errors
- Installation failed
- Validation failed
- Incompatible module
- Missing dependency
- Module load failure
- Module update failure

### Playback Errors
- Media cannot be decoded
- Playback unavailable
- Rendering failure

### Export Errors
- Encoding failure
- Insufficient disk space
- Permission denied
- Invalid output configuration
- Cancelled export

## 3. Recovery

Where possible:
- Preserve project state.
- Preserve undo history.
- Offer Retry.
- Offer Relink for missing media.
- Offer Reinstall for module failures.
- Offer an alternate output location for export failures.

## 4. Missing Media

Missing media must not automatically remove clips from the timeline.

The application should show the media as offline and provide a Relink workflow.

## 5. Module Failure

If a module fails to load:
1. Keep Core available.
2. Disable the failed module.
3. Preserve project data.
4. Explain the affected features.
5. Offer repair/reinstall where appropriate.

## 6. Logging

Internal logs should contain enough diagnostic information to troubleshoot failures without exposing unnecessary user data.

## 7. User Messages

Avoid exposing raw technical errors as the primary message. Technical details may be available through a disclosure or diagnostic report.
