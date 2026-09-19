# v0.9.2: surface tone and native glyph sampling

## Evidence and scope

The playtest images show sparse blue glyph strokes, weak surface solidity and
strong world dimming behind the settings panel. This patch fixes identifiable
shader/settings causes. It does NOT prove that all readability issues or the
visual distance to the approved reference have been solved.

The original 32-glyph atlas uses 6×9 tiles (5×7 ink plus padding). Sampling it
with nearest filtering into 4×6 output cells skips entire source rows. In the
original atlas the horizontal dash loses all ink at that sampling phase.
The original shader also combined reduced density with reduced ink brightness.
In a Mesa replay of the original fragment at the screenshot's settings, neutral
input 0.10 produced mean output 0.02972529; input 0.20 produced 0.02047744.
This is a non-monotonic transfer: a brighter source becomes a darker cell.
The old menu shade alpha was 0.88, independently darkening the preview world.

## Native-size atlas generation

`tools/build_glyph_atlases.py` area-integrates each original tile independently
into widths 4..10, with height floor(width*1.5+0.5). Quantized coverage is measured
from the resulting pixels and packed into a 16-bit RG lookup image. The
original ASCII alphabet and atlas are preserved. No font files are included.

`rendering/ascii_atlas_binding.gd` loads native masks plus coverage for both Main
and ReadabilityLab. Pixel-center sampling prevents bleeding into adjacent glyphs.
These PNGs are data masks, not sRGB colors; samplers intentionally lack source_color.

## Cell reconstruction

The scene is sampled to one color per cell. From target channel T, actual mean
ink coverage A and requested background ratio B:

    ink = min(T * (1 - (1-A)*B) / A, 1)
    background = max((T - ink*A)/(1-A), 0)
    output = mix(background, ink, glyph_mask)

Consequently the cell mean remains T even if ink clips at 1. The glyph choice,
contrast and background fill do not multiply the mean brightness a second time.
A nonzero per-cell bed makes shadowed surfaces more continuous without copying
the full-resolution scene underneath. It is deliberately still ASCII rendering,
not conventional 3D with a transparent text overlay.

The neutral tone curve, desaturated shadows and reduced global blue fill should
separate form from emissive accents. Warm lights retain their hue. Small stable
variations only choose between near-equal glyph coverage; no TIME-based flicker.
Optional full-scene depth contours are off on both PC and mobile by default.
Normals/roughness buffers are not required by this shader.

## Settings and preview

Schema 4 reads old settings, saves the old config once, and migrates only tone,
glyph spacing and edge parameters. Controls/audio, render budget, render scale,
shadow preference and Reality Archive are not reset. Application name is unchanged
so opening a new source folder keeps the same user:// save location.
The panel is opaque locally; no dimmer covers the rest of the world. Preview
hides only the panel and never resumes combat. UI input still blocks the game.
High and Ultra currently use the same 1.0 scale/6px/shadow defaults; these are
budget labels, not an assertion of different production asset quality.

## Validation boundaries

56 Python regressions include native atlas coverage, the missing-dash regression,
material binding, versioned settings, source contracts and cell-mean algebra.
`tools/test_canvas_pixels.py` executes a translated fragment with software Mesa
OpenGL via EGL. 70 tone/width cases and 27 contrast cases passed pixel assertions.
The fixture of the previous shader is retained as plain text only for regression.

This GLSL translation is NOT Godot shader import, Godot's framebuffer/color-space
integration, a physical GPU benchmark, or a game screenshot. Shader-language
hints are stripped and screen built-ins emulated for this isolated test.

Offscreen old/new images, when included in build/, process the same raw-3D frame
from an older playtest video. They are NOT captured renders of this v0.9.2 city;
new scene lighting/material/actor changes cannot be demonstrated by that replay.

## Next on-device checks

Compare the same viewpoint without the menu; test width4 and width6, PREVIEW
pause, F1 raw/ASCII, dark wall + player, small moving projectiles, and mobile8px.
Check old audio/control settings and archive survive; check old render settings
have a backup. Test both Compatibility and the user's chosen renderer before
claiming renderer parity. No guaranteed performance improvement is claimed.
