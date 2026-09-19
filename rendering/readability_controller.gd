extends Node

const DEPTH_SHADER: Shader = preload("res://shaders/depth_contours.gdshader")
const ACTOR_STYLE = preload("res://rendering/actor_readability.gd")
var _quad: MeshInstance3D = null
var _material: ShaderMaterial = null
var _enabled: bool = true

func configure(camera: Camera3D) -> void:
    if camera == null:
        return
    _quad = MeshInstance3D.new()
    _quad.name = "DepthContours"
    var quad_mesh: QuadMesh = QuadMesh.new()
    quad_mesh.size = Vector2(2.0, 2.0)
    _quad.mesh = quad_mesh
    _quad.extra_cull_margin = 16384.0
    _quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _quad.position = Vector3(0.0, 0.0, -1.0)
    _material = ShaderMaterial.new()
    _material.shader = DEPTH_SHADER
    _material.render_priority = -100
    var rendering_method: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility"))
    _material.set_shader_parameter("compatibility_ndc", rendering_method == "gl_compatibility")
    _quad.material_override = _material
    camera.add_child(_quad)
    SettingsManager.changed.connect(_apply_settings)
    _apply_settings()

func set_effect_enabled(value: bool) -> void:
    _enabled = value
    _apply_settings()

func _apply_settings() -> void:
    ACTOR_STYLE.refresh_strength()
    if _quad == null:
        return
    _quad.visible = _enabled and SettingsManager.depth_contours_enabled
    _material.set_shader_parameter("contour_strength", SettingsManager.readability_strength * 0.66)
    _material.set_shader_parameter("pixel_radius", clampf(SettingsManager.ascii_cell_px * 0.30, 1.0, 3.0))
