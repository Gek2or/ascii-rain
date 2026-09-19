# v0.9.1 — ZIP import packaging repair

This is the SAME Mobile Clarity v0.9.1 game, not a new gameplay version.
All 120 original files, including game code and assets, are preserved byte-for-byte.
Only this note and tools/package_project.py have been added.

## Cause
The old ZIP contained 120 file entries but zero directory entries.
Godot ProjectDialog extracts entries sequentially: it creates a directory for a
directory entry, but does not create missing parent folders when writing a file.
A reproduction of that strategy failed on 114 nested files: the same 16 initial
paths and "And 98 more files" shown in the reported error. ZIP CRC success alone
did not detect this compatibility problem.

## Repair
The replacement ZIP explicitly records every directory, parents before children,
before writing files. It uses portable relative names and standard ZIP Deflate.
The internal root folder is shortened to ASCII_RAIN_v0_9_1.
The included packager rejects archives with missing/late parent directory entries
and tests sequential extraction both with and without stripping the root folder.

## Open the project / Как открыть
1. Extract the ZIP to a NEW writable folder; do not merge with a partial import.
2. In Godot Project Manager choose Import, then the extracted project.godot.
3. Open the existing project. Do not create a blank replacement project.

Для Windows: распакуй архив через «Извлечь всё» в новую папку. В Godot выбери
Import → ASCII_RAIN_v0_9_1/project.godot → Import & Edit. Не выбирай старую
папку, где распаковка оборвалась. Рабочие старые версии удалять не нужно.

Direct ZIP import is also supported by the repaired directory-entry structure.
Use an empty writable installation directory.

## Scope of validation
Packaging and extraction checks are not Godot parser, GPU or Play Mode tests.
Original build logs remain unchanged and describe the original v0.9.1 source
validation. This repair does not claim new runtime or device testing.

## Packaging future versions
    python tools/package_project.py pack /path/to/project /path/to/new_archive.zip
    python tools/package_project.py check /path/to/new_archive.zip

Upstream extraction code reviewed:
https://github.com/godotengine/godot/blob/master/editor/project_manager/project_dialog.cpp
