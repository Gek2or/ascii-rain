# ASCII//RAIN v0.7 — Vertical Slice Notes

## Goal

Make District 01 readable and satisfying enough to evaluate the actual game loop: movement → combat → build growth → teleporter pressure → WATCHER encounter → reality fragment discovery.

## Combat contract

Damage-heavy enemy actions should communicate intent before damage is applied. Normal melee, ranged, Tank burst, Bomber detonation, WATCHER fan, WATCHER radial burst and WATCHER FIELD COLLAPSE now have explicit windup states. The telegraph layer is built from emissive primitive geometry so it survives the ASCII post-process without requiring texture assets.

Standard enemy windups can be interrupted by sufficient stagger. WATCHER is resistant rather than fully interruptible. Dash grants a brief invulnerability window so players have a deterministic defensive answer to telegraphed attacks.

## Boss phase contract

WATCHER starts as PHASE 01 // OBSERVER. At 55% health it enters PHASE 02 // OVERWRITE: core becomes magenta, fins open, movement accelerates, projectile cadence increases and FIELD COLLAPSE becomes available. The transition is an explicit gameplay state, not only a cosmetic color swap.

## Reality Archive contract

The ASCII world itself does not become ordinary 3D. Reality fragments remain rare exceptions rendered in a separate unfiltered 3D inspection viewport. Fragment 01 recovers SUNLIGHT. Fragment 02 appears after WATCHER and recovers CHILDHOOD through a hand-made wooden toy. Both persist in `user://ascii_rain_profile.cfg`.

## Performance contract

- Telegraphs use primitive emissive meshes, no dynamic shadows.
- Dynamic city lights remain selective on mobile.
- Audio uses a fixed reusable voice pool.
- Enemy and projectile caps still come from `RuntimeProfile`.
- No skeletal animation dependency was added.

## Next target

v0.8 should focus on run structure rather than raw content count: stronger teleporter waves, elite behavior differences, two active abilities, proper pickup choice UI, and a small post-boss transition into District 02.
