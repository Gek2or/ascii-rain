extends Control

var camera: Camera3D = null
var actor: Node3D = null
var target: Vector3 = Vector3.ZERO
var caption: String = ""
var enabled: bool = true
var _font: Font = null

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    process_mode = Node.PROCESS_MODE_ALWAYS
    _font = ThemeDB.fallback_font

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    if not enabled or get_tree().paused or caption.is_empty():
        return
    if not is_instance_valid(camera) or not is_instance_valid(actor):
        return
    if not bool(actor.get("control_enabled")) or _font == null:
        return
    var aim: Vector3 = target + Vector3.UP * 1.5
    var middle: Vector2 = size * 0.5
    var local: Vector3 = camera.to_local(aim)
    var screen_point: Vector2 = middle
    if local.z < -0.1:
        screen_point = camera.unproject_position(aim)
    else:
        # Bearing marker for goals, not visibility of enemies through walls.
        var bearing: Vector2 = Vector2(local.x, 2.0)
        screen_point = middle + bearing.normalized() * maxf(size.x, size.y)
    var safe: Rect2 = Rect2(108.0, 190.0, maxf(1.0, size.x - 216.0), maxf(1.0, size.y - 350.0))
    var clamped: Vector2 = Vector2(clampf(screen_point.x, safe.position.x, safe.end.x), clampf(screen_point.y, safe.position.y, safe.end.y))
    var tint: Color = Color(0.96, 0.79, 0.44, 0.95)
    var diamond: PackedVector2Array = PackedVector2Array([clamped + Vector2(0, -8), clamped + Vector2(8, 0), clamped + Vector2(0, 8), clamped + Vector2(-8, 0), clamped + Vector2(0, -8)])
    draw_polyline(diamond, Color(0.01, 0.012, 0.016, 0.94), 5.0, true)
    draw_polyline(diamond, tint, 2.0, true)
    if screen_point.distance_to(clamped) > 4.0:
        var direction: Vector2 = (screen_point - clamped).normalized()
        draw_line(clamped + direction * 12.0, clamped + direction * 22.0, tint, 2.0, true)
    var distance: int = int(actor.global_position.distance_to(target))
    var text: String = "%s  %dm" % [caption, distance]
    var text_size: Vector2 = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
    var baseline: Vector2 = clamped + Vector2(-text_size.x * 0.5, 28.0)
    _draw_label(text, baseline, text_size, tint)

func _draw_label(text: String, baseline: Vector2, text_size: Vector2, tint: Color) -> void:
    draw_rect(Rect2(baseline + Vector2(-6, -16), Vector2(text_size.x + 12, 23)), Color(0.01, 0.016, 0.024, 0.90))
    draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tint)
