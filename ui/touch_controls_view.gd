extends Control

const LAYOUT = preload("res://components/input/touch_layout.gd")
const LABELS: Dictionary = {&"shoot": "FIRE", &"aim": "AIM", &"dash": "DASH", &"jump": "JUMP", &"interact": "USE", &"weapon_next": "WPN"}
var layout: Dictionary = {}
var stick: Vector2 = Vector2.ZERO
var held: Dictionary = {}
var aim_toggled: bool = false
var dash_remaining: float = 0.0
var _idle_style: StyleBoxFlat = null
var _pressed_style: StyleBoxFlat = null

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    resized.connect(rebuild)
    SettingsManager.changed.connect(rebuild)
    rebuild()

func rebuild() -> void:
    layout = LAYOUT.build(get_viewport().get_visible_rect().size, SettingsManager.touch_controls_scale)
    var corner: int = int(16.0 * float(layout["scale"]))
    _idle_style = StyleBoxFlat.new()
    _idle_style.bg_color = Color(0.015, 0.035, 0.045, 0.52)
    _idle_style.border_color = Color(0.45, 0.62, 0.68, 0.68)
    _idle_style.set_border_width_all(1)
    _idle_style.set_corner_radius_all(corner)
    _pressed_style = _idle_style.duplicate() as StyleBoxFlat
    _pressed_style.bg_color = Color(0.08, 0.30, 0.35, 0.70)
    _pressed_style.border_color = Color(0.52, 0.83, 0.88, 0.85)
    _pressed_style.set_border_width_all(2)
    queue_redraw()

func _draw() -> void:
    if layout.is_empty():
        return
    var scale_factor: float = float(layout["scale"])
    var center: Vector2 = layout["center"]
    var radius: float = float(layout["radius"])
    var ink: Color = Color(0.69, 0.84, 0.88, 0.8)
    draw_circle(center, radius, Color(0.02, 0.045, 0.06, 0.45))
    draw_arc(center, radius, 0.0, TAU, 56, Color(0.47, 0.69, 0.76, 0.65), 2.0, true)
    draw_arc(center, radius * 0.14, 0.0, TAU, 24, Color(0.42, 0.62, 0.70, 0.30), 1.0, true)
    draw_circle(center + stick * radius, 23.0 * scale_factor, Color(0.51, 0.78, 0.84, 0.66))
    var buttons: Dictionary = layout["buttons"]
    for action in buttons:
        var rect: Rect2 = buttons[action]
        var selected: bool = bool(held.get(action, false)) or (action == &"aim" and aim_toggled)
        draw_style_box(_pressed_style if selected else _idle_style, rect)
        var label: String = String(LABELS[action])
        if action == &"aim" and aim_toggled:
            label = "AIM ON"
        if action == &"dash" and dash_remaining > 0.05:
            label = "%.1f" % dash_remaining
        var font_size: int = maxi(12, int(17.0 * scale_factor))
        draw_string(ThemeDB.fallback_font, rect.position + Vector2(0.0, rect.size.y * 0.5 + font_size * 0.34), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, ink)
