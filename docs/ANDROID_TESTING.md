# Android v0.9.1 — device check

Import `project.godot` from a fresh extracted folder in the Android Godot editor,
then run the project. First apply **SET → Restore v0.9.1 clarity defaults**.
Do not clear app storage: the permanent Reality Archive is intentionally retained.

Verify during ordinary play: the world stays ASCII, the player separates from
flat backgrounds, damage does not tint the center, touching MOVE does not fire,
two fingers support movement + FIRE-drag camera, and releasing FIRE does not
release movement. AIM is a toggle; SET, backgrounding the app, and death clear
held inputs. Adjust **Touch button size** / **Touch look sensitivity** separately.
Health is above the thumb zones; combat relics are listed in SET.

For a controlled comparison use **TEST COURTYARD (ends current run)** in SET.
This ends the run but does not erase permanent discoveries. Aim around the
corner cover, compare the three fixed targets against their backgrounds, walk
up the ramp, and press TEST HIT FLASH. RETURN TO CITY starts a new run.

Start with depth contours OFF. The frame-time overlay is optional and reports
actual current frame cadence, not a promised benchmark. Do not infer device
performance from the editor screenshot alone. Re-test both a standalone exported
APK and the Android editor later; no APK is provided in this source ZIP.
