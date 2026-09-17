# Project Structure

```text
VideoEditor/
├── App/
├── Core/
│   ├── Project/
│   ├── Media/
│   ├── Timeline/
│   ├── Playback/
│   ├── Rendering/
│   ├── Export/
│   ├── Cache/
│   └── Commands/
├── Modules/
│   ├── Effects/
│   ├── Transitions/
│   ├── AdvancedSubtitles/
│   ├── ProfessionalColor/
│   ├── AudioPro/
│   └── AdvancedExport/
├── UI/
│   ├── Components/
│   ├── Views/
│   ├── Timeline/
│   ├── Viewer/
│   ├── Inspector/
│   └── DesignSystem/
├── Resources/
├── Tests/
└── docs/
```

## Rules
- Core must not depend on optional modules.
- UI should not directly implement media-processing logic.
- Modules should use public Core interfaces.
- Shared models belong in Core.
- Feature-specific code belongs in its module.


## Module Directory

The initial implementation can contain the six v1.0 modules:

```text
Modules/
├── Effects/
├── Transitions/
├── AdvancedSubtitles/
├── ProfessionalColor/
├── AudioPro/
└── AdvancedExport/
```

Future modules are added without making them dependencies of Core.
