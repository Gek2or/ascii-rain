# ASCII//RAIN v0.16 — Threshold Market Sector

This cumulative source release continues the supplied v0.13 project. It does
not replace the existing city, six districts, encounter director, weapons,
relics, WATCHER, Reality Archive, Android controls, music or ASCII renderer.

## Implemented

- Added Sector 01 inside Market Ruins as a compact, authored ten-node route:
  01 entry lift, 02 tutorial corridor, 03 broken courtyard, 04 scan node,
  05 bypass, 06 side cache, 07 archive passage, 08 prep room,
  09 distortion arena and 10 exit lift.
- Used the existing reusable city module layer for visible geometry and static
  physics. Floors are real collision surfaces; walls, piers and arena pylons
  are solid. Decorative ribs and seams stay non-physical and batched.
- Kept the existing Market terminal reachable at the scan node. The new arena is
  within the existing Market event area rather than creating an incompatible
  second encounter system.
- Added a matched convex descent ramp with physical rails, and retained the
  city-wide seam overlap policy at connected deck edges.
- Added segmented bulkheads, wall ribs, support piers, signal pylons and local
  lights for stronger doorway and vertical silhouettes. Route labels billboard
  toward the camera so their direction cannot mirror them.

## Checks actually executed

- `python tools/static_gdscript_guard.py .` — PASS.
- `python tools/validate_project.py` — PASS: 93 GDScript files, 17 scenes,
  20 data resources, 5 autoloads.
- `python -m unittest tests.test_v013 tests.test_v014 tests.test_v015 -v` —
  PASS, 37/37.
- Godot 4.7.2 `tools/run_engine_checks.py` — PASS: project import, run state
  73/0, run loop 42/0, engine smoke, mobile clarity smoke and the new Sector 01
  collision smoke 19/0.
- Non-headless Godot 4.7.2 `sector01_capture.gd` — exit 0; staged entry,
  courtyard, bypass and arena frames were captured and inspected.

## Limits

- The staged capture is an engine visual inspection, not a player playthrough,
  art-final approval or a benchmark.
- Physical Android/Windows performance, thermal, touch, APK/EXE export and
  full combat balance validation were not executed.
- Earlier engine-smoke runs have reported two ObjectDB instances at exit. This
  release does not claim to have fixed or profiled that lifecycle warning.
