# ASCII//RAIN v0.18.0-alpha — Entity 01 Hero Integration

This continuation integrates the supplied Entity 01 asset into the existing
v0.17.1 project. It does not replace the game controller or rebuild the player.

## Integration

- `models/Entity01.glb` is the desktop visual; `models/Entity01_Lite.glb` is
  selected for the existing mobile runtime profile.
- `godot/character/entity_visual.gd` owns GLB instantiation, glyph materials,
  morph updates and clip playback.
- `scripts/entity01_player_bridge.gd` keeps the old `Player` gameplay surface
  intact and forwards locomotion, dash, shot, damage and death state into the
  new visual.
- The old procedural body is hidden, but `Visual/WeaponPivot`, muzzle flash,
  weapon data, camera and the capsule collision remain active.

## Checks actually executed

- `python tools/static_gdscript_guard.py .` — PASS.
- `python tools/validate_project.py` — PASS: 97 GDScript files, 18 scenes,
  20 data resources and 5 autoloads.
- Godot 4.7.2 headless `tests/entity01_smoke.gd` — PASS: model instance,
  eight clip interface names, player collision and locomotion bridge.
- Godot 4.7.2 non-headless OpenGL 3.3 capture `tests/entity01_capture.gd` —
  exit 0; ASCII and raw frames captured and visually inspected.

## Known limits

- No physical Android device, APK export, Windows packaged build or measured
  device FPS was run in this session.
- Entity 01 is integrated as a visual actor; its supplied animation clips are
  in-place and do not replace the existing gameplay movement or collision.
- Weapon geometry remains the project's existing `WeaponPivot`, so the hero
  asset is not claimed to include a new weapon model.
