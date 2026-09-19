# ASCII//RAIN v0.18.2-alpha — Hero Animation and Camera Zoom

This release continues the existing Entity 01 integration and raw hero render
pass.

## Hero animation

- The existing `Hover_Idle` / `Glide_Loop` locomotion state now treats airtime as
  flight and restarts the flight pose at jump takeoff. The supplied GLB has no
  dedicated `Jump` animation; no new skeletal clip was fabricated.
- Existing Dash, Cast Pulse, Hit Recoil and Dissolve event bindings remain.
- A Reality Archive fragment now plays `Human_Echo`, followed by `Reconstruct`
  when the echo clip finishes, then returns to the current locomotion state.

## Camera zoom

- Mouse-wheel up/down adjusts the existing SpringArm3D distance.
- Zoom eases at a fixed rate and is clamped between 2.8m and 9.0m. The current
  camera, collision behavior and aim ray remain the source of truth.

## Verification

- `static_gdscript_guard.py`, `validate_project.py`, and 37 source-contract unit
  tests pass. `tests/entity01_smoke.gd` passes twice, covering model clips,
  jump-to-glide, archive animation routing, zoom easing/bounds, player collision
  and raw-pass occlusion. Sector 01 collision smoke passes 19/19 checks.
- The broad engine runner passes import, run-state (73), run-loop (42), gameplay
  smoke and Entity 01 smoke, then exits on `mobile_clarity`: headless Dummy
  renderer logs `Parameter "material" is null` although that smoke prints its
  success marker. This is not reported as a fully passing engine suite.
- Android physical-device input/performance and exported binaries are not
  verified here.
