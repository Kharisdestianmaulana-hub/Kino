# Playback Engine

## 1. Purpose

Provide responsive, frame-accurate preview playback of the current timeline.

## 2. Responsibilities

- Timeline playback
- Scrubbing
- Seeking
- Frame stepping
- Playback speed
- Audio synchronization
- Preview quality
- Viewer state
- Playhead synchronization

## 3. Media Foundation

Use AVFoundation and related Apple media frameworks for supported media playback and timing.

## 4. Playback Model

The playback system evaluates the current timeline state and determines which media should be presented at the current timeline position.

The original source files remain unchanged.

## 5. Viewer States

Support:
- Playing
- Paused
- Seeking
- Scrubbing
- Rendering
- Media unavailable
- Empty timeline

## 6. Performance

The playback engine should prioritize responsiveness.

When full-resolution playback cannot be maintained, the application may reduce preview quality or use generated cache/proxy data without altering source media.

## 7. Frame Accuracy

Editing and frame stepping should use deterministic timeline timing. Internal timing should avoid precision loss that could produce visible edit-boundary errors.

## 8. Audio

Video and audio playback should remain synchronized during normal playback and scrubbing.

## 9. Module Integration

Optional modules may participate in frame evaluation through defined rendering interfaces.

A missing optional module must not prevent unrelated project media from being opened.
