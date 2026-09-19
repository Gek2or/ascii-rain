extends Node3D

const LOW_TINT: Color = Color(1.0, 0.34, 0.08)
const MID_TINT: Color = Color(1.0, 0.78, 0.32)
const HIGH_TINT: Color = Color(0.35, 0.72, 1.0)
const CALM_TINT: Color = Color(0.12, 0.34, 0.92)
const RISING_TINT: Color = Color(0.12, 0.86, 0.78)
const TENSE_TINT: Color = Color(1.0, 0.34, 0.08)
const PEAK_TINT: Color = Color(1.0, 0.04, 0.16)
const PORTAL_CHAOS_DURATION: float = 18.0
const PORTAL_SKY_HEIGHT: float = 74.0
const PORTAL_SKY_RANGE: float = 180.0
const PORTAL_TINTS: Array[Color] = [
    Color(0.08, 0.82, 1.0),
    Color(1.0, 0.08, 0.28),
    Color(0.76, 0.12, 1.0),
    Color(1.0, 0.42, 0.06)]

var _lights: Array[OmniLight3D] = []
var _base_energy: Array[float] = []
var _base_color: Array[Color] = []
var _band_mix: Array[Vector3] = []
var _bands: Vector3 = Vector3.ZERO
var _tension: float = 0.0
var _portal_light: OmniLight3D = null
var _portal_sky_light: SpotLight3D = null
var _portal_event_light: DirectionalLight3D = null
var _portal_chaos_remaining: float = 0.0
var _portal_chaos_level: float = 0.0
var _chaos_timer: float = 0.0
var _chaos_tint: Color = Color(0.08, 0.82, 1.0)
var _chaos_target_tint: Color = Color(0.08, 0.82, 1.0)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()
    for entry in get_tree().get_nodes_in_group("audio_reactive_lights"):
        var light: OmniLight3D = entry as OmniLight3D
        if light == null:
            continue
        _lights.append(light)
        _base_energy.append(light.light_energy)
        _base_color.append(light.light_color)
        _band_mix.append(_mix_for_band(int(light.get_meta("audio_band", 1))))

func _process(delta: float) -> void:
    var target: Vector3 = AudioManager.get_music_bands()
    _bands = _bands.lerp(target, 1.0 - exp(-delta * 16.0))
    if _portal_chaos_remaining > 0.0:
        _portal_chaos_remaining = maxf(0.0, _portal_chaos_remaining - delta)
        _portal_chaos_level = _portal_chaos_remaining / PORTAL_CHAOS_DURATION
        _chaos_timer -= delta
        if _chaos_timer <= 0.0:
            _chaos_timer = _rng.randf_range(0.32, 0.72)
            _chaos_target_tint = PORTAL_TINTS[_rng.randi_range(0, PORTAL_TINTS.size() - 1)]
        _chaos_tint = _chaos_tint.lerp(_chaos_target_tint, 1.0 - exp(-delta * 10.0))
        _update_portal_light()
    else:
        _portal_chaos_level = 0.0
        _clear_portal_event_lights()
    var tension_target: float = clampf(
        _bands.x * 0.45 + _bands.y * 0.35 + _bands.z * 0.20, 0.0, 1.0)
    _tension = move_toward(_tension, tension_target, delta * 7.0)
    for index in range(_lights.size()):
        var light: OmniLight3D = _lights[index]
        if not is_instance_valid(light):
            continue
        var mix: Vector3 = _band_mix[index]
        var pulse: float = _bands.dot(mix)
        var energy_pulse: float = clampf(pulse * 1.15 + _tension * 0.28, 0.0, 1.60)
        var portal_boost: float = _portal_chaos_level * (0.55 + pulse * 0.80)
        light.light_energy = _base_energy[index] * (1.0 + energy_pulse + portal_boost)
        var band_tint: Color = LOW_TINT * mix.x + MID_TINT * mix.y + HIGH_TINT * mix.z
        var tension_tint: Color = _tone_for_tension(_tension)
        var target_tint: Color = band_tint.lerp(tension_tint, 0.62)
        target_tint = target_tint.lerp(_chaos_tint, 0.48 * _portal_chaos_level)
        light.light_color = _base_color[index].lerp(
            target_tint, clampf(0.48 + pulse * 0.40 + _portal_chaos_level * 0.10, 0.0, 0.92))

