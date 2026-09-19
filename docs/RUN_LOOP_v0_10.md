# v0.10 Run Loop — design and implementation

## Scope

Continue the v0.9.2 project, without replacing its renderer, lighting defaults,
animations or map. This increment connects existing mechanics. It does not add a
second biome, complete navigation mesh, final character rig, or production APK.

## Run state

`RunProgress` is a RefCounted run-local model. Stages: LOADOUT, EXPLORE, LOCATE,
BATTLE, RECOVER, EXIT, COMPLETE, FAILED. Two distinct non-arrival visits plus the
starter claim unlock activation. Visiting districts before claiming the starter
is valid, but does not bypass that claim. Terminal states ignore later events.
Boss-death and charge-complete may arrive in either order. Both are required.
A previously saved toy bypasses RECOVER; a new toy is optional and can be left
behind. Completed combat relics and credits are NOT made permanent.

`RunGuide` bridges existing game/director/portal events to the state and a single
objective marker. It points to a goal, not to enemies, and shows straight-line
bearing/distance, NOT a navigable path. The objective has an opaque backing for
readability against busy glyphs. The marker hides on pause, death and completion.

## Item transaction

`RelicOffers` filters actual InventoryComponent data. Each chest caches its
first offer; cancel does not reroll. Starter choices are deterministic and
mechanically different. Other caches draw up to three unique eligible items.
`RelicChoice` owns a pause while visible. It validates actor, range, item cap,
cache state and credits immediately before a synchronous debit/grant. No await
is permitted in this critical section. Marking the transaction closed before
signals prevents double delivery. Claims are counted by RunGuide, not by price.

Inventory grant now returns null at maximum stack. This prevents repeated stat
application even when someone calls grant_item on an already-capped item.

## Encounters and conclusion

Existing per-district budget pacing stays in place. Requested spawns enter a
bounded queue (24); at most two placement attempts per physics tick, each with
up to ten candidates. World rays find a street surface and a capsule excludes
solid obstructions. Candidates outside map bounds, close to the player or on
high roofs are rejected. This is NOT pathfinding: an enemy can still need better
navigation around complex cover. No fixed horde FPS improvement is claimed.

After boss death the director stops requesting new enemies. Once the field is
charged too, remaining enemies dissolve without death rewards and hostile
projectiles recycle. There is no resumption of ordinary ambient spawning during
artifact recovery. Failure and extraction also stop hostile processing.

## Native defects found during this increment

StoryDirector._ready previously added its inspection CanvasLayer as a sibling
while Main was still setting up children. Native Godot reported add_child failure
and leaked the detached overlay. The layer is now owned by StoryDirector itself.
The hidden artifact viewport uses UPDATE_WHEN_VISIBLE rather than rendering
continuously. Story data, artifact geometry and save path remain unchanged.

Audio initialization called play twice; the duplicate was removed. Explicit
stop_all and teardown are available for clean tests. Original music/SFX bytes
are unchanged.

## Deliberately deferred

12–15 minutes is still a design target, not a measured duration. Automated tests
use teleportation, invulnerability and scripted damage to cover events, not to
measure difficulty. Combat feel, original art fidelity, full navigation and
hardware performance remain real-player test work.
