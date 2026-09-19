# ASCII//RAIN v0.15.5 — Dynamic Tension Lighting

This is a continuation of the supplied v0.13 source through v0.14.1. It keeps
the six districts, navigation, encounter director, weapons, relics, WATCHER,
Reality Archive, Android controls, music and pooled ASCII FX intact.

## Implemented

- Versioned the source project as `0.15.0-alpha`.
- Moved enemy silhouette selection into `EnemyData` as five explicit profiles:
  biped, low, ranged, carrier and heavy.
- Added per-archetype accent palettes for readable armor/back-unit/weapon
  shapes while preserving each enemy's existing core color and AI behavior.
- Added per-archetype stride, bob and attack-pose tuning to the existing
  procedural animation, plus a short core/light hit flash.
- Sealed ground tile edges and ramp/deck joins with small matched visual and
  collision overlaps; the overlap is below gameplay readability scale and does
  not close the authored underground openings.
- Added the supplied `Deserted Coded City.mp3` as the current city soundtrack,
  routed through a dedicated Music bus with low/mid/high spectrum analysis.
- Added bounded audio-reactive energy and tint changes to existing city lights;
  this does not create lights per frame or change gameplay collision.
- Calibrated the spectrum gain so the supplied track produces visible movement
  in low, mid and high bands instead of a nearly imperceptible 1–2% pulse.
- Increased the bounded energy response and mapped smoothed track tension through
  calm blue, rising cyan, tense orange and peak red-magenta tones.
- Kept the existing five enemy archetypes and their current gameplay rules;
  this pass does not add a sixth enemy type or enlarge the map.

## Checks actually executed

- `python tools/static_gdscript_guard.py .` — PASS.
- `python tools/validate_project.py` — PASS.
- `python -m unittest tests.test_v013 tests.test_v014 tests.test_v015 -v` — PASS,
  36/36.
- Godot 4.7.2 `tools/run_engine_checks.py` — PASS after the v0.15 source
  changes: import, run state, run loop, engine smoke and mobile clarity smoke;
  the supplied MP3 imported and the AudioManager analyzer compiled.
- Non-headless Godot 4.7.2 `reference_city_capture.gd` — exit 0; staged Market,
  Utility and Rooftop captures visually inspected after the seam change.
- The separate legacy `encounter_tactics_test.gd` harness did not return its
  result marker within the observation window; it is not reported as PASS.

## Open limits

- No physical Android or Windows FPS, memory, thermal, touch, APK or signed EXE
  validation was performed.
- No final combat-balance certification or new enemy-combat visual capture was
  performed in this pass.
- The headless suite verifies analyzer creation and runtime stability, but does
  not prove audible spectrum response on a physical audio device; a final
  Windows/Android visual and performance check remains open.
- The engine smoke still reports the pre-existing two ObjectDB instances leaked
  at process exit; it is not claimed fixed.
