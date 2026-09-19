class_name RainEntityVisual
extends Node3D
## Standalone visual: no camera, collision, movement, or dependencies on game code.
## All eight skeletal clips and both morphs are baked into the GLB.

signal clip_finished(clip_name: StringName)

const FULL_MODEL: PackedScene = preload("res://models/Entity01.glb")
const LITE_MODEL: PackedScene = preload("res://models/Entity01_Lite.glb")
const CODE_SHADER: Shader = preload("res://godot/character/living_code.gdshader")
const BODY_SHADER: Shader = preload("res://godot/character/void_body.gdshader")
const CODE_ATLAS: Texture2D = preload("res://textures/code_atlas.png")

@export var use_lite_model: bool = false
@export var use_animated_materials: bool = true
@export var auto_play: bool = true
@export_range(0.0, 8.0, 0.1) var code_energy: float = 0.45

var _model: Node3D
var _player: AnimationPlayer
var _meshes: Array[MeshInstance3D] = []
var _shader_materials: Array[ShaderMaterial] = []
var _clips: Dictionary = {}
var _current: StringName = &""
var _base_clip: StringName = &"Hover_Idle"
var _one_shot: bool = false
var _moving: bool = false

func _ready() -> void:
    _build_model()

func _build_model() -> void:
    if is_instance_valid(_model):
        remove_child(_model)
        _model.queue_free()
    _meshes.clear()
    _shader_materials.clear()
    _clips.clear()
    _player = null
    _current = &""
    var packed: PackedScene = LITE_MODEL if use_lite_model else FULL_MODEL
    _model = packed.instantiate() as Node3D
    if _model == null:
        push_error("Entity01: GLB did not instantiate as Node3D.")
        return
    add_child(_model)
    _collect_nodes(_model)
    if _player == null:
        push_error("Entity01: imported GLB has no AnimationPlayer. Check import animations setting.")
        return
    for key: StringName in _player.get_animation_list():
        var short_name: StringName = StringName(String(key).get_file())
        _clips[short_name] = key
        var clip: Animation = _player.get_animation(key)
        if short_name == &"Hover_Idle" or short_name == &"Glide_Loop" or short_name == &"Glide":
            clip.loop_mode = Animation.LOOP_LINEAR
        else:
            clip.loop_mode = Animation.LOOP_NONE
    if _clips.has(&"Glide") and not _clips.has(&"Glide_Loop"):
        _clips[&"Glide_Loop"] = _clips[&"Glide"]
    _player.animation_finished.connect(_on_animation_finished)
    if use_animated_materials:
        _install_materials()
    if auto_play:
        play_clip(_base_clip, 0.0)

func _collect_nodes(node: Node) -> void:
    if node is AnimationPlayer:
        _player = node as AnimationPlayer
    if node is MeshInstance3D:
        _meshes.append(node as MeshInstance3D)
    for child: Node in node.get_children():
        _collect_nodes(child)

func _install_materials() -> void:
    for mesh_node: MeshInstance3D in _meshes:
        if mesh_node.mesh == null:
            continue
        for i: int in range(mesh_node.mesh.get_surface_count()):
            var original: Material = mesh_node.get_active_material(i)
            if original == null:
                continue
            var material_name: String = original.resource_name
            if material_name.contains("Living_Code"):
                var code_material: ShaderMaterial = ShaderMaterial.new()
                code_material.shader = CODE_SHADER
                code_material.set_shader_parameter("glyph_atlas", CODE_ATLAS)
                code_material.set_shader_parameter("emission_energy", code_energy)
                code_material.set_shader_parameter("code_tint", Color(0.12, 0.50, 0.58, 1.0))
                code_material.set_shader_parameter("color_bleed", 0.10)
                code_material.set_shader_parameter("animate_symbols", not use_lite_model)
                mesh_node.set_surface_override_material(i, code_material)
                _shader_materials.append(code_material)
            elif material_name.contains("Void_Silhouette"):
                var body_material: ShaderMaterial = ShaderMaterial.new()
                body_material.shader = BODY_SHADER
                body_material.set_shader_parameter("fragmentation", 0.04 if use_lite_model else 0.08)
                mesh_node.set_surface_override_material(i, body_material)
                _shader_materials.append(body_material)

func _process(_delta: float) -> void:
    var echo_value: float = 0.0
    var disperse_value: float = 0.0
    for mesh_node: MeshInstance3D in _meshes:
        var echo_index: int = mesh_node.find_blend_shape_by_name("Human_Echo")
        if echo_index >= 0:
            echo_value = mesh_node.get_blend_shape_value(echo_index)
        var disperse_index: int = mesh_node.find_blend_shape_by_name("Disperse")
        if disperse_index >= 0:
            disperse_value = mesh_node.get_blend_shape_value(disperse_index)
    for material: ShaderMaterial in _shader_materials:
        material.set_shader_parameter("human_echo", echo_value)
        material.set_shader_parameter("disperse", disperse_value)

func available_clips() -> Array[StringName]:
    var names: Array[StringName] = []
    for key: Variant in _clips.keys():
        names.append(StringName(key))
    return names

func play_clip(clip_name: StringName, blend_time: float = 0.14) -> bool:
    if _player == null or not _clips.has(clip_name):
        push_warning("Entity01: missing animation '%s'." % String(clip_name))
        return false
    visible = true
    _current = clip_name
    _one_shot = clip_name != &"Hover_Idle" and clip_name != &"Glide_Loop"
    var actual: StringName = StringName(_clips[clip_name])
    _player.play(actual, blend_time)
    return true

func set_moving(value: bool) -> void:
    if _moving == value:
        return
    _moving = value
    _base_clip = &"Glide_Loop" if value else &"Hover_Idle"
    if not _one_shot:
        play_clip(_base_clip)

func _on_animation_finished(_actual_name: StringName) -> void:
    var completed: StringName = _current
    clip_finished.emit(completed)
    _one_shot = false
    if completed == &"Dissolve":
        visible = false
        return
    play_clip(_base_clip, 0.18)

func set_lite_profile(value: bool) -> void:
    if value == use_lite_model:
        return
    use_lite_model = value
    _build_model()
