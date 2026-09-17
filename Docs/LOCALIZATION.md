# Localization

## 1. Goal

The application should be designed so UI text can be localized without restructuring the interface.

## 2. Text

Do not hard-code user-facing strings directly into UI logic when localization is expected.

## 3. Layout

UI should tolerate:
- Longer translations
- Different word lengths
- Different number formats

## 4. v1.0

The initial release may prioritize one primary language while keeping the architecture localization-ready.

## 5. Technical Considerations

Use Apple's localization mechanisms and native text APIs where appropriate.

## 6. User Content

User-created project names, media names and text overlays are not automatically translated.
