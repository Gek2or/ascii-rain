# ASCII//RAIN v0.14.1 — Combat FX and Runtime Allocation Pass

This is a narrow continuation of the supplied v0.13 source project. It does
not rebuild the game, replace the six-district city, or change the ordinary
world's ASCII presentation.

## Implemented

- Added a pooled `AsciiGlyph` scene and lifecycle component.
- Routed burst, impact, dash and melee glyphs through the existing
  `PoolManager`, removing per-glyph `Label3D` allocation/free churn.
- Kept v0.13 weapons, relics, enemies, navigation, district events, WATCHER,
  Reality Archive, touch controls, music and renderer behavior intact.
- Replaced the newer renderer-method query with a project-setting read that is
  compatible with the declared Godot 4.3 project target.
- Made the validator ignore generated editor/cache directories after import.
- Made weapon recoil, muzzle-flash duration and muzzle-light energy explicit in
  `WeaponData`, with distinct values for Pulse, Scatter and Arc.

## Checks actually executed

- `python tools/static_gdscript_guard.py .` — PASS.
- `python tools/validate_project.py` — PASS; 89 GDScript files, 17 scenes, 20
  data resources, 5 autoloads.
- `python -m unittest tests.test_v013 tests.test_v014 -v` — PASS, 31/31.
- Godot 4.7.2 `tools/run_engine_checks.py` — PASS: import, run state 73/0,
  run loop 42/0, engine smoke, and mobile clarity smoke.

The Godot 4.7.2 smoke run still reports the pre-existing warning about two
ObjectDB instances leaked at process exit. That warning is not claimed fixed.

## Open limits

- No physical Android or Windows device FPS, memory, thermal, touch, APK or
  signed EXE validation was performed.
- No final human visual-match or combat-balance certification was performed.
- The pooled glyph path has source/static coverage, but a dedicated isolated
  spawn-to-recycle native smoke was not retained because the headless harness
  did not terminate cleanly; it is not claimed as runtime-proven here.
- A Godot 4.3 run reached the runtime suite but failed two pre-existing
  starter-offer assertions (61 checks / 2 failures), so 4.3 is not reported as
  a passing release runtime. Godot 4.7.2 is the passing engine used above.
- The supplied archive's original v0.13 native report remains historical; its
  Linux 4.8-dev template and temporary asset remaps were not reproduced here.
