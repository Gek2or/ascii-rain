# Build status — v0.13

See `../build/RELEASE_REPORT.txt` for executed native/source/package checks and
explicit exclusions. This is a Godot **source project**, not an exported binary.
The Godot debug-template tests do not substitute for a stable editor import or a
physical Android/Windows playtest. Screenshots are staged actual-engine captures.

Known warning: the general native smoke test passes but reports two ObjectDB
instances left at process exit. This lifecycle warning remains open; tests are
not described as warning-free. See the release report for exact scope.
