extends RefCounted

# Masks contain linear coverage data, not color. Every tile has exactly the same
# dimensions as a screen cell, including the 4px setting used in the bug report.
const ATLASES: Array[Texture2D] = [
    preload("res://assets/ascii_prefiltered/glyphs_1.png"),
    preload("res://assets/ascii_prefiltered/glyphs_2.png"),
    preload("res://assets/ascii_prefiltered/glyphs_3.png"),
    preload("res://assets/ascii_prefiltered/glyphs_4.png"),
    preload("res://assets/ascii_prefiltered/glyphs_5.png"),
    preload("res://assets/ascii_prefiltered/glyphs_6.png"),
    preload("res://assets/ascii_prefiltered/glyphs_7.png"),
    preload("res://assets/ascii_prefiltered/glyphs_8.png"),
    preload("res://assets/ascii_prefiltered/glyphs_9.png"),
    preload("res://assets/ascii_prefiltered/glyphs_10.png")
]
static func apply(material: ShaderMaterial, width: float) -> void:
    if material == null:
        return
    var cell: int = clampi(int(floor(width + 0.5)), 1, 10)
    material.set_shader_parameter("cell_px", float(cell))
    material.set_shader_parameter("glyph_atlas", ATLASES[cell - 1])
    material.set_shader_parameter("surface_fill", SettingsManager.surface_fill)
