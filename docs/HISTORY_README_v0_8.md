> v0.8.1 playtest pass: readability, responsive HUD, fairer district encounters.

# ASCII//RAIN — Godot 4 Prototype v0.8

Third-person 3D action roguelike rendered through a full-screen ASCII/glyph post-process. The simulation remains conventional 3D so movement, combat, physics, animation and level design stay flexible, while the player's normal perception of the far-future city is encoded into symbols.


## v0.8 — World, Controls & Settings Pass

v0.8 expands the city to roughly **5.2× the previous playable area** and changes encounter pacing from an always-on spawn stream to **district-driven encounters**. The Arrival Node is quiet; enemies begin to appear after the player explores named districts, while the teleporter still escalates into an event director.

The player controller received acceleration/deceleration, coyote time, jump buffering, variable jump height, a preserved shoulder camera with procedural motion, improved camera-to-muzzle aiming, and a dynamic reticle with spread/hit feedback. Player and enemy silhouettes gained more articulated geometry.

A persistent in-game settings menu now exposes Low/Medium/High/Ultra presets plus render scale, ASCII density, bloom, lighting, shadows, look sensitivity, music and SFX volume. An original ambient track (`assets/music/district_signal.wav`) is included and controlled through `AudioManager`.

See `docs/WORLD_CONTROL_PASS_v0_8.md` for implementation details.

## v0.7 — Vertical Slice Combat Pass

v0.7 turns the existing prototype into a more readable combat slice rather than adding another pile of disconnected content. The main focus is attack communication, boss identity, impact feedback, environmental readability, and the Reality Archive story mechanic.

### Combat readability

- Melee enemies now wind up before striking instead of applying damage instantly.
- Gunner and Tank shots use world-space emissive aim telegraphs before firing.
- Bombers visibly enter an overload state and show their blast radius before detonation.
- Strong stagger can interrupt a normal enemy windup.
- Player dash now includes a short invulnerability window so the move functions as an intentional dodge.
- Added full-screen damage feedback on player hits.

### WATCHER phase 2

- WATCHER now has a true second phase at 55% health: **PHASE 02 // OVERWRITE**.
- Phase 2 changes core color, fin silhouette, movement speed and attack cadence.
- Boss fan and radial attacks are telegraphed before release.
- Added a large FIELD COLLAPSE slam with an 8.5 m warning ring, damage falloff and radial projectile release.
- HUD explicitly reports the current boss phase.

### City / lighting

- Raised ambient and player-forward lighting again for combat readability.
- Added wet reflective-looking street patches using inexpensive low-roughness geometry.
- Added six illuminated storefronts, additional emissive strips, a transit arch, road markings and utility cabinets.
- Enemy geometry now includes antennae, side armor and knee detail while retaining primitive low-cost meshes.

### Sound pass

- Added lightweight original procedural WAV effects for the three weapons, hit impact, dash, player damage, boss warnings and Reality Archive discovery.
- Sound playback uses a small reusable voice pool through `AudioManager`; weapon fire does not instantiate a new audio node every shot.

### Reality Archive

- Archive expanded to 2 persistent fragments.
- The original **PHOTOGRAPH // FAMILY IN SUNLIGHT** remains discoverable.
- Destroying WATCHER causes a second anomaly to appear near the teleporter: **WOODEN TOY // WHEELED OBJECT**.
- The second fragment introduces the recovered concept **CHILDHOOD** and has its own unfiltered 3D inspection model.

See `docs/VERTICAL_SLICE_v0_7.md` for the implementation notes.

## v0.6 — Architecture Foundation

v0.6 keeps the v0.5 combat/city presentation, but reorganizes the codebase so future weapons, enemies, relics, Android optimization and story systems can grow without turning the prototype into a monolith.

### Architecture changes

- Added `GameEvents`, `PoolManager`, and `RuntimeProfile` autoload services.
- Moved weapon balance into `WeaponData` `.tres` resources and added `WeaponController`.
- Moved enemy archetype balance into `EnemyData` resources.
- Moved relic catalog/stack ownership into `ItemData` resources + `InventoryComponent`.
- Enemy projectiles and player tracers now use object pooling.
- Centralized PC/Android rendering and horde budgets in `RuntimeProfile`.
- Added stronger project validation and a formal coding standard.
- Kept all v0.5 gameplay, lighting, city density, animation, story fragment, boss, touch controls, and ASCII rendering.

