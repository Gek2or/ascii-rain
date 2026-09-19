extends ColorRect
class_name DamageFeedback

const VIGNETTE: Shader = preload("res://shaders/damage_vignette.gdshader")
var _effect: ShaderMaterial = null
var _flash_start_msec: int = 0
var _intensity: float = 0.0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _effect = ShaderMaterial.new()
    _effect.shader = VIGNETTE
    material = _effect
    color = Color.WHITE
    visible = false

func flash(damage_ratio: float) -> void:
    _intensity = maxf(_intensity * 0.6, clampf(0.12 + damage_ratio * 0.70, 0.12, 0.30))
    _flash_start_msec = Time.get_ticks_msec()
    visible = true
    _effect.set_shader_parameter("impact", _intensity)

func _process(_delta: float) -> void:
    if not visible:
        return
    # Real time: hit-stop must not prolong a red overlay during repeated damage.
    var elapsed_ms: int = Time.get_ticks_msec() - _flash_start_msec
    var remaining: float = clampf(1.0 - float(elapsed_ms) / 220.0, 0.0, 1.0)
    _effect.set_shader_parameter("impact", _intensity * remaining * remaining)
    if remaining <= 0.0:
        visible = false
        _intensity = 0.0
