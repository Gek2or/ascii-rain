# Native QA provenance — v0.10

## Engine and provenance

Official repository: godotengine/godot. Master push workflow run `34621975671`,
commit `3756fbb2c79a3f77fd9cdfc39d4fbb2ae2618405`.
Downloaded via the connected GitHub workflow-artifact action:

- `linux-template-mono-debug`, artifact `10273424473`.
- ZIP SHA-256: `3f116456f6d289563100bff982f6135894ad64581f6df930d6135a843bdc767a`.
- Actual reported version: `4.8.dev.mono.gh.3756fbb2c`.
- Binary digest for executed tests is in `build/native_provenance.json`.

The editor artifact was also obtained and its ZIP digest checked, but could not
initialize because this host lacks .NET hostfxr/runtime. It was not used to
claim successful editor import. The debug template skips C# initialization when
the project does not advertise the dotnet feature. No executable is distributed
in the game project.

## Native template method

`tools/run_debug_template_checks.py` creates an isolated copy. Because export
templates do not perform editor import, a small native Godot scene loads PNGs
with Image.load_from_file, creates ImageTextures, loads WAVs as AudioStreamWAV,
and saves .res files using ResourceSaver. Temporary .remap entries point to
these resources. A temporary global script class cache is assembled from the
source declarations. The engine still parses/type-checks GDScript and executes
actual scene/physics/input/UI code. No Python model substitutes that execution.

A small bootstrap attaches each supplied SceneTree test to the live SceneTree.
Neither bootstrap, binary, imported test resources nor temporary save files
are included in the playable source ZIP. The tests themselves and reproduction
script are included. User data directories are isolated for each case.

These remaps do not establish equivalence with each Godot Editor's import
configuration, color pipeline or compression choices. In particular, normal
texture importer behavior still needs the user's editor test.

## Scope

Headless cases use real Godot physics/scene trees and a dummy renderer. They
exercise the run state, transactions, signals, routing, movement and synthetic
input. They do not measure device latency, tactile usability, gameplay balance
or FPS. A scripted victory is not a human playthrough.

Graphical capture uses the same Godot build with gl_compatibility, Xvfb and
Mesa llvmpipe. The game's shaders are compiled by Godot and real scene frames
are saved from the root viewport. This is NOT a translated shader probe or
image generation. It remains a SOFTWARE renderer, not an Android/Windows GPU.
The expected V-Sync unsupported warning is recorded in the log.

`tools/run_engine_checks.py` remains available for a normal editor's real import
plus the same tests. This path has not been successfully run in this environment.
Physical device playtests and APK/EXE exports are not performed for this release.
