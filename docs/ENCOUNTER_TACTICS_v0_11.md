# v0.11 implementation / test scope

## Collision -> route -> warning -> damage

`world/city_collision_pass.gd` makes named/tagged structural source meshes solid
before `StreetNavigation` starts its physics sampling. Existing cover and deck
already have collision. Decorative details/skyline outside the playable border
are not given blanket triangle collision. Tag insertion does not change RNG,
geometry or materials, verified by removing only those metadata lines and comparing
the complete original generator's digest.

`StreetNavigation` samples a 2.5-unit grid after two physics synchronisation ticks.
Nodes need an upward-facing surface at -0.8..3.6 units and a capsule-sized clear
volume. Edges require a clear capsule sweep and sampled support. Diagonal corner
cuts are prohibited. Once baked, connected-component IDs support spawn filtering.
A* is capped at 4 requests/physics frame on desktop, 2 under RuntimeProfile mobile.
Both node and edge construction are bounded per tick. This is a single-surface
street solution; a multi-floor navmesh is a separate future feature.

`EnemyNavigation` retains an actor-local route, refreshes when the goal moves,
projects airborne goals to a street node, checks nearby supported shortcuts and
waits if the shared query budget is busy. No valid path means stop/retry, not warp.
Body movement remains native CharacterBody3D `move_and_slide`, floor snapping and
gravity. Rotating the body does not rotate the locked aim point or hit cone.

`CombatSight` checks world layer 1. Live enemies are not cover. Melee also checks
3D distance, a height bound, and the advertised forward cone. Gunner/Tank warnings
are actual world-space beams to the locked point. Strong stagger clears their cue
handle. Bomber/Volatile warnings have time to evade; delayed hazards are ordinary
pauseable scene nodes and are removed by the existing end-of-combat path.

`EnemyProjectile` tests its central movement segment on layers 1|2 before advancing.
Native Area overlap handles slower/grazing contacts. This is intentionally not
advertised as a full swept-sphere CCD implementation. Both routes share the
single recycle/damage guard and preserve pooling.

## Tests that must pass

`encounter_tactics_test.gd`: independent physical test world, native graph build,
clearance edges, agent walking around a wall, agent climbing a ramp to a deck,
shared request cap, blocking LOS, committed gunner aim, melee cone and wall checks,
stagger cancellation, bomber cover, delayed/pauseable volatile damage, very fast
centre-ray crossing a 4-cm wall, pooled projectile reuse and duplicate callback.

`city_navigation_test.gd`: actual Main scene, physics collision pass, routes from
Arrival to all named districts, reachable spawned/scaled colliders, and hostile
hazard/cue cleanup on end of combat. It does not substitute for playing every
alley with every enemy type.

Existing run-state, actual scene/run-loop, controller/menu, synthetic two-finger,
relic-choice and 126 real native canvas pixel tests are re-run. The renderer itself
is byte-identical to v0.10.1. `tactics_capture.gd` arranges actors and freezes their
real cues for a native scene illustration; it is not a human playthrough.

## Relevant engine contracts consulted

AStar3D graph construction/path retrieval:
https://docs.godotengine.org/en/stable/classes/class_astar3d.html
PhysicsDirectSpaceState3D shape overlap, casts, ray queries (cast_motion ignores
initial overlaps, hence the explicit intersect_shape check):
https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate3d.html
CharacterBody3D floor snapping/kinematic movement:
https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html

Native engine/version, commands, outputs and limitations belong in the build
report. No FPS guarantee, final art-quality claim or real-device validation is
inferred from a Linux software-renderer capture.
