# ASCII//RAIN v0.17 — Rebuilt Threshold Market

This source release replaces the **runtime** Market Ruins layout only. The five
other district scenes and existing game systems stay in place.

## Map replacement

- Sector 01 is the sole Market runtime layout. The old `market_ruins.tscn` is
  retained as protected historical source but is no longer instantiated.
- The playable route follows the approved first-location structure in order:
  entry lift, tutorial corridor, broken courtyard, scan node, high bypass with
  optional cache, archive passage, prep room, distortion arena and exit lift.
- Node 01 begins at the existing city approach. The legacy Market defense
  terminal was moved to node 04, so it remains one coherent district event.
- Node 05 has its own physical Scan ascent and archive descent. Node 06 has a
  separate elevated cache loop with rails. Node 09 reaches node 10 through its
  own exit walk. No old Market gallery supplies these transitions.
- A solid perimeter shell creates an authored location boundary while keeping
  the entry and exit openings available.

## Visual direction

- New Market surfaces use a sector-only low-luminance palette to recover dark
  negative space under the ASCII renderer. Cyan, amber and red are reserved for
  terminals, route markings, signal fixtures and hazards.
- Architectural ribs, bulkheads, rails, piers and signal pylons provide large
  silhouettes instead of relying on generic market stalls.
- The courtyard now has a collapsed central core, broken slab/beam and partial
  canopy; the tutorial exit and scan bay have strong authored frames visible in
  both raw and ASCII captures.

## Checks actually executed

- `python tools/static_gdscript_guard.py .` — PASS.
- `python tools/validate_project.py` — PASS: 93 GDScript files, 17 scenes,
  20 data resources and 5 autoloads.
- `python -m unittest tests.test_v013 tests.test_v014 tests.test_v015 -v` —
  PASS, 37/37.
- Godot 4.7.2 `tools/run_engine_checks.py` — PASS: import, run state 73/0,
  run loop 42/0, engine smoke, mobile clarity smoke, Sector 01 collision smoke
  19/0.
- Non-headless Godot 4.7.2 `sector01_capture.gd` — exit 0; entry, courtyard,
  bypass and arena staged frames were captured after the runtime replacement.

## Limits

- This validates static collision support and staged scene rendering; it is not
  a complete player traversal, combat-balance or final art-certification pass.
- No physical Android or Windows GPU performance, APK/EXE export, thermal or
  touchscreen validation was run.
- Engine smoke has previously emitted an ObjectDB shutdown warning; this release
  does not claim to have fixed or profiled that lifecycle issue.
