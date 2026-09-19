extends Node

signal changed

const SAVE_PATH: String = "user://ascii_rain_settings.cfg"

enum QualityPreset { LOW, MEDIUM, HIGH, ULTRA }

var quality_preset: int = QualityPreset.HIGH
var render_scale: float = 1.0
var ascii_cell_px: float = 6.0
var bloom_strength: float = 0.16
var edge_gain: float = 0.45
var glyph_gain: float = 1.40
var lighting_boost: float = 1.0
var shadows_enabled: bool = true
var mouse_sensitivity_scale: float = 1.0
var music_volume: float = 0.72
var sfx_volume: float = 0.82

# Gameplay readability is independent of quality / enemy budgets.
var readability_strength: float = 0.65
var actor_edge_strength: float = 0.45
var depth_contours_enabled: bool = false
var camera_motion: float = 0.35
var background_calm: float = 0.40
var color_saturation: float = 0.68
var touch_controls_scale: float = 1.0
var touch_look_sensitivity: float = 1.0
var performance_hud_enabled: bool = false
var ambient_motion: float = 1.0
var ambient_volume: float = 0.55
var visual_style: int = 0
var surface_fill: float = 0.22
var _save_pending: bool = false
const RENDER_SCHEMA: int = 5
const PREVIOUS_SETTINGS: String = "user://ascii_rain_settings_before_0_13.cfg"

func _ready() -> void:
    _apply_platform_defaults()
    _render_defaults()
    load_settings()

func _is_mobile_platform() -> bool:
    return OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS" or OS.get_cmdline_user_args().has("--touch-preview")

func _apply_platform_defaults() -> void:
    var mobile: bool = _is_mobile_platform()
    if mobile:
        depth_contours_enabled = false
        quality_preset = QualityPreset.MEDIUM
        render_scale = 0.78
        ascii_cell_px = 8.0
        bloom_strength = 0.25
        edge_gain = 0.62
        glyph_gain = 1.64
        lighting_boost = 1.14
        shadows_enabled = false
        mouse_sensitivity_scale = 1.05
    else:
        quality_preset = QualityPreset.HIGH
        render_scale = 1.0
        ascii_cell_px = 6.0
        bloom_strength = 0.20
        edge_gain = 0.72
        glyph_gain = 1.60
        lighting_boost = 1.08
        shadows_enabled = true

func apply_preset(preset: int) -> void:
    quality_preset = clampi(preset, QualityPreset.LOW, QualityPreset.ULTRA)
    match quality_preset:
        QualityPreset.LOW:
            render_scale = 0.62
            ascii_cell_px = 8.0
            shadows_enabled = false
        QualityPreset.MEDIUM:
            render_scale = 0.78
            ascii_cell_px = 8.0
            shadows_enabled = false
        QualityPreset.HIGH:
            render_scale = 1.0
            ascii_cell_px = 6.0
            shadows_enabled = true
        QualityPreset.ULTRA:
            render_scale = 1.0
            ascii_cell_px = 6.0
            shadows_enabled = true
    # Tone/contrast are user preferences, not a side effect of the quality tier.
    save_settings()
    changed.emit()

func save_settings() -> void:
    # Collapse multiple UI changes in a frame into one config write.
    if _save_pending:
        return
    _save_pending = true
    call_deferred("_flush_settings")

