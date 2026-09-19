extends CanvasLayer

var _label: Label = null
var _samples: Array[float] = []
var _last_usec: int = 0
var _refresh_usec: int = 0

func _ready() -> void:
    layer = 150
    process_mode = Node.PROCESS_MODE_ALWAYS
    _label = Label.new()
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _label.position = Vector2(26.0, 242.0)
    _label.add_theme_font_size_override("font_size", 13)
    _label.add_theme_color_override("font_color", Color(0.84, 0.93, 0.89))
    _label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.025, 0.95))
    _label.add_theme_constant_override("outline_size", 5)
    add_child(_label)
    _last_usec = Time.get_ticks_usec()

func _process(_delta: float) -> void:
    var now: int = Time.get_ticks_usec()
    _label.visible = SettingsManager.performance_hud_enabled and not get_tree().paused
    if get_tree().paused or not SettingsManager.performance_hud_enabled:
        _samples.clear()
        _last_usec = now
        return
    var duration_ms: float = float(now - _last_usec) * 0.001
    _last_usec = now
    if duration_ms > 0.0:
        _samples.append(duration_ms)
        if _samples.size() > 120:
            _samples.pop_front()
    if now < _refresh_usec or _samples.size() < 5:
        return
    _refresh_usec = now + 500000
    var ordered: Array[float] = _samples.duplicate()
    ordered.sort()
    var p95: float = ordered[mini(ordered.size() - 1, int(ceil(ordered.size() * 0.95)) - 1)]
    var median: float = ordered[int(ordered.size() / 2.0)]
    _label.text = "%d FPS   FRAME %.1f ms / P95 %.1f ms\n%s | %d enemies | %.2f scale" % [
        Engine.get_frames_per_second(), median, p95,
        str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility")), get_tree().get_nodes_in_group("enemies").size(), SettingsManager.render_scale]