func trigger_portal_chaos(portal: Node3D) -> void:
    if not is_instance_valid(portal):
        return
    _portal_chaos_remaining = PORTAL_CHAOS_DURATION
    _portal_chaos_level = 1.0
    _chaos_timer = 0.0
    if not is_instance_valid(_portal_light):
        _portal_light = OmniLight3D.new()
        _portal_light.name = "PortalPulseLight"
        _portal_light.omni_range = 21.0
        _portal_light.shadow_enabled = false
        add_child(_portal_light)
    if not is_instance_valid(_portal_sky_light):
        _portal_sky_light = SpotLight3D.new()
        _portal_sky_light.name = "PortalSkyProjector"
        _portal_sky_light.spot_range = PORTAL_SKY_RANGE
        _portal_sky_light.spot_angle = 58.0
        _portal_sky_light.shadow_enabled = false
        add_child(_portal_sky_light)
    if not is_instance_valid(_portal_event_light):
        _portal_event_light = DirectionalLight3D.new()
        _portal_event_light.name = "PortalEventLight"
        _portal_event_light.shadow_enabled = false
        add_child(_portal_event_light)
    _portal_light.global_position = portal.global_position + Vector3(0.0, 2.8, 0.0)
    _portal_light.light_color = _chaos_tint
    _portal_light.light_energy = 5.5
    _portal_sky_light.global_position = portal.global_position + Vector3.UP * PORTAL_SKY_HEIGHT
    _portal_sky_light.look_at(portal.global_position, Vector3.FORWARD)
    _portal_sky_light.light_color = _chaos_tint
    _portal_sky_light.light_energy = 5.0
    _portal_event_light.global_position = _portal_sky_light.global_position
    _portal_event_light.look_at(portal.global_position, Vector3.FORWARD)
    _portal_event_light.light_color = _chaos_tint
    _portal_event_light.light_energy = 0.48

func _update_portal_light() -> void:
    if not is_instance_valid(_portal_light):
        return
    var audio_impact: float = clampf(_bands.x * 1.60 + _bands.y * 0.90 + _bands.z * 0.65, 0.0, 2.0)
    var spectrum_tint: Color = LOW_TINT.lerp(MID_TINT, clampf(_bands.y, 0.0, 1.0))
    spectrum_tint = spectrum_tint.lerp(HIGH_TINT, clampf(_bands.z, 0.0, 0.85))
    _portal_light.light_energy = clampf(
        5.5 * _portal_chaos_level * (0.72 + audio_impact), 0.0, 16.0)
    _portal_light.light_color = _chaos_tint.lerp(spectrum_tint, clampf(audio_impact * 0.28, 0.0, 0.52))
    var event_tint: Color = _chaos_tint.lerp(spectrum_tint, clampf(0.22 + audio_impact * 0.30, 0.0, 0.78))
    if is_instance_valid(_portal_sky_light):
        _portal_sky_light.light_color = event_tint
        _portal_sky_light.light_energy = clampf(
            6.0 * _portal_chaos_level * (0.52 + audio_impact), 0.0, 16.0)
    if is_instance_valid(_portal_event_light):
        _portal_event_light.light_color = event_tint
        _portal_event_light.light_energy = clampf(
            _portal_chaos_level * (0.30 + audio_impact * 0.36), 0.0, 0.95)

func _clear_portal_event_lights() -> void:
    for light: Light3D in [_portal_light, _portal_sky_light, _portal_event_light]:
        if is_instance_valid(light):
            light.queue_free()
    _portal_light = null
    _portal_sky_light = null
    _portal_event_light = null

func _tone_for_tension(tension: float) -> Color:
    if tension < 0.33:
        return CALM_TINT.lerp(RISING_TINT, tension / 0.33)
    if tension < 0.70:
        return RISING_TINT.lerp(TENSE_TINT, (tension - 0.33) / 0.37)
    return TENSE_TINT.lerp(PEAK_TINT, (tension - 0.70) / 0.30)

func _mix_for_band(band: int) -> Vector3:
    match band:
        0:
            return Vector3(1.0, 0.0, 0.0)
        2:
            return Vector3(0.0, 0.0, 1.0)
        _:
            return Vector3(0.0, 1.0, 0.0)
