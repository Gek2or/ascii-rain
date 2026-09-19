extends RefCounted
# Legacy-only lookup retained for native A/B tests, not the game renderer.
const COVERAGES: Array[Texture2D] = [
    preload("res://assets/ascii_prefiltered/coverage_4.png"),
    preload("res://assets/ascii_prefiltered/coverage_5.png"),
    preload("res://assets/ascii_prefiltered/coverage_6.png"),
    preload("res://assets/ascii_prefiltered/coverage_7.png"),
    preload("res://assets/ascii_prefiltered/coverage_8.png"),
    preload("res://assets/ascii_prefiltered/coverage_9.png"),
    preload("res://assets/ascii_prefiltered/coverage_10.png")
]

static func apply(material: ShaderMaterial, width: int) -> void:
    material.set_shader_parameter("coverage_atlas", COVERAGES[clampi(width, 4, 10) - 4])
