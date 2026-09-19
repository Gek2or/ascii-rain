# v0.19.1-alpha — Location 01 Soundscape

- Added the supplied rain loop, terminal typing and two digital glitches as
  spatial Location 01 audio. Rain/typing stop when District ambience is muted.
- Added one-shot entry and side-cache triggers, with native checks covering all
  four supplied WAV files.

# v0.19.0-alpha — Location 01 Split

- Preserved the existing all-district city as the `TestArena` scene for combat,
  navigation and renderer testing.
- Added the standalone `Location01_ThresholdMarket` scene. It builds only the
  detailed ten-node Threshold Market route, its navigation surfaces and local
  run spawns; the other five districts are not loaded.
- Added bounded non-shadowing sky/route lighting for the standalone sector and
  a native smoke/capture path for its isolated load.

# v0.18.4-alpha — Sky Portal Event and Hero Separation

- Added a high, music-reactive PortalSkyProjector and a bounded sector-wide
  event light to teleporter activation; no translucent beam mesh can obscure
  the camera.
- Added native 1–3px glyph atlases and exposed the full 1–10px ASCII cell-size
  range; 1px is an intentionally dense micro-code mode.
- Reduced Entity 01 code emission, constrained its colour bleed and reduced
  silhouette fragmentation so the raw hero reads as one character rather than
  as part of the surrounding glyph field.

# v0.18.3-alpha — Portal Signal and Reactive Light Chaos

- Added the supplied `Corrupted Signal.wav` as the soundtrack on teleporter
  activation; starting a new run restores the city soundtrack.
- Strengthened the Music-bus spectrum response during the portal event and added
  a nearby, non-shadow-casting pulse light with shifting tones and an 18-second
  bounded fade.
- Extended the native run-loop smoke test for portal music, the extra light,
  event fade and soundtrack restoration.

# v0.18.2-alpha — Hero Animation and Camera Zoom

- Routed airborne/jump state to the supplied `Glide_Loop` clip, bound
  `Human_Echo` and `Reconstruct` to Reality Archive discovery, and preserved
  existing idle, movement, dash, cast, hit and death reactions.
- Added eased third-person camera zoom on mouse-wheel input with minimum and
  maximum spring-arm distances.
- Extended the Entity 01 smoke test for animation event routing, jump state,
  camera easing and zoom limits.

# v0.18.1-alpha — Raw Hero Render Pass

- Rendered the Entity 01 hero in a transparent 3D viewport over the existing
  ASCII-rendered city, leaving world geometry, enemies and props in the ASCII pass.
- Mirrored the active camera and lighting for the hero pass; ray-tested camera
  occlusion returns the hero to the world pass behind blocking geometry.
- Added runtime coverage for the pass configuration, locomotion/collision bridge
  and wall-occlusion fallback, plus staged mixed/raw captures.

# v0.18.0-alpha — Entity 01 Hero Integration

- Integrated the supplied `Entity01.glb` and `Entity01_Lite.glb` into the
  existing Player scene as the primary hero visual.
- Preserved the existing Player controller, capsule collision, camera,
  WeaponPivot, combat feedback, district systems and Android touch controls.
- Added a small bridge for locomotion, dash, weapon cast, hit recoil and death
  clips; mapped Godot's imported `Glide` clip to the `Glide_Loop` interface.
- Added a Godot smoke test and staged ASCII/raw captures for the integrated hero.

# v0.17.1 — Threshold Market Silhouette Pass

- Added the collapsed courtyard core, broken slab/beam, partial canopy and
  tutorial exit bulkhead so the first location reads as authored architecture,
  not an open procedural plaza.
- Added a scan-node ceiling frame and vertical signal column; preserved the
  existing terminal interaction and static collision rules.
- Rechecked staged raw and ASCII captures after the silhouette pass.

# v0.17 — Rebuilt Threshold Market

- Removed the legacy Market Ruins scene from runtime instantiation; its protected
  v0.13 source remains intact as an archive, while Sector 01 now owns the market.
- Reoriented the ten-node path so node 01 begins at the existing city approach,
  then leads through nodes 02–10 in the approved first-location order.
- Built the high bypass, Scan ascent, archive descent, cache loop, perimeter
  shell and exit walk from the new map's own collision geometry.
- Moved the existing Market defense terminal to the Scan Node instead of adding
  a separate encounter system.
