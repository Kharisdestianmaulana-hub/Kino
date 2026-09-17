# Accessibility

## 1. Goal

The editor should be usable by as many users as reasonably possible while following native macOS accessibility conventions.

## 2. Keyboard Access

Core editing workflows should be accessible without requiring a mouse.

Important operations must have:
- Menu commands
- Keyboard shortcuts where appropriate
- Focusable controls

## 3. Labels

Interactive controls must have meaningful accessibility labels.

Icons must not be the only source of meaning.

## 4. Visual Information

Do not communicate important state using color alone.

Examples:
- Missing media
- Locked track
- Muted track
- Disabled feature
- Export failure

## 5. Contrast

Text, controls, timeline states and important indicators should maintain appropriate contrast in both Light and Dark Mode.

## 6. Dynamic UI

Panels and controls should remain understandable when system text or accessibility settings require larger presentation.

## 7. Reduced Motion

Respect relevant macOS accessibility preferences where practical.

Non-essential animation should not prevent users from completing editing tasks.

## 8. Focus

Focus states should be visible and predictable.

## 9. Testing

Accessibility should be tested using macOS accessibility tools and representative keyboard-only workflows.
