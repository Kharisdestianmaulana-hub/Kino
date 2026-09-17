# Observability & Diagnostics

## 1. Purpose

Provide developers with enough diagnostic information to understand crashes, performance issues and module failures.

## 2. Diagnostics

Potential diagnostic areas:
- Application errors
- Playback failures
- Render failures
- Export failures
- Module failures
- Project migration failures
- Media resolution failures

## 3. Logs

Logs should:
- Be structured
- Include severity
- Include useful context
- Avoid unnecessary user content

## 4. Privacy

Diagnostics must follow PRIVACY.md.

Source media contents should not be included in logs by default.

## 5. Debug Builds

Development builds may expose additional diagnostics such as:
- Timeline timing
- Render timings
- Cache activity
- Module loading
- Memory usage

## 6. User Reports

A future diagnostic report may allow users to share relevant logs when requesting support.