- Made the new Market palette dark by default, with route/terminal accents kept
  cyan, amber and red for discrete ASCII readability.

# v0.16 — Threshold Market Sector

- Added the first physical ten-node Sector 01 route inside the existing Market
  Ruins: entry, tutorial, courtyard, scan node, bypass, cache, archive, prep,
  arena and exit.
- Built explicit floors, walls, supports, ramp/deck joins, bulkheads and arena
  pylons; the route is not a new map or a replacement for the six districts.
- Added billboard route labels so the numbered nodes remain readable from either
  direction in the 3D city.
- Added an actual Godot collision smoke test with ten floor probes and seven
  collision-body assertions for the new Sector 01 geometry.

# v0.15.5 — Dynamic Tension Lighting

- Made soundtrack-driven energy response stronger while keeping a hard upper
  bound per light.
- Added smoothed tension tones: calm blue, rising cyan, tense orange and peak
  red-magenta, derived from the low/mid/high track envelope.

# v0.15.4 — Audio-Reactive City Calibration

- Increased and bounded spectrum normalization for the supplied soundtrack so
  the existing city lights visibly respond during playback.
- Kept the Music bus, low/mid/high split, ASCII renderer and gameplay systems
  unchanged.

# v0.15.3 — Audio-Reactive City Pass

- Added the supplied `Deserted Coded City.mp3` as the current city soundtrack.
- Added a dedicated Music bus with low/mid/high spectrum envelopes for runtime
  visual feedback.
- Added bounded energy/tint response to existing city lights while preserving
  the ASCII renderer, district layout, gameplay collision and Android profile.

# v0.15.2 — City Surface Seam Pass

- Added a small matched overlap to split ground tiles so visible geometry and
  collision do not crack at generated cut boundaries.
- Extended authored ramp wedges into their deck landings, using the same points
  for the visible mesh and convex collision shape.
- Rechecked Market, Utility and Rooftop staged captures after the geometry pass.

# v0.15.1 — Enemy Motion and Hit Feedback

- Added per-archetype stride, bob and attack-pose tuning to the existing enemy
  procedural animation.
- Added a short core/light hit flash and stronger core pulse without changing
  enemy health, damage, AI or navigation.
- Kept the five data-driven silhouette profiles and v0.14 pooled ASCII FX.

# v0.15 — Enemy Silhouette Profiles

- Versioned the current continuation as `0.15.0-alpha`.
- Moved the five existing enemy silhouette choices into `EnemyData` profiles
  and added distinct accent palettes for ASCII-readable enemy separation.
- Preserved existing enemy AI, combat values, districts, navigation and v0.14
  pooled ASCII FX.

# v0.14.1 — Weapon Feedback Tuning

- Made recoil, muzzle-flash duration and muzzle-light energy data-driven per
  weapon without changing damage, fire rate or projectile rules.
- Kept the existing procedural locomotion, pooled ASCII FX and six-district
  source of truth intact.
- Revalidated the full static and native Godot smoke suite after the combat
  feedback change.

# v0.14 — Combat FX and Runtime Allocation Pass

- Pooled ASCII burst, impact, dash and melee glyphs through the existing
  `PoolManager`; repeated combat feedback no longer allocates and frees a new
  `Label3D` for every glyph.
- Kept renderer-method detection compatible with the declared Godot 4.3 target
  by reading the project setting instead of calling a newer API.
- Made the package validator ignore generated `.godot`, `.git` and Python cache
  files after a real editor import.
- Kept glyph identity, dark gaps, ordinary-world ASCII presentation and all
  v0.13 gameplay systems unchanged.
- Versioned the source project as `0.14.0-alpha`; editor/device/runtime QA is
  still pending until a Godot executable and target hardware are available.

# v0.13 — Reference City & District Events

- Replaced blended glyph identities / grey surface bed with stable crisp glyphs,
  restrained negative-space fill, edge-only bars and bounded nonlinear exposure.
- Added Reference Mood / Readable Combat / Mobile Safe and one-time graphics
  migration with backup; controls/audio/archive preserved.
- Broadened player geometry, dark materials and readable accent/rim treatment.
- Added a stepped warm-lit market frontage on existing wall footprints.
- Added Utility Depths at -6m and Rooftop Relay at +10m; six authored districts.
- Cut rendered ground and physics using identical rectangles. Fixed a one-meter
  gap at ramp lips discovered through actual enemy traversal tests.
