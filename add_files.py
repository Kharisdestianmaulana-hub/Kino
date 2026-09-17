from pbxproj import XcodeProject
import os

project_path = "Kino.xcodeproj/project.pbxproj"
project = XcodeProject.load(project_path)

files_to_add = [
    "Kino/Core/Commands/ModifyClipPropertiesCommand.swift",
    "Kino/Core/Services/ExportService.swift",
    "Kino/UI/Workspace/ExportModalView.swift"
]

for file_path in files_to_add:
    if os.path.exists(file_path):
        project.add_file(file_path, force=False)
        print(f"Added {file_path}")
    else:
        print(f"File not found: {file_path}")

project.save()
print("pbxproj updated successfully.")
