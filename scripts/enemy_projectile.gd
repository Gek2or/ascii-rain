extends Area3D

@export var speed: float = 12.0
@export var damage: float = 10.0
@export var lifetime: float = 6.0

var direction: Vector3 = Vector3.FORWARD
var _life: float = 6.0
var _recycle_requested: bool = false
var _runtime_material: StandardMaterial3D = null

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    var source_material: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
    if source_material != null:
        _runtime_material = source_material.duplicate() as StandardMaterial3D
        mesh_instance.material_override = _runtime_material
    on_pool_spawned()

func on_pool_spawned() -> void:
    add_to_group("hostile_projectiles")
    _life = lifetime
    _recycle_requested = false
    monitoring = true
    monitorable = true
    set_physics_process(true)

func on_pool_recycled() -> void:
    remove_from_group("hostile_projectiles")
    monitoring = false
    monitorable = false
    set_physics_process(false)
    direction = Vector3.FORWARD
    _life = lifetime

func setup(new_direction: Vector3, new_speed: float, new_damage: float, color: Color = Color(1.0, 0.12, 0.04)) -> void:
    direction = new_direction.normalized()
    speed = new_speed
    damage = new_damage
    _life = lifetime
    reset_physics_interpolation()

    if _runtime_material != null:
        _runtime_material.albedo_color = color
        _runtime_material.emission = color
        _runtime_material.emission_energy_multiplier = 5.5

func _physics_process(delta: float) -> void:
    if _recycle_requested:
        return
    var next_position: Vector3 = global_position + direction * speed * delta
    # Continuous centre-segment check catches thin cover even if one physics step
    # crosses it entirely. Area overlap still covers slow/grazing sphere contacts.
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position, next_position, 3)
    query.hit_from_inside = true
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        global_position = hit["position"]
        _on_body_entered(hit.get("collider") as Node)
        return
    global_position = next_position
    _life -= delta
    if _life <= 0.0:
        _request_recycle()

func _on_body_entered(body: Node) -> void:
    if _recycle_requested:
        return
    if body != null and body.has_method("take_damage"):
        body.call("take_damage", damage)
    _request_recycle()

func _request_recycle() -> void:
    if _recycle_requested:
        return
    _recycle_requested = true
    set_physics_process(false)
    PoolManager.call_deferred("recycle", self)