See `docs/CODE_STANDARD.md` and `docs/ARCHITECTURE_v0_6.md`.

## v0.5 — Combat + City Pass

This build focuses on three things: combat feel, visibility, and environmental density.

### Combat feel

- Three switchable weapons: **Pulse Rifle**, **Scatter Cannon**, and **Arc Carbine**.
- `Q` cycles weapons; `1/2/3` selects directly on desktop; Android gets a **WPN** button.
- Weapon-specific rate of fire, spread, pellet count, damage and tracer color.
- Scatter Cannon creates close-range multi-hit pressure; Arc Carbine fires slower heavy shots and chains into nearby targets.
- Stronger muzzle flash, recoil, weapon movement and camera impulse.
- Short hit-stop on meaningful hits, with a mobile-safe cap.
- Enemy stagger / knockback response.
- ASCII impact glyphs, melee slashes and dash echo trails.
- Player animation now changes weapon silhouette and recoil behavior with the selected weapon.

### Visibility / lighting

- Brighter ambient night lighting while preserving the dark ASCII mood.
- Reduced fog density and a clearer blue night fill.
- Stronger glyph gain and controlled bloom so silhouettes read better.
- Player-mounted forward fill light for navigation and combat readability.
- More street lamps, brighter emissive windows, curbs and data beacons.
- Dynamic enemy lights are restricted to bosses, elites, bombers and tanks to avoid throwing dozens of OmniLights at the renderer.

### City density

- Raised sidewalks and luminous curb strips.
- Abandoned procedural vehicles with wheels and tail lights.
- Benches, bollards and street furniture.
- Neon / data signs integrated into the 3D world.
- Data beacon pillars and overhead cables.
- Existing skyline, monumental facade, trees, plaza markings and cover remain in place.

### Enemy detail

- Added chest armor, shoulders, weapon modules, back units, eye lights and core light treatment.
- Enemy silhouettes differ by archetype rather than all sharing the same body proportions.
- Skitter, Gunner, Bomber and Tank get different visual/animation emphasis.
- WATCHER receives additional armor, eye strip, back fins and a brighter animated core.

## Narrative rule

The setting is a far-future digitized civilization (roughly 2500–2800). The protagonist does **not** gradually turn the ASCII world into ordinary 3D. Instead, extremely rare physical artifacts and story characters can bypass the glyph layer and appear as true non-encoded 3D. These fragments expose how people lived before digitization.

The first persistent fragment remains **PHOTOGRAPH // FAMILY IN SUNLIGHT**. Reality fragments survive run restarts in `user://ascii_rain_profile.cfg`; combat relics remain temporary run power.

## Current playable systems

- Third-person movement, mouse/touch camera, jump and dash
- Full-screen ASCII renderer
- Three player weapons
- Five enemy archetypes + elite modifiers
- Enemy ranged and melee attacks
- XP, credits, level surges and stackable combat relics
- Purchasable caches
- Teleporter pressure event
- WATCHER boss
- Reality Archive + true-3D artifact inspection
- Android touch controls and mobile performance profile
- Windows and Android export presets

## Controls — desktop

| Action | Input |
| --- | --- |
| Move | WASD |
| Look | Mouse |
| Fire | Left mouse |
| Jump | Space |
| Dash | Shift |
| Interact | E |
| Cycle weapon | Q |
| Select weapon | 1 / 2 / 3 |
| Toggle ASCII | F1 |
| Release/capture mouse | Esc |

## Controls — Android

- Left virtual stick: move
- Drag right side: look
- FIRE: shoot
- JUMP: jump
- DASH: dash
- USE: interact
- WPN: cycle weapon

The mobile profile uses larger ASCII cells, fewer active enemies, cheaper dynamic lighting and reduced post-processing while keeping the same gameplay and visual language.

## Open and run

Import the folder containing `project.godot` into a compatible Godot 4.x editor, open `scenes/Main.tscn`, and run the project.

`export_presets.cfg` includes Windows Desktop and Android targets. Producing an APK still requires Android export templates / SDK in the local Godot installation.

## Visual source of truth

- `reference/approved_visual_target.png`
- `reference/approved_combat_target.png`

The night-city ASCII references remain the visual target: readable silhouettes, bright emissive sources, dense glyph detail, fog/depth, and real 3D perspective underneath the character renderer.

## Narrative source of truth

See `docs/STORY_BIBLE_v0_3.md`.
