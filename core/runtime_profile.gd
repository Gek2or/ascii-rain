extends Node

enum Tier { DESKTOP, MOBILE }

var tier: Tier = Tier.DESKTOP
var is_mobile: bool = false
var enemy_soft_cap: int = 88
var base_spawn_interval: float = 1.12
var ascii_cell_px: float = 6.0
var ascii_bloom_strength: float = 0.16
var ascii_edge_gain: float = 0.45
var ascii_glyph_gain: float = 1.40
var dynamic_shadow_enabled: bool = true
var player_forward_light_energy: float = 2.25
var player_forward_light_range: float = 26.0
var hit_stop_max_ms: int = 42
var render_scale: float = 1.0
var lighting_boost: float = 1.0
var ascii_exposure: float = 1.0

func _ready() -> void:
    refresh()

func refresh() -> void:
    is_mobile = OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS"
    # Editor/CI preview switch only; actual Android detection remains automatic.
    is_mobile = is_mobile or OS.get_cmdline_user_args().has("--touch-preview")
    tier = Tier.MOBILE if is_mobile else Tier.DESKTOP

    if is_mobile:
        enemy_soft_cap = 54
        base_spawn_interval = 1.34
        player_forward_light_energy = 1.72
        player_forward_light_range = 22.0
        hit_stop_max_ms = 28
    else:
        enemy_soft_cap = 96
        base_spawn_interval = 1.10
        player_forward_light_energy = 2.45
        player_forward_light_range = 30.0
        hit_stop_max_ms = 42

    ascii_cell_px = SettingsManager.ascii_cell_px
    ascii_bloom_strength = SettingsManager.bloom_strength
    ascii_edge_gain = SettingsManager.edge_gain
    ascii_glyph_gain = SettingsManager.glyph_gain
    ascii_exposure = 1.0
    render_scale = SettingsManager.render_scale
    lighting_boost = SettingsManager.lighting_boost
    dynamic_shadow_enabled = SettingsManager.shadows_enabled and not (is_mobile and SettingsManager.quality_preset <= SettingsManager.QualityPreset.MEDIUM)

    if SettingsManager.quality_preset == SettingsManager.QualityPreset.LOW:
        enemy_soft_cap = mini(enemy_soft_cap, 36)
        base_spawn_interval *= 1.12
        player_forward_light_range *= 0.88
    elif SettingsManager.quality_preset == SettingsManager.QualityPreset.ULTRA and not is_mobile:
        enemy_soft_cap = 112
        player_forward_light_range = 32.0
