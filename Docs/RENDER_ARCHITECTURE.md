# Render Architecture

## 1. Purpose

Define how timeline state becomes preview frames and final output.

## 2. Pipeline

Source Media
→ Asset Decode
→ Timeline Evaluation
→ Clip Processing
→ Module Effects
→ Compositing
→ Color Processing
→ Output Frame

## 3. Separation

Rendering must be independent from SwiftUI presentation.

The same rendering logic should be reusable by:
- Viewer preview
- Render cache
- Export pipeline

## 4. Core Rendering

Core provides the baseline rendering pipeline for:
- Source video
- Transform
- Opacity
- Crop
- Basic color
- Basic compositing

## 5. Module Rendering

Optional modules may add processing nodes through defined rendering interfaces.

## 6. Hardware Acceleration

Use Metal and suitable Apple media frameworks where supported.

## 7. Determinism

Given the same project state, source media and render settings, rendering should produce consistent results within expected codec/framework tolerances.

## 8. Preview vs Final

Preview rendering may use reduced resolution or cached data.

Final export must use the configured output quality and should not depend on low-quality preview settings.