func _flush_settings() -> void:
    _save_pending = false
    var cfg: ConfigFile = ConfigFile.new()
    cfg.set_value("graphics", "quality_preset", quality_preset)
    cfg.set_value("graphics", "render_scale", render_scale)
    cfg.set_value("graphics", "ascii_cell_px", ascii_cell_px)
    cfg.set_value("graphics", "bloom_strength", bloom_strength)
    cfg.set_value("graphics", "edge_gain", edge_gain)
    cfg.set_value("graphics", "glyph_gain", glyph_gain)
    cfg.set_value("graphics", "lighting_boost", lighting_boost)
    cfg.set_value("graphics", "shadows_enabled", shadows_enabled)
    cfg.set_value("controls", "mouse_sensitivity_scale", mouse_sensitivity_scale)
    cfg.set_value("audio", "music_volume", music_volume)
    cfg.set_value("audio", "sfx_volume", sfx_volume)
    cfg.set_value("readability", "strength", readability_strength)
    cfg.set_value("readability", "actor_edges", actor_edge_strength)
    cfg.set_value("readability", "depth_contours", depth_contours_enabled)
    cfg.set_value("controls", "camera_motion", camera_motion)
    cfg.set_value("readability", "background_calm", background_calm)
    cfg.set_value("readability", "color_saturation", color_saturation)
    cfg.set_value("controls", "touch_controls_scale", touch_controls_scale)
    cfg.set_value("controls", "touch_look_sensitivity", touch_look_sensitivity)
    cfg.set_value("debug", "performance_hud", performance_hud_enabled)
    cfg.set_value("readability", "surface_fill", surface_fill)
    cfg.set_value("ambient", "motion", ambient_motion)
    cfg.set_value("ambient", "volume", ambient_volume)
    cfg.set_value("meta", "schema", RENDER_SCHEMA)
    cfg.set_value("graphics", "visual_style", visual_style)
    var save_error: Error = cfg.save(SAVE_PATH)
    if save_error != OK:
        push_warning("Settings save failed: %s" % error_string(save_error))

