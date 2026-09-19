extends Node3D

@export var artifact_id = "memory_01"
@export var display_name = "UNINDEXED OBJECT"
@export_multiline var short_hint = "Physical record / format unknown"

var collected = false
var _pulse_time = 0.0
var _core: MeshInstance3D
var _light: OmniLight3D

func _ready() -> void:
    add_to_group("interactables")
    add_to_group("reality_artifacts")
    _build_marker()

func _process(delta: float) -> void:
    if collected:
        return
    _pulse_time += delta
    rotation.y += delta * 0.22
    if is_instance_valid(_light):
        _light.light_energy = 2.2 + sin(_pulse_time * 2.6) * 0.55
    if is_instance_valid(_core):
        var s = 1.0 + sin(_pulse_time * 2.2) * 0.055
        _core.scale = Vector3.ONE * s

func _build_marker() -> void:
    var frame = MeshInstance3D.new()
    var frame_mesh = BoxMesh.new()
    frame_mesh.size = Vector3(0.95, 1.25, 0.10)
    frame.mesh = frame_mesh
    var frame_mat = StandardMaterial3D.new()
    frame_mat.albedo_color = Color(0.018, 0.024, 0.032)
    frame_mat.metallic = 0.72
    frame_mat.roughness = 0.28
    frame.material_override = frame_mat
    frame.position = Vector3(0.0, 1.0, 0.0)
    add_child(frame)

    _core = MeshInstance3D.new()
    var core_mesh = BoxMesh.new()
    core_mesh.size = Vector3(0.62, 0.88, 0.035)
    _core.mesh = core_mesh
    var core_mat = StandardMaterial3D.new()
    core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    core_mat.albedo_color = Color(0.82, 0.94, 1.0)
    core_mat.emission_enabled = true
    core_mat.emission = Color(0.45, 0.78, 1.0)
    core_mat.emission_energy_multiplier = 4.2
    _core.material_override = core_mat
    _core.position = Vector3(0.0, 1.0, -0.07)
    add_child(_core)

    _light = OmniLight3D.new()
    _light.light_color = Color(0.48, 0.78, 1.0)
    _light.light_energy = 2.2
    _light.omni_range = 7.0
    _light.shadow_enabled = false
    _light.position = Vector3(0.0, 1.15, 0.2)
    add_child(_light)

    var base = MeshInstance3D.new()
    var base_mesh = CylinderMesh.new()
    base_mesh.top_radius = 0.62
    base_mesh.bottom_radius = 0.78
    base_mesh.height = 0.12
    base.mesh = base_mesh
    var base_mat = StandardMaterial3D.new()
    base_mat.albedo_color = Color(0.04, 0.055, 0.075)
    base_mat.metallic = 0.5
    base_mat.roughness = 0.45
    base.material_override = base_mat
    base.position = Vector3(0.0, 0.06, 0.0)
    add_child(base)

func get_interaction_text(_player: Node) -> String:
    if collected:
        return ""
    return "[E] EXAMINE ANOMALY   //   NON-DIGITAL SIGNATURE"

func interact(_player: Node) -> void:
    if collected or get_tree().paused or not get_tree().get_nodes_in_group("exclusive_ui").is_empty():
        return
    collected = true
    remove_from_group("interactables")
    var directors = get_tree().get_nodes_in_group("story_director")
    if not directors.is_empty() and directors[0].has_method("present_artifact"):
        directors[0].call("present_artifact", artifact_id, display_name, short_hint)
    queue_free()
