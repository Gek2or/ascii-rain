# ASCII//RAIN v0.8 — World & Control Pass

This pass focuses on making the prototype easier to read, move through, and scale on both desktop and Android without changing the core rule: gameplay remains true 3D while normal perception is rendered through the ASCII layer.

## Graphics / settings

- Added persistent `SettingsManager` autoload using `user://ascii_rain_settings.cfg`.
- Added in-game settings overlay (ESC on desktop, SET on mobile).
- Presets: Low, Medium, High, Ultra.
- Runtime controls for 3D render scale, ASCII cell size, ASCII bloom, world-light multiplier, dynamic shadows, look sensitivity, music volume, and SFX volume.
- `RuntimeProfile` now consumes the settings so Android and desktop budgets remain centralized.

## Player / camera / aiming

- Movement now uses ground acceleration, separate deceleration, reduced air control, coyote time, jump buffering, and variable jump height.
- Procedural animation reacts to velocity lag and acceleration so starts, stops, strafes, landing, air movement and weapon motion feel less rigid.
- Shoulder camera position is preserved while procedural bob/recoil/shake is applied as an offset.
- Center-screen camera ray determines the desired aim point; the weapon ray is then resolved from the muzzle toward that point. This reduces third-person crosshair/parallax mismatch.
- Replaced the old text crosshair with a dynamic drawn reticle that expands with movement, weapon spread, airborne state and dash, and shows hit/critical feedback.

## World scale

- Previous playable footprint was roughly 72 × 72 world units (~5,184 square units).
- v0.8 expands this to roughly 164 × 164 (~26,896 square units), about 5.2× the playable area.
- Added a three-axis road grid, remote district pads, secondary facades, emissive bands, pylon clusters, consoles, extended lighting, outer skyline and more road detail.
- Districts: Arrival Node, Archive Row, Utility Spine, Market Ruins, Memory Gardens, Null Terminal, Signal Concourse.

## Encounter pacing

- Removed the old always-on timed ambient enemy stream.
- Arrival Node starts as a protected exploration space with a short grace period.
- New districts trigger a discovery event and a first combat wave after entry.
- Ambient encounters continue only after the player has entered an active district.
- Teleporter event temporarily switches the director into a more aggressive event-spawn mode.
- Enemy type, elite probability and wave size still scale with run threat/difficulty.

## Geometry / readability

- Player gained additional articulated visual pieces: neck/waist joints, rib plates, elbow guards, hands, shin armor and ankle joints.
- Enemies gained jaw/waist/hip parts, hands/elbows, back vents and spine armor in addition to existing class-specific silhouette changes.
- The added pieces deliberately reuse primitive resources and emissive materials so the ASCII renderer gains richer silhouettes without large texture memory costs.

## Music

- Added `assets/music/district_signal.wav`, an original lightweight dark ambient/data-pulse loop generated for this prototype.
- `AudioManager` owns music playback and immediately reacts to saved music/SFX volume settings.

## Performance intent

The larger city is visually denser, but expensive real-time lights remain sparse and mobile profiles still reduce enemy count, shadow cost, render scale and ASCII density. Further city optimization should move repeated geometry to MultiMesh/instancing once the layout is locked.
