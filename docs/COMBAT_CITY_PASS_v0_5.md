# v0.5 Combat + City Pass

## Goal

Remove the remaining prototype stiffness before adding more content. The priority is readable combat, more responsive feedback, and a city that feels deliberately authored even though its pieces are generated procedurally.

## Combat pass

The survivor now carries three weapon modes with different rhythms and shapes. Recoil, muzzle light, camera motion, hit-stop, stagger, impact glyphs and dash echoes are deliberately small and short-lived so the game feels faster without making the ASCII screen unreadable.

## Lighting pass

The previous build was too dark in motion. v0.5 raises ambient visibility, reduces fog, strengthens emissive sources and adds a forward player fill light. Darkness remains part of the art direction, but gameplay targets and traversal geometry should now remain legible.

## Environment pass

The city now contains sidewalks, curbs, vehicles, street props, signage, beacons and cables in addition to the existing skyline and plaza. These are low-cost primitive assemblies so they survive the ASCII filter and remain suitable for Android.

## Enemy pass

Enemy types now differ in silhouette and equipment rather than mainly in stats. Dynamic lights are intentionally reserved for elites, bombers, tanks and bosses; regular enemies rely on emissive cores/eyes to avoid excessive light cost.

## Next target

v0.6 should focus on one polished 10–15 minute run: enemy telegraphs, damage readability, one additional boss pattern, a stronger teleporter climax, audio hooks, artifact staging, and performance measurement on an actual Android device.