- Raised entrance clearance and moved the east roof ramp clear of archive walls.
- Expanded supported-layer sampling below street; retained district identity on
  ascent, cached AI paths and no unrelated ground fallback for basement spawns.
- Added district-specific enemy distributions and optional console defenses,
  guarded single payout, failure/abandonment/boss cancellation and side vent cues.
- Reused existing ambience spatially in the new districts; animated rotor/antenna.
- Kept the existing run, music, touch controller, procedural animation and archive.

---
Historical changes below refer to their respective older releases.

# v0.12b — Archive Stacks & Memory Gardens

- Replaced two legacy district clusters without rebuilding the existing Main run.
- Archive courtyard: two 5.5m reading galleries, two crossing bridges, two ramps,
  stepped repository towers, recessed record cabinets, arch/desk/return-slot props.
- Gardens: 2.75m filled terrace, 5.5m open pavilion, four connected ramp segments,
  genuine pavilion underpass, mechanical trees, catch basin, off-route benches.
- New CivicModules uses bounded cylindrical/arched geometry, existing sector trim
  batching and simple static collision; only declared surfaces enter navigation.
- New ground/gallery/terrace/pavilion spawn bands share existing parent IDs.
- Physical support is cached on physics ticks: jumps crossing a height band do not
  activate an unrelated floor. Cached values are discarded on large teleports.
- Consistent minimum-distance filtering for authored and final spawn placement.
- Four existing caches relocated, still fourteen in total. Goal/descent hints
  cover the new districts and lower terrace; no extra discovery/reward counts.
- Archive courier/status board and garden irrigation add pause-safe local motion.
- Two original 16s mono positional ambient loops, finite range and threat ducking;
  independent persisted ambience volume, SFX-linked mute; original music retained.
- Real native multi-floor/player/enemy/zone/spawn/pause tests and staged captures.
- Renderer/atlases/player animation/combat/story/music remain protected byte-for-byte.
- Safe parent-first ZIP directory records retained. Not APK/EXE or final art.

# v0.12a — Living City / Market & Transit

- Replaced two existing district clusters with distinct modular multi-level architecture.
- Shared XZ cells retain multiple supported floors; physically checked slope/capsule/support edges.
- Added 5.5m U-gallery with two ascents, two transit platforms/bridge with two ascents.
- Authored walkable surface IDs, lower/upper encounter zones, bounded reachable spawn anchors.
- Floor changes preserve district visit count/threat budget; stale floor spawn requests discarded.
- Relocated two existing caches upstairs without reward inflation; clear circulation preserved.
- Added one service drone, service-status board and distant decorative transit convoy.
- Pause-safe ambient motion with persistent independent control, distance limits and Low fallback.
- Preserved current glyph renderer, atlases, character animation, combat, music and archive.
- Added native current-city multilayer traversal/zone/spawn/pause regressions and staged captures.
- ZIP retains explicit parent-before-child directory records and safe relative paths.

# v0.11 — ENCOUNTER TACTICS

- Solid physics for existing structural city meshes, without changing the render.
- Incremental shared street A* graph, conservative clearance/support, connected spawns.
- Cached ordinary-enemy routes and ramp following; Gunner reposition/retreat.
- Committed aim, forward melee warning sector and cover-aware damage.
- Owned/cancellable attack cues and post-release recovery.
- Delayed volatile-death hazard, pausable and cancelled on combat end.
- Projectile between-frame ray checks, duplicate-hit guard retained.
- Native physical regressions, whole-city routing checks and a staged engine capture.
- Existing Visual Balance shader/settings, controls, audio and narrative preserved.

# v0.10.1 — Visual Balance

- Reproduced the full-screen Y/T/K noise in the actual native game scene.
- Replaced shadow-to-letter sqrt lookup with a continuous sparse punctuation ramp.
- Removed coverage-normalized stroke amplification; bounded contrast is now explicit.
- Kept original hand-authored/native-sized glyph masks (4–10 px), no font dependency.
- Reduced sky fog contribution separately from street illumination.
- Preserved player material differences instead of a shared bright albedo floor.
- Added desktop HUD text outlines; no new graphics-schema reset.
- Reran native run, input, UI, shader/scene tests; added 126 native pixel checks.
- Existing gameplay/audio/story/geometry/profile files remain protected by hashes.
- Test teardown allows the Dummy audio backend to release playback before exiting.