func load_settings() -> void:
    var cfg: ConfigFile = ConfigFile.new()
    var result: Error = cfg.load(SAVE_PATH)
    if result != OK:
        return
    visual_style = clampi(int(cfg.get_value("graphics", "visual_style", 0)),0,2)
    quality_preset = clampi(int(cfg.get_value("graphics", "quality_preset", quality_preset)), QualityPreset.LOW, QualityPreset.ULTRA)
    render_scale = clampf(float(cfg.get_value("graphics", "render_scale", render_scale)), 0.50, 1.0)
    ascii_cell_px = clampf(float(cfg.get_value("graphics", "ascii_cell_px", ascii_cell_px)), 1.0, 10.0)
    bloom_strength = clampf(float(cfg.get_value("graphics", "bloom_strength", bloom_strength)), 0.0, 0.70)
    edge_gain = clampf(float(cfg.get_value("graphics", "edge_gain", edge_gain)), 0.30, 1.20)
    glyph_gain = clampf(float(cfg.get_value("graphics", "glyph_gain", glyph_gain)), 1.0, 2.2)
    lighting_boost = clampf(float(cfg.get_value("graphics", "lighting_boost", lighting_boost)), 0.70, 1.50)
    shadows_enabled = bool(cfg.get_value("graphics", "shadows_enabled", shadows_enabled))
    mouse_sensitivity_scale = clampf(float(cfg.get_value("controls", "mouse_sensitivity_scale", mouse_sensitivity_scale)), 0.35, 2.2)
    music_volume = clampf(float(cfg.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
    sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
    readability_strength = clampf(float(cfg.get_value("readability", "strength", readability_strength)), 0.0, 1.0)
    actor_edge_strength = clampf(float(cfg.get_value("readability", "actor_edges", actor_edge_strength)), 0.0, 1.0)
    depth_contours_enabled = bool(cfg.get_value("readability", "depth_contours", depth_contours_enabled))
    camera_motion = clampf(float(cfg.get_value("controls", "camera_motion", camera_motion)), 0.0, 1.0)
    background_calm = clampf(float(cfg.get_value("readability", "background_calm", background_calm)), 0.0, 1.0)
    color_saturation = clampf(float(cfg.get_value("readability", "color_saturation", color_saturation)), 0.35, 1.0)
    touch_controls_scale = clampf(float(cfg.get_value("controls", "touch_controls_scale", touch_controls_scale)), 0.8, 1.25)
    touch_look_sensitivity = clampf(float(cfg.get_value("controls", "touch_look_sensitivity", touch_look_sensitivity)), 0.35, 2.2)
    performance_hud_enabled = bool(cfg.get_value("debug", "performance_hud", performance_hud_enabled))
    surface_fill = clampf(float(cfg.get_value("readability", "surface_fill", surface_fill)), 0.0, 0.70)
    ambient_motion = clampf(float(cfg.get_value("ambient", "motion", ambient_motion)), 0.0, 1.0)
    ambient_volume = clampf(float(cfg.get_value("ambient", "volume", ambient_volume)), 0.0, 1.0)
    if int(cfg.get_value("meta", "schema", 0)) < RENDER_SCHEMA:
        if not FileAccess.file_exists(PREVIOUS_SETTINGS):
            var backup_error: Error = cfg.save(PREVIOUS_SETTINGS)
            if backup_error != OK:
                push_warning("Could not back up old graphics settings: %s" % error_string(backup_error))
        _render_defaults()
        save_settings()


func update_render_scale(value: float) -> void:
    render_scale = clampf(value, 0.50, 1.0)
    save_settings()
    changed.emit()

func update_ascii_cell(value: float) -> void:
    ascii_cell_px = clampf(value, 1.0, 10.0)
    save_settings()
    changed.emit()

func update_bloom(value: float) -> void:
    bloom_strength = clampf(value, 0.0, 0.70)
    save_settings()
    changed.emit()

func update_lighting(value: float) -> void:
    lighting_boost = clampf(value, 0.70, 1.50)
    save_settings()
    changed.emit()

func update_shadows(enabled: bool) -> void:
    shadows_enabled = enabled
    save_settings()
    changed.emit()

func update_mouse_sensitivity(value: float) -> void:
    mouse_sensitivity_scale = clampf(value, 0.35, 2.2)
    save_settings()
    changed.emit()

func update_music_volume(value: float) -> void:
    music_volume = clampf(value, 0.0, 1.0)
    save_settings()
    changed.emit()

func update_sfx_volume(value: float) -> void:
    sfx_volume = clampf(value, 0.0, 1.0)
    save_settings()
    changed.emit()

func update_readability(value: float) -> void:
    readability_strength = clampf(value, 0.0, 1.0)
    save_settings()
    changed.emit()

func update_actor_edges(value: float) -> void:
    actor_edge_strength = clampf(value, 0.0, 1.0)
    save_settings()
    changed.emit()

func update_depth_contours(value: bool) -> void:
    depth_contours_enabled = value
    save_settings()
    changed.emit()

func update_camera_motion(value: float) -> void:
    camera_motion = clampf(value, 0.0, 1.0)
    save_settings()
    changed.emit()

func _render_defaults() -> void:
    _set_visual_style(2 if _is_mobile_platform() else 0)

func _set_visual_style(style: int) -> void:
    visual_style = clampi(style,0,2)
    depth_contours_enabled = false
    color_saturation = 0.86
    edge_gain = 0.45
    glyph_gain = 1.65
    bloom_strength = 0.05
    readability_strength = 0.56
    actor_edge_strength = 0.38
    background_calm = 0.28
    surface_fill = 0.22
    lighting_boost = 0.88
    ascii_cell_px = 6.0
    render_scale = 1.0
    if visual_style == 1: # Same discrete glyph renderer, softer contrast for play.
        surface_fill = 0.46
        readability_strength = 0.78
        actor_edge_strength = 0.50
        background_calm = 0.45
        lighting_boost = 1.04
    elif visual_style == 2:
        ascii_cell_px = 8.0
        surface_fill = 0.32
        readability_strength = 0.72
        render_scale = 0.78
        shadows_enabled = false

func apply_visual_style(style: int) -> void:
    _set_visual_style(style)
    save_settings()
    changed.emit()

func reset_readability() -> void:
    _render_defaults()
    save_settings()
    changed.emit()

func update_surface_fill(value: float) -> void:
    surface_fill = clampf(value, 0.0, 0.70)
    save_settings()
    changed.emit()

func update_background_calm(value: float) -> void:
    background_calm = clampf(value, 0.0, 1.0)
    save_settings()
    changed.emit()

func update_color_saturation(value: float) -> void:
    color_saturation = clampf(value, 0.35, 1.0)
    save_settings()
    changed.emit()

func update_touch_controls_scale(value: float) -> void:
    touch_controls_scale = clampf(value, 0.8, 1.25)
    save_settings()
    changed.emit()

func update_touch_look_sensitivity(value: float) -> void:
    touch_look_sensitivity = clampf(value, 0.35, 2.2)
    save_settings()
    changed.emit()

func update_performance_hud(value: bool) -> void:
    performance_hud_enabled = value
    save_settings()
    changed.emit()

func update_ambient_motion(value: float) -> void:
    ambient_motion = clampf(value,0.0,1.0)
    save_settings()
    changed.emit()

func update_ambient_volume(value: float) -> void:
    ambient_volume = clampf(value, 0.0, 1.0)
    save_settings()
    changed.emit()
