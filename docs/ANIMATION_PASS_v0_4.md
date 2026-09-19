# ASCII//RAIN v0.4 — Animation Pass

This pass targets the stiff prototype feel without adding heavy external character assets.

## Player
- articulated procedural body: torso, pelvis, head, upper/lower arms, thighs, shins and boots
- idle breathing
- run cycle with independent arms/legs
- strafe lean and forward lean
- jump/fall pose
- landing compression
- dash lean + dynamic FOV
- weapon bob and recoil
- muzzle flash + short local light pulse
- hit reaction
- death collapse
- subtle camera bob and landing feedback

## Enemies
- articulated legs
- speed-dependent walk/run cycle
- arm movement
- attack recoil
- hit reaction
- bomber proximity core pulse
- different movement weight for Skitter and Tank

## WATCHER
- heavy locomotion cycle
- attack anticipation/recoil
- core breathing/pulse
- hit vibration

## Performance
All animation is simple procedural transform animation. No skeletal skinning, imported clips, texture animation or expensive IK is required. This is intentional for Android and fits the ASCII visual language.
