# v0.9 implementation boundaries

The build continues the supplied v0.8.1 project. Narrative, inventory data, weapons and audio assets are retained. No published site or remote repository has been changed.

Rendering: 3D opaque scene → optional additive depth-contour QuadMesh on main Camera3D → canvas ASCII → HUD and unfiltered story inspection. Only depth is sampled in the screen-space contour pass. The actor rim uses its own material NORMAL and VIEW; it does not require a separate normal buffer. Depth projection has an explicit OpenGL vs Vulkan NDC switch.

Animation: named articulated mesh nodes remain in Player.tscn. Limb lengths are 0.46/0.46 (legs), 0.35/0.34 (arms). The analytic solver clamps reach and handles degenerate poles. Feet are ground-sampled on physics ticks. This is not a full-body skeletal animator, navigation system or mocap conversion. Large steps, tight camera corners and extreme aiming pitch require real-engine review.

New city geometry is cosmetic except the service deck/ramps. It is chunked into 24 m cells and batched by material; this reduces node/draw submission count for the additions, but no measured performance improvement is claimed. Existing city geometry is not fully batched or rebuilt. Ground/roof navigation and full interiors are not implemented.

Quality does not overwrite the new independent readability sliders. Old saved controls/audio remain valid. Restoring the v0.9 readability defaults makes comparisons easier without deleting the separate Reality Archive profile.

Reference documentation used for implementation:
```text
https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html
https://docs.godotengine.org/en/stable/classes/class_environment.html
```
