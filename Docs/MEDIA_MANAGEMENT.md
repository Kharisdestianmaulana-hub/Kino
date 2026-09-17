# Media Management

## 1. Core Principle
Source media belongs to the user.

The editor references source files in the user's chosen project/asset folders instead of copying them into an internal media library.

## 2. Example

```text
My Project/
├── Footage/
├── Audio/
├── Images/
├── Graphics/
├── Exports/
├── Cache/
└── MyProject.project
```

## 3. Source Media
Original media must remain untouched.

The editor may read:
- Video
- Audio
- Images
- Graphics
- Other supported media

## 4. Project References
The project should store enough information to locate and identify assets, including:
- Relative path when available
- File identity / bookmark information where appropriate
- Volume information
- Metadata required for relinking

## 5. Filesystem Changes
The application should detect relevant filesystem changes and update the media browser.

Supported workflows:
- New file
- Removed file
- Renamed file
- Moved file
- Missing file

## 6. Relinking
When an asset cannot be found:
1. Mark it as missing.
2. Preserve its timeline usage.
3. Allow the user to locate the replacement file.
4. Validate the selected file.
5. Restore the reference.

## 7. Cache
Generated thumbnails, waveforms, previews and proxies may be stored in Cache.

Cache may be deleted without deleting source media or project edit decisions.

## 8. Finder Integration
Provide:
- Reveal in Finder
- Open Project Folder
- Import from Finder
- Drag and drop
