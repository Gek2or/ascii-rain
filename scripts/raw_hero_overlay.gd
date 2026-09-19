extends CanvasLayer
## Draws the hero after the ASCII canvas pass while retaining camera occlusion.

const WORLD_LAYER: int = 1
const HERO_LAYER: int = 2
const OCCLUSION_POLL_SECONDS: float = 0.08
const OCCLUSION_CONFIRM_SAMPLES: int = 2

@onready var _player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var _container: SubViewportContainer = $HeroViewportContainer as SubViewportContainer
@onready var _viewport: SubViewport = $HeroViewportContainer/HeroViewport as SubViewport
@onready var _hero_camera: Camera3D = $HeroViewportContainer/HeroViewport/HeroCamera as Camera3D

var _world_camera: Camera3D
var _render_targets: Array[VisualInstance3D] = []
var _occlusion_time: float = 0.0
var _blocked_samples: int = 0
var _clear_samples: int = 0
var _raw_pass_active: bool = true

func _ready() -> void:
    process_priority = 100
    _world_camera = _player.get_node("CameraPivot/SpringArm3D/Camera3D") as Camera3D
    _viewport.world_3d = get_viewport().world_3d
    _hero_camera.cull_mask = HERO_LAYER
    _configure_camera()
    _collect_targets(_player.get_node("Entity01Bridge/Entity01Visual"))
    _collect_targets(_player.get_node("Visual/WeaponPivot"))
    _set_raw_pass(true)
    _include_hero_in_lights(get_tree().root)
    get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
    var active_camera: Camera3D = get_viewport().get_camera_3d()
    if active_camera != null and active_camera != _world_camera:
        _world_camera = active_camera
        _configure_camera()
        _world_camera.cull_mask = (_world_camera.cull_mask | WORLD_LAYER) & ~HERO_LAYER
    if not is_instance_valid(_world_camera):
        return
    _hero_camera.global_transform = _world_camera.global_transform
    _hero_camera.fov = _world_camera.fov
    _occlusion_time += delta
    if _occlusion_time < OCCLUSION_POLL_SECONDS:
        return
    _occlusion_time = 0.0
    _update_occlusion_state()

func _configure_camera() -> void:
    _hero_camera.projection = _world_camera.projection
    _hero_camera.fov = _world_camera.fov
    _hero_camera.size = _world_camera.size
    _hero_camera.frustum_offset = _world_camera.frustum_offset
    _hero_camera.h_offset = _world_camera.h_offset
    _hero_camera.v_offset = _world_camera.v_offset
    _hero_camera.near = _world_camera.near
    _hero_camera.far = _world_camera.far
    _hero_camera.keep_aspect = _world_camera.keep_aspect
    _hero_camera.attributes = _world_camera.attributes
    _hero_camera.environment = _world_camera.environment

func _collect_targets(node: Node) -> void:
    if node is VisualInstance3D:
        var visual: VisualInstance3D = node as VisualInstance3D
        _render_targets.append(visual)
        visual.layers = HERO_LAYER
    for child: Node in node.get_children():
        _collect_targets(child)

func _update_occlusion_state() -> void:
    var camera_origin: Vector3 = _world_camera.global_position
    var sample_points: Array[Vector3] = [
        _player.global_position + Vector3.UP * 0.72,
        _player.global_position + Vector3.UP * 1.28,
        _player.global_position + Vector3.UP * 1.88
    ]
    var blocked: bool = false
    var excluded: Array[RID] = [_player.get_rid()]
    var space_state: PhysicsDirectSpaceState3D = _player.get_world_3d().direct_space_state
    for sample_point: Vector3 in sample_points:
        var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
            camera_origin,
            sample_point,
            WORLD_LAYER,
            excluded
        )
        query.hit_from_inside = true
        if not space_state.intersect_ray(query).is_empty():
            blocked = true
            break

    if blocked:
        _blocked_samples += 1
        _clear_samples = 0
        if _blocked_samples >= OCCLUSION_CONFIRM_SAMPLES and _raw_pass_active:
            _set_raw_pass(false)
    else:
        _clear_samples += 1
        _blocked_samples = 0
        if _clear_samples >= OCCLUSION_CONFIRM_SAMPLES and not _raw_pass_active:
            _set_raw_pass(true)

func _set_raw_pass(enabled: bool) -> void:
    _raw_pass_active = enabled
    _container.visible = enabled
    var target_layer: int = HERO_LAYER if enabled else WORLD_LAYER
    for visual: VisualInstance3D in _render_targets:
        if is_instance_valid(visual):
            visual.layers = target_layer
    _world_camera.cull_mask = (_world_camera.cull_mask | WORLD_LAYER) & ~HERO_LAYER

func _include_hero_in_lights(node: Node) -> void:
    if node is Light3D:
        var light: Light3D = node as Light3D
        light.light_cull_mask |= HERO_LAYER
    for child: Node in node.get_children():
        _include_hero_in_lights(child)

func _on_node_added(node: Node) -> void:
    if node is Light3D:
        var light: Light3D = node as Light3D
        light.light_cull_mask |= HERO_LAYER
