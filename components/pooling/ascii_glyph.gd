extends Node3D

var _label: Label3D = null
var _active_tween: Tween = null
var _recycle_requested: bool = false

func _ready() -> void:
    add_to_group("ascii_glyph")
    _label = $Glyph as Label3D
    on_pool_spawned()

func on_pool_spawned() -> void:
    _recycle_requested = false
    if _active_tween != null and _active_tween.is_valid():
        _active_tween.kill()
    if _label != null:
        _label.visible = true
        _label.modulate.a = 1.0
        _label.scale = Vector3.ONE

func on_pool_recycled() -> void:
    if _active_tween != null and _active_tween.is_valid():
        _active_tween.kill()
    _active_tween = null
    _recycle_requested = false
    if _label != null:
        _label.visible = false
        _label.modulate.a = 0.0
        _label.scale = Vector3.ONE

func configure(text: String, world_position: Vector3, color: Color, font_size: int,
        start_scale: float, end_position: Vector3, duration: float,
        outline_size: int, outline_alpha: float) -> void:
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    if _label == null:
        _request_recycle()
        return

    _label.text = text
    _label.font_size = font_size
    _label.outline_size = outline_size
    _label.modulate = Color(color.r, color.g, color.b, 1.0)
    _label.outline_modulate = Color(color.r, color.g, color.b, outline_alpha)
    _label.scale = Vector3.ONE * start_scale
    global_position = world_position

    var camera: Camera3D = get_viewport().get_camera_3d()
    if camera != null:
        look_at(camera.global_position, Vector3.UP, true)

    _active_tween = create_tween()
    _active_tween.set_parallel(true)
    _active_tween.tween_property(self, "global_position", end_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _active_tween.tween_property(_label, "modulate:a", 0.0, duration)
    _active_tween.tween_property(_label, "scale", Vector3.ONE * 0.18, duration)
    _active_tween.set_parallel(false)
    _active_tween.tween_callback(_request_recycle)

func _request_recycle() -> void:
    if _recycle_requested:
        return
    _recycle_requested = true
    PoolManager.call_deferred("recycle", self)
