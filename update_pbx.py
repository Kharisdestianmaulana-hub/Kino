import sys
from pbxproj import XcodeProject

project_path = "Kino.xcodeproj/project.pbxproj"
project = XcodeProject.load(project_path)

# Ensure Kino target
target = project.get_target_by_name("Kino")

project.add_file("Kino/Core/Services/PlaybackEngine.swift", force=False)
project.add_file("Kino/Core/Commands/SplitClipCommand.swift", force=False)

project.save()
print("Files added successfully.")
