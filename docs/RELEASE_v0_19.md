# ASCII//RAIN v0.19.0-alpha - Location 01 Split

## Play spaces

- `scenes/TestArena.tscn` inherits the existing `Main` scene and retains the
  complete city as a combat, navigation and renderer test space.
- `scenes/Location01_ThresholdMarket.tscn` also inherits the stable game shell,
  but switches the city and run profiles to `threshold_market` at scene load.
  It therefore loads only Sector 01 instead of the full six-district city.

## Location 01: Threshold Market

1. Entry lift: safe arrival and starter cache.
2. Tutorial corridor: movement, camera and weapon read.
3. Broken courtyard: first combat cover and sightlines.
4. Scan node: route objective and lore terminal space.
5. Bypass: elevated ramp/bridge route.
6. Side cache: optional elevated reward path.
7. Archive passage: constricted transition.
8. Prep room: local recovery and purchase space.
9. Distortion arena: teleporter location and event arena.
10. Exit lift: handoff point for the future second location.

The sector has authored decks, convex ramps, static collision, route markers,
walkable-surface metadata, four local route lights and one non-shadowing sky
fill. Its old global-city floor and other district systems are not loaded.

## Verification

- Godot 4.7.2 headless `location01_smoke.gd`: 9 checks / 0 failures.
- Godot 4.7.2 headless `run_loop_smoke.gd` in a temporary empty profile:
  48 checks / 0 failures for the preserved Test Arena.
- `tools/static_gdscript_guard.py` and `tools/validate_project.py` passed.
- `python -m unittest tests.test_v013 tests.test_v014 tests.test_v015 -q`
  passed: 39 tests.
- Non-headless OpenGL 3.3 captures were made for the entry view and overview.

## Known limits

- The exit lift is a visual/route handoff; Location 02 is not implemented yet.
- Godot reports two ObjectDB instances and one resource still in use when the
  isolated Location 01 smoke process exits, after its assertions pass. Physical
  Android testing has not been performed.
