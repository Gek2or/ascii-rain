# ASCII//RAIN v0.13 — Reference City & District Events

Cumulative source-project release based on v0.12b. Not an APK or EXE. This release
implements the visual-recovery pass, Utility Depths, Rooftop Relay and optional
local encounters. It does not restart the project or replace it with a web demo.

## Opening the project

Extract the ZIP into a NEW folder, then import the extracted `project.godot` in
Godot and run Main with F5. The archive contains explicit parent-first directory
records, so the earlier missing-folder ZIP problem is covered by the packager.
Windows and Android presets are included, but neither executable export is built.

The game remains a third-person 3D simulation through a real ASCII shader.
Normal gameplay, movement, touch input, animation, weapons, existing four authored
districts, audio tracks, relics and two persistent story artifacts remain in place.

## Visual recovery: what actually changed

One stable glyph is chosen per cell; adjacent glyph identities are not blended.
Flat walls use punctuation/rings instead of long scanlines or a random alphabet.
Long bars are reserved for strong image-space edges. Native-size atlases for 4–10
pixels remain in use. The new gap floor is 1.5–26% of the reconstructed tone,
rather than the old 44–76%; dark negative space is part of the image again.
A bounded nonlinear tone curve keeps dim glyphs readable without a full-size 3D
image being composited behind them. Bright local samples receive limited weight.

ESC / SET -> VISUAL STYLE offers Reference Mood, Readable Combat and Mobile Safe.
Quality presets remain independent of tone choices. Reference Mood defaults to
6px and full resolution on desktop; Mobile Safe uses 8px / 0.78 scale and no
shadows. Physical-device performance is not established by those defaults.

Graphics preferences from schema 4 migrate ONCE, with a backup at
`user://ascii_rain_settings_before_0_13.cfg`. Mouse/touch sensitivity, audio,
ambience and the separate reality archive are not reset. New-schema adjustments
survive reloads. Application/save identity is not renamed by this package.

The player's torso/shoulders/limbs are broader, its base material darker and its
back light wider. Edge lighting is separate from uniform surface fill. Existing
procedural locomotion and weapon handling remain; this is not a new skeletal rig.
Market receives a taller stepped facade on its existing wall footprints, selected
warm windows, cornices and frontage lights. This is a pilot frontage treatment,
not a replacement of every building and not an asserted match to generated art.

## Six authored districts

Market Ruins, Transit Spine, Archive Stacks and Memory Gardens retain their v0.12b
layouts. New additions:

### Utility Depths

A real lower floor at -6m under the north-west service area. Two cuts are applied
to BOTH visible street geometry and collision. South entrance is near (-66,0,12),
north entrance near (-42,0,-45). Both ramps meet the street without a falling gap.
There is a wide pressure hall, tanks, power cabinets, overhead pipes, a rotor and
warm fixtures. Two existing caches are relocated below; they are not extra loot.

### Rooftop Relay

Three linked roof sections at +10m around the north courtyard, joined at the back.
West ascent starts near (-29,0,-23), east ascent near (25.5,0,-23). The east route
is offset to avoid the pre-existing archive wall. Both ascents and the connecting
walkway are continuous, without required jumps. Cover, a mast, shelter, antennas
and two relocated existing caches provide landmarks. The arena remains below;
opaque screens block common roof-to-arena firing angles. This is not a claim that
every possible player-created boss exploit has been eliminated.

The existing layered A* graph now includes below-street surfaces as well as roofs.
Floor identity is derived from physical support, not merely from actor Y. Traversing
levels retains the parent district's discovery and threat. Basement/roof spawns
use authored supported anchors, without falling back to an unrelated ground floor.
The objective guide supplies an ascent from Utility and descent from roofs when
its destination is at street level. No new teleport movement is used by AI.

## District combat and local activities

Each of the six districts has its own enemy composition using the existing five
archetypes. Utility avoids Bombers/Tanks in its corridors; roofs favour ranged
opponents; Gardens favour fast enemies. Early ambient encounters still restrict
enemy types. Upper gallery compositions exclude unsuitable heavy/explosive units.

Six OPTIONAL consoles, one per district, offer variations of a shared defense
activity. They are not six completely unrelated minigames:

| District | Console | Completion credits |
| --- | --- | ---: |
| Market | Reclaim the Ledger | 45 |
| Transit | Restore Platform Signal | 55 |
| Archives | Recover the Missing Index | 50 |
| Gardens | Restart the Climate Cycle | 50 |
| Utility | Purge Pressure Lock | 60 |
| Roofs | Calibrate the Lost Carrier | 65 |

E / USE starts a four-second warning, then a 20-second synchronization with two
composition-specific waves. Remaining defenders must be cleared, and a separate
interaction claims the reward. A minimum of three successfully spawned defenders
is required. Failed placement cannot grant a free completion. Repeat interactions
cannot reset the event or duplicate credits. Credits and 25 XP are paid once per
run. Starting costs nothing; the event does not create permanent story collectibles.

Only one local activity can run at a time. Ordinary ambient waves stop during it.
Leaving its district/radius for more than eight seconds, dying or starting the
teleporter battle aborts it without the completion reward. Already spawned enemies
are not silently removed during combat. Pause stops timers and telegraphed hazards.
Utility adds two delayed pressure vents in side bays, not across both exits.

Existing autonomous drone/train/archive courier/irrigation remain. The rotor and
roof antenna animate nearby. Existing sound loops are reused spatially in the new
areas, with finite range and ducking during local activity. No new song, recorded
voice or human NPC population is claimed.

The main run remains: starter relic -> any two districts -> teleporter / WATCHER
-> optional real object -> exit. Local activities are optional detours, not six
mandatory chores. The city and ordinary props never turn into unfiltered 3D.

## Test scope

See `build/RELEASE_REPORT.txt` and individual logs. Native tests execute GDScript,
physics and shaders using a trusted Godot 4.8 dev Linux DEBUG EXPORT TEMPLATE,
Mesa software OpenGL and Xvfb. PNG/WAV resources are serialized in a temporary QA
copy because the editor's .NET runtime is unavailable. This is not normal editor
import, not stable 4.7/4.3 validation and not hardware Android/Windows testing.

Fixtures deliberately place actors and force certain wave completions/state timer
steps. They establish logic, not human difficulty, animation quality or FPS.
Player/chaser ramp traversals use real movement between initial placement and the
measured destination; no intermediate teleport is used in these traversal tests.
Captures are real-engine output with deliberately placed cameras, not generated
art and not a record of an ordinary human run.

Current commands:

```sh
python tools/static_gdscript_guard.py .
python tools/validate_project.py
python -m unittest discover -s tests -p test_v013.py -v
xvfb-run -a python tools/run_debug_template_checks.py --template /trusted/godot_debug_template --render --timeout 260
python tools/package_project.py pack . /output/ASCII_RAIN_Godot_v0_13_REFERENCE_CITY.zip
```

Historical release-specific source/hash tests remain available for reference;
several assert the *old* render formula and cannot be treated as current v0.13
contracts. Current native gameplay regressions are reused; new pixel invariants
are in `reference_glyph_test.gd`, replacing the old grey-bed/noise target.

## Remaining limitations

No APK/EXE export/signing, normal stable editor import, physical GPU/touch test,
phone thermal/memory benchmark or human balance certification in this release.
No ladders, lifts, fully traversable interiors for every building, streaming open
world, complete crowd avoidance or distinct navigation meshes per body size.
WATCHER retains its arena controller. Animation remains procedural; geometry and
lighting still need human visual tuning against the approved reference.
