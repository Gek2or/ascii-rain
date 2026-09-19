# Visual Balance — implementation and QA

## Evidence
The submitted screenshot was reproduced in the base v0.10 native Compatibility scene.
The prior shader floors density at a nonempty character and applies pow(tone, 0.52),
so dim surfaces jump into the alphabet's Y/L/T/K range. Area-normalized ink compensation
then boosts each stroke. Cell-average correctness is not sufficient for gameplay:
a field of white letters can preserve the mean while burying silhouettes.

On the native 6px test patch with source gray 0.20, the old stroke peak is 0.6431,
new peak 0.2941. Within-cell standard deviation drops from 0.2037 to 0.0300.
These are isolated SDR gray test-patch measurements, NOT FPS or a universal visual score.
The bed remains 0.1373 in this case; the fix removes bright stroke noise, not all detail.

## New rendering contract
A monotone blank/punctuation density ramp replaces randomized letter substitutions.
Adjacent glyph masks crossfade smoothly. Ink contrast is bounded with no reciprocal
coverage factor. Geometry edge/highlight weighting comes from the existing five scene
samples; no normal-buffer dependency, semantic enemy mask or x-ray outline is added.
The optional existing depth-contour pass remains off by default.

The ground/walls retain a per-cell color bed. It is honest to call this glyph rendering
with cell-tone support, not a renderer made exclusively of bright text on pure black.
No full-resolution raw-3D layer is composited under the cells.

Sky fog influence is 0.08 instead of 1.0, retaining the same ambient street lighting.
Player material mapping retains differences in source albedo. Collision, animation,
weapons, enemies, director and narrative are not redesigned by this hotfix.

## Preferences
No new render schema and no automatic reset. The existing settings file is unchanged.
Quality tiers still affect rendering cost, not the meaning of contrast controls.
A manual RESTORE READABLE NIGHT remains available, but is not necessary for the fix.

## Reproduce native tests
Use a trusted executable, not an engine included in this ZIP (none is bundled):

```sh
python tools/run_debug_template_checks.py --template /path/to/godot-debug-template --render
```

On a headless Linux host, supply a working DISPLAY (e.g. Xvfb) and optionally
LIBGL_ALWAYS_SOFTWARE=1. Native visual tests require rendering, not --headless.
The helper builds a disposable resource-remapped project and an isolated user directory.
This is NOT the editor's resource importer and does not validate APK/EXE export.

`tests/visual_balance_test.gd`: 126 assertions, 7 widths, 11 gray levels,
black preservation, nonzero midtone floor, capped dim ink, actual glyph variation,
identical repeated frames and comparison to legacy shader noise.
`tests/visual_balance_capture.gd`: same paused scene in corrected/raw/legacy shader modes,
plus UI/settings/paused preview screenshots. No generated reference image is used as output.

The old mean-only translated-fragment checker is archived as a historical fixture.
Source tests now check the new bounded-contrast contract, with native pixel tests as
independent evidence. Test count is not evidence of final art quality.

## Limitations
Test engine: Godot 4.8.dev.mono.gh.3756fbb2c Linux debug template.
OpenGL software renderer: llvmpipe / Mesa. The only warning in final graphical logs
is unsupported V-Sync. Editor import, stable-engine GPU behavior, physical Android,
full human playthrough and hardware FPS remain unverified.
The game still uses prototype geometry; it does not match the approved concept art.

## Documentation consulted
- https://docs.godotengine.org/en/stable/classes/class_environment.html (fog_sky_affect)
- https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html
  (color textures vs data masks; mask textures intentionally do not use source_color)