# v0.10 — RUN LOOP (based on v0.9.2 Render Fix)

- Free starter cache with three mechanically different choices; paid caches now
  offer a deterministic-per-cache choice of up to three eligible relics.
- Pause-safe choice UI for mouse, 1/2/3 and native touch buttons; cancellation
  spends nothing, reopening does not reroll, repeat clicks cannot double-claim.
- Inventory maximum stack is enforced before applying additional stat effects.
- RunProgress + RunGuide: claim, explore any two districts, activate, charge and
  defeat WATCHER, optionally recover the physical toy, extract and view results.
- Single goal bearing/distance marker and high-contrast objective background.
- Bounded spawn-placement queue with real world ray/capsule checks; not navigation.
- Stop director after boss death; clear remaining hostiles without rewards after
  charge completes too. No new waves while recovering the artifact.
- Results include visited districts, claimed caches/relics and new archive records.
- Fixed native add_child failure for the story inspection layer; pause ownership
  across settings/relic/story UI; hidden artifact viewport no longer always renders.
- Held-fire protection on leaving selection/inspection; interaction checks walls.
- Music/SFX content preserved, duplicate initial play removed, explicit audio stop.
- Renderer, atlases, graphic defaults, controls settings, city, animation and
  narrative reference files preserved (64 protected files verified by SHA-256).
- New native Godot state/integration regressions, retained general/touch tests,
  real OpenGL software-rendered captures and a reproducible debug-template runner.
- Packaging retains explicit parent-first ZIP directories. No APK/EXE exported.

All entries below describe earlier versions, not current test execution.

# v0.9.2 — RENDER FIX

- Fixed nearest-sampled stroke loss at 4px using native area-prefiltered glyphs.
- Replaced density × ink double-darkening with coverage-aware cell reconstruction.
- Added Surface tone; calm backgrounds now adjust contrast, not mean luminance.
- More neutral ambient/moon/material palette; depth contours opt-in on all platforms.
- Graphics panel no longer dims the world; paused PREVIEW and quick render reset.
- One-time schema4 render migration with backup; audio/control/archive preserved.
- Quality presets keep art preferences; manual budget differences display CUSTOM.
- Added actual translated GLSL pixel execution via Mesa: 97 cases passed.
- 56 Python/source regressions passed; native Godot checks remain NOT RUN.
- Kept the parent-first ZIP directory fix and all gameplay systems.

# v0.9.1 — Mobile Clarity

- Separate glyph density from ink brightness; reduce flat-midtone clutter, retain local boundaries/highlights. Added independent background calm and color saturation controls.
- Brighter actor fill/edge treatment while retaining normal depth testing and the world ASCII pass.
- Replaced full-screen red damage wash with a 220 ms real-time peripheral vignette; the center stays clear.
- Rebuilt mobile controls around a shared geometry helper: circular analog stick, FIRE-drag look, AIM toggle, dash cooldown, configurable scale/sensitivity and input reset on pause/focus loss/death/settings/scene exit.
- Filtered mobile combat mouse bindings by physical device so touch-to-mouse UI emulation does not double-trigger shooting; native menu emulation remains enabled.
- Moved mobile HUD out of thumb regions; relic details are accessible from SET. PC HUD retained.
- Added shoulder-to-muzzle and muzzle-to-target obstruction sampling with blocked-shot feedback. SpringArm now owns the shoulder offset and excludes the player collider.
- Added opt-in 120-sample frame cadence / P95 overlay; no measured performance gain claimed.
- Added a separate no-progression ReadabilityLab with three fixed respawning targets, dark/bright/midtone backgrounds, cover and a ramp. Entry ends the current run, returning starts a new one. Archive unaffected.
- Retained music, references, story, combat data and existing city/animation systems.
- Added 23 Python source/reference tests (42 total) and an optional actual Godot courtyard/touch/physics test. Actual Godot execution and device/GPU checks remain NOT RUN in the build environment.

# v0.9 — READABILITY & MOTION

