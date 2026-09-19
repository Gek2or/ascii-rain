extends Control

var _player: Node = null
var _pulse: float = 0.0
var _hit_timer: float = 0.0
var _crit_timer: float = 0.0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _player = get_tree().get_first_node_in_group("player")
    GameEvents.shot_feedback.connect(_on_shot_feedback)
    queue_redraw()

func _process(delta: float) -> void:
    _pulse = move_toward(_pulse, 0.0, delta * 7.0)
    _hit_timer = maxf(0.0, _hit_timer - delta)
    _crit_timer = maxf(0.0, _crit_timer - delta)
    queue_redraw()

func _draw() -> void:
    if get_tree().paused or not is_instance_valid(_player):
        return
    if not bool(_player.get("control_enabled")):
        return
    var center: Vector2 = size * 0.5
    var gap: float = 9.0
    if _player != null and _player.has_method("get_reticle_gap_px"):
        gap = float(_player.call("get_reticle_gap_px"))
    gap += _pulse * 2.0
    if Input.is_action_pressed("aim"):
        gap *= 0.72

    var line_length: float = 7.0
    var width: float = 1.6
    var color: Color = Color(0.82, 0.91, 1.0, 0.92)
    var blocked: bool = _player.has_method("is_aim_blocked") and bool(_player.call("is_aim_blocked"))
    if blocked:
        color = Color(1.0, 0.49, 0.19, 1.0)
    if _hit_timer > 0.0:
        color = Color(1.0, 0.68, 0.22, 1.0)
    if _crit_timer > 0.0:
        color = Color(1.0, 0.22, 0.12, 1.0)

    _outlined_line(center + Vector2(-gap - line_length, 0), center + Vector2(-gap, 0), color, width)
    _outlined_line(center + Vector2(gap, 0), center + Vector2(gap + line_length, 0), color, width)
    _outlined_line(center + Vector2(0, -gap - line_length), center + Vector2(0, -gap), color, width)
    _outlined_line(center + Vector2(0, gap), center + Vector2(0, gap + line_length), color, width)
    draw_circle(center, 3.4, Color(0.005, 0.008, 0.012, 0.92))
    draw_circle(center, 1.5, color)

    if blocked:
        var obstruction: Vector2 = _player.call("get_aim_block_screen_position")
        if Rect2(Vector2.ZERO, size).has_point(obstruction):
            draw_arc(obstruction, 7.0, 0.0, TAU, 20, Color(0.005, 0.008, 0.012, 0.95), 4.0, true)
            draw_arc(obstruction, 7.0, 0.0, TAU, 20, color, 1.8, true)
            _outlined_line(obstruction + Vector2(-5, 5), obstruction + Vector2(5, -5), color, 1.8)

    if _hit_timer > 0.0:
        var hit_size: float = 7.0 + _crit_timer * 8.0
        _outlined_line(center + Vector2(-hit_size, -hit_size), center + Vector2(-3.0, -3.0), color, 1.8)
        _outlined_line(center + Vector2(hit_size, -hit_size), center + Vector2(3.0, -3.0), color, 1.8)
        _outlined_line(center + Vector2(-hit_size, hit_size), center + Vector2(-3.0, 3.0), color, 1.8)
        _outlined_line(center + Vector2(hit_size, hit_size), center + Vector2(3.0, 3.0), color, 1.8)

func notify_shot() -> void:
    _pulse = 1.0

func _on_shot_feedback(hit: bool, critical: bool) -> void:
    _pulse = 1.0
    if hit:
        _hit_timer = 0.13
    if critical:
        _crit_timer = 0.16

func _outlined_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
    draw_line(from, to, Color(0.005, 0.008, 0.012, 0.88), width + 2.4, true)
    draw_line(from, to, color, width, true)
