# v0.2 Systems Notes

## Enemy director
The game unlocks enemy archetypes over run time instead of spawning the full roster immediately. Elite probability rises after the early game. During the teleporter event, spawn cadence accelerates and the enemy cap increases.

## Enemy roster
- **Grunt:** baseline melee pressure.
- **Skitter:** low HP, high speed, fast contact attacks.
- **Gunner:** keeps distance and fires projectiles.
- **Bomber:** rushes the player and detonates at close range.
- **Tank:** slow, high HP, fires a three-shot ranged pattern.

## Elites
- **Overcharged:** purple core; faster, harder-hitting, higher attack rate.
- **Volatile:** orange core; tougher and explodes on death.

## WATCHER
WATCHER maintains medium range, fires aimed fan volleys and periodically emits radial projectile rings. Under 50% HP both patterns accelerate.

## Teleporter
Activation starts the boss event. Charge advances only while the player is inside the large field radius. The district exit becomes available when both conditions are met: teleporter charge is 100% and WATCHER is dead.

## ASCII effects
Normal gameplay is rendered through the full-screen glyph post-process. Enemy death additionally emits actual `Label3D` glyph fragments in world space, giving kills a readable character-disintegration effect even before the post-process pass.