- Corrected sky-less ambient source; adjusted surface values and decorative emission.
- Replaced 16-glyph atlas with 32 hand-authored glyphs and cell averaging / midtone mapping.
- Added optional same-viewport depth contours and actor rim-material treatment.
- Corrected player feet/hip/collider proportions; rounded limb meshes; two-bone procedural feet/hands.
- Added ground sampling on physics ticks, planted/swing feet, distance-based gait, moderated camera motion.
- Preserved analog joystick strength; added RMB aiming stabilization and outlined reticle.
- Added independent persistent readability controls and a scrollable settings menu without sync-signal feedback.
- Added chunked MultiMesh facade/street details, shelters, and one collidable service walkway with two ramps.
- Fixed exact-zero first-wave bug, district cancellation and bounded local encounter budgets.
- Added ordinary-enemy return-to-home behavior when the player leaves far enough.
- Preserved weapons, relics, boss phases, artifact archive, touch controls and existing audio.
- Added 19 source/numerical Python checks and a real-engine smoke runner (not executed here).
- No APK/EXE, runtime verification or FPS guarantee is claimed.

# v0.8.1 — READABILITY & FAIRNESS PASS

- Real-playtest HUD anchoring fix.
- Brighter ASCII midtones and player readability.
- Softer first encounters and enemy materialization grace.
- Reticle no longer draws through end-of-run panels.
- Reduced fog and stronger local forward illumination.

# v0.8 World & Control Pass

- Added persistent graphics/audio/control settings through `SettingsManager`.
- Added ESC/SET in-game settings menu with Low/Medium/High/Ultra presets.
- Added runtime 3D render scale, ASCII cell size/bloom, world lighting, shadow, sensitivity, music and SFX controls.
- Added dynamic reticle with spread, movement, airborne/dash expansion, hit marker and critical marker feedback.
- Reworked player movement with acceleration/deceleration, air-control separation, coyote time, jump buffer and variable jump height.
- Improved third-person aiming using a camera-center aim point resolved from the weapon muzzle.
- Added procedural body/weapon inertia and preserved the shoulder camera baseline during animation.
- Expanded the playable city from roughly 72×72 to 164×164 world units (~5.2× area).
- Added six remote named districts, large road grid, emissive architecture, district consoles/pylons, extended lighting and outer skyline.
- Replaced always-on ambient spawning with visit-driven `EncounterDirector` pacing; Arrival Node begins quiet, district discovery starts combat, and teleporter events override the director.
- Added more player and enemy geometry while reusing low-cost primitive resources.
- Added original ambient music `district_signal.wav` and live music/SFX volume control.
- Updated Windows/Android export metadata to v0.8.
- Validator now checks all five autoloads and required v0.8 systems.

# v0.7 Vertical Slice Combat Pass

- Added reusable low-cost world-space `CombatTelegraph` component.
- Melee, ranged, Tank and Bomber attacks now use attack windups instead of instant damage.
- Added stagger interruption for standard enemy windups.
- Added short dash invulnerability window.
- Added `DamageFeedback` component and player damage signal.
- WATCHER now transitions to `PHASE 02 // OVERWRITE` at 55% health.
- Added telegraphed fan/radial attacks and FIELD COLLAPSE boss slam.
- Added boss phase signal/event and boss-phase HUD state.
- Added second persistent Reality Archive fragment after WATCHER death: `WOODEN TOY // WHEELED OBJECT`.
- Added separate true-3D inspection representation and story text for the second fragment.
- Added lightweight procedural sound assets and pooled `AudioManager`.
- Added wet street patches, illuminated storefronts, transit arch, utility props and road details.
- Increased ambient/glyph/forward-light readability while retaining the night-city target.
- Added antenna, side-panel and knee geometry to enemy silhouettes.
- Strengthened package validation with scene parent-order checks, scene-node path checks and a fourth required autoload.

# v0.6 Architecture Foundation

