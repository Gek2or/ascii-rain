extends MeshInstance3D

var _material: StandardMaterial3D = null
var _box_mesh: BoxMesh = null
var _active_tween: Tween = null
var _recycle_requested: bool = false

func _ready() -> void:
    _box_mesh = BoxMesh.new()
    _box_mesh.size = Vector3(0.035, 0.035, 1.0)
    mesh = _box_mesh

    _material = StandardMaterial3D.new()
    _material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _material.emission_enabled = true
    material_override = _material
    on_pool_spawned()

func on_pool_spawned() -> void:
    _recycle_requested = false
    if _active_tween != null and _active_tween.is_valid():
        _active_tween.kill()
    scale = Vector3.ONE

func on_pool_recycled() -> void:
    if _active_tween != null and _active_tween.is_valid():
        _active_tween.kill()
    _active_tween = null
    _recycle_requested = false

func configure(from: Vector3, to: Vector3, color: Color, duration: float = 0.055) -> void:
    var distance: float = from.distance_to(to)
    if distance <= 0.05:
        _request_recycle()
        return

    if _box_mesh == null or _material == null:
        return

    _box_mesh.size = Vector3(0.035, 0.035, distance)
    _material.albedo_color = color
    _material.emission = color
    _material.emission_energy_multiplier = 5.0

    global_position = (from + to) * 0.5
    look_at(to, Vector3.UP)
    scale = Vector3.ONE

    _active_tween = create_tween()
    _active_tween.tween_property(self, "scale", Vector3(0.25, 0.25, 1.0), maxf(0.02, duration))
    _active_tween.tween_callback(_request_recycle)

func _request_recycle() -> void:
    if _recycle_requested:
        return
    _recycle_requested = true
    PoolManager.call_deferred("recycle", self)
