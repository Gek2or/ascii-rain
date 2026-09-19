# ASCII//RAIN v0.18.1-alpha — Raw Hero Render Pass

This update separates the playable Entity 01 hero from the ASCII post-process
without changing the city renderer or the player's gameplay systems.

## Rendering behavior

- A transparent `SubViewport` shares the existing 3D world and renders only the
  hero's visual meshes on a dedicated layer. Its camera follows the active game
  camera, including projection and lens settings.
- The main camera excludes that layer, so the hero does not also appear as an
  ASCII silhouette. World geometry, enemies and props remain in the existing
  ASCII pass.
- The raw pass uses the scene's lights. Three camera-to-hero ray samples are
  checked at 12.5 Hz. When an obstacle blocks the view, the overlay is hidden and
  the hero returns to the normal world layer; after the view clears, the raw pass
  is restored. This preserves wall occlusion without rendering world geometry a
  second time.

## Verification

- `tests/entity01_smoke.gd`: passed with Godot 4.7.2 stable headless; checks the
  separate render layer, existing player collision/locomotion and occlusion
  fallback/restoration.
- `tests/entity01_capture.gd`: staged mixed ASCII/raw and raw-world captures
  produced with the Compatibility renderer.
- Physical-device performance, Android GPU compatibility, and exported builds
  have not been verified in this update.