- Added `GameEvents`, `PoolManager`, and `RuntimeProfile` autoload services.
- Added data-driven `WeaponData`, `EnemyData`, and `ItemData` resources.
- Added `WeaponController` and `InventoryComponent` to the Player scene.
- Removed hard-coded weapon stat match blocks from `player.gd`; weapon tuning now comes from `.tres` resources.
- Removed hard-coded enemy base-stat match blocks from `enemy.gd`; archetype tuning now comes from `.tres` resources before difficulty/elite scaling.
- Added object pooling for enemy projectiles and player tracers.
- Enemy projectile material is reused across pooled shots rather than duplicated on every spawn.
- Centralized PC/Android budgets for enemy count, spawn interval, ASCII cell size, bloom, edge gain, glyph gain, shadows, forward light and hit-stop.
- Added typed architecture fields and a stronger package validator covering autoloads, `.tres` files, `class_name` collisions, architecture typing and pooling hooks.
- Added `docs/CODE_STANDARD.md` and `docs/ARCHITECTURE_v0_6.md`.
- Preserved the v0.5 combat, lighting, city, boss, story and Android feature set.

# v0.5 Combat + City Pass

- Added Pulse Rifle, Scatter Driver and Arc Carbine with desktop and Android weapon switching.
- Added weapon-specific recoil, spread, fire rates, tracers and silhouettes.
- Added hit-stop, stronger camera impulse, stagger/knockback, ASCII hit impacts, melee slash glyphs and dash trails.
- Brightened the night scene without abandoning the dark ASCII visual target: stronger ambient fill, reduced fog, brighter emissives, forward player light and controlled bloom.
- Expanded the procedural city with sidewalks, luminous curbs, abandoned vehicles, benches, bollards, signs, data beacons and overhead cables.
- Added enemy chest armor, shoulders, weapons, back modules, eyes and archetype-specific silhouette differences.
- Added WATCHER armor/eye/back-fin detail and brighter core presentation.
- Limited dynamic enemy lights to important silhouettes so the added detail remains practical on PC and Android.
- Expanded project validation to verify input actions and `.tscn` load-step counts in addition to resource references and compatibility rules.

# v0.4 Animation Pass

- Rebuilt player visual as an articulated procedural humanoid.
- Added idle, run, strafe, jump/fall, landing, dash, recoil, hit and death motion.
- Added camera bob, speed FOV and muzzle flash.
- Added animated enemy legs/arms and archetype-weighted locomotion.
- Added animated WATCHER locomotion, attacks and core pulse.
- No external animation assets required; Android-friendly transform animation only.

# Changelog

## v0.3.3 — Godot 4.x compatibility pass

- Removed inferred `:=` declarations across **all 12 GDScript files** so dynamically typed scene nodes cannot trigger repeated “Cannot infer type” parser failures.
- Explicitly typed the reported `center`, `spawn_position`, and interaction `distance` values in `game.gd`.
- Preserved the v0.3.2 `ready` → `exit_ready` teleporter fix.
- Added packaging checks that reject any remaining `:=` declarations and accidental `var ready` collisions.
- No gameplay, balance, story, or ASCII visual target was changed by this hotfix.

## v0.3.2 — native member collision hotfix

- Renamed the teleporter state variable `ready` to `exit_ready` so it does not collide with Node's native `ready` member.

## v0.3.1 — parser hotfix

- Typed enemy/boss target vectors and distances explicitly where values came from dynamically resolved nodes.


## v0.3 — Reality Fragment

- Locked the far-future digitized-world premise into the project bible.
- Added `StoryDirector` and persistent Reality Archive.
- Added first rare story artifact: `PHOTOGRAPH // FAMILY IN SUNLIGHT`.
- Added a true-3D artifact inspection viewport rendered after the ASCII layer.
- Added persistent fragment save at `user://ascii_rain_profile.cfg`.
- Added Android touch movement, camera, fire, jump, dash and interaction controls.
- Added automatic Android/iOS performance profile: 7 px glyph cells, lower enemy cap, reduced post-effect cost, main shadow disabled.
- Added Windows and Android export presets.
- Kept the v0.2 combat loop, relic system, teleporter and WATCHER boss intact.

## v0.2 — Combat Loop

- Five enemy archetypes and elite modifiers.
- Enemy projectiles.
- Credits and caches.
- Twelve stackable combat relics.
- Teleporter event and WATCHER boss.
- Expanded night-city arena and ASCII combat effects.

## v0.7.1 parser hotfix
- Fixed the parser cascade at `city_generator.gd:606` by renaming the local variable `signal` to `gate_signal`. `signal` is a reserved GDScript keyword.
- Added `tools/static_gdscript_guard.py` to catch reserved identifiers in variables, function names, loop variables and parameters before packaging.
- The guard also rejects `:=` declarations under this project's compatibility standard.
