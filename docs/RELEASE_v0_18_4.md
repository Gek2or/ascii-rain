# ASCII//RAIN v0.18.4-alpha — Sky Portal Event and Hero Separation

This cumulative visual update keeps the existing map, portal logic, soundtrack
switch and ASCII renderer intact.

## Portal event

- Activation keeps the local pulse light and additionally creates a high
  `PortalSkyProjector` and a non-shadow-casting directional event light.
- Their energy and colour follow the existing Music-bus low/mid/high analyzer.
  Existing district lights also receive the temporary event boost.
- All portal-event lights remain bounded to the existing 18-second chaos
  window, then free themselves. No new shadow maps or translucent beam meshes
  are created.

## ASCII detail and hero readability

- The visual settings menu now exposes a 1–10px ASCII cell width. New 1px, 2px
  and 3px area-filtered atlases are generated from the supplied glyph source.
  One pixel is a dense micro-code mode, not a promise that a full glyph can be
  recognized at that physical size.
- Entity 01's Living Code material has lower emission and limited vertex-colour
  bleed; the Void Silhouette material has far less fragmentation and a controlled
  rim. The player remains a separately rendered raw pass and returns to the
  depth-tested world pass when occluded.

## Verification

- Godot 4.7.2 editor import completed successfully.
- `tools/static_gdscript_guard.py` and `tools/validate_project.py` passed.
- `tools/build_glyph_atlases.py --check` reported `6 / 6` micro-code outputs
  identical while retaining the approved 4-10px source textures.
- `python -m unittest tests.test_v013 tests.test_v014 tests.test_v015 -q`
  passed: 38 tests.
- `run_loop_smoke.gd` passed: `48 checks / 0 failures`, including the two
  upper portal lights. `smoke_test.gd` and `entity01_smoke.gd` also passed.
- Non-headless OpenGL 3.3 captures were made for the active portal event and
  Entity 01 ASCII/raw presentation. They are visual evidence, not a performance
  benchmark.

## Known limits

- The general engine smoke scenario still reports Godot's existing warning of
  two ObjectDB instances during shutdown, despite completing its assertions.
- PC/Android GPU performance, gameplay balance and physical-device testing are
  not established by these checks.
