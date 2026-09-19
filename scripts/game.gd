extends Node3D

const DISTRICT_RULES = preload("res://data/district_rules.gd")
const ATLAS_BINDING = preload("res://rendering/ascii_atlas_binding.gd")

const ENEMY_SCENE = preload("res://scenes/Enemy.tscn")
const CHEST_SCENE = preload("res://scenes/Chest.tscn")
const TELEPORTER_SCENE = preload("res://scenes/Teleporter.tscn")
const BOSS_SCENE = preload("res://scenes/Boss.tscn")
const DAMAGE_FEEDBACK = preload("res://components/damage_feedback.gd")
const CITY_COLLISIONS = preload("res://world/city_collision_pass.gd")
const AUDIO_REACTIVE_LIGHTING = preload("res://scripts/audio_reactive_lighting.gd")
const STREET_NAVIGATION = preload("res://world/navigation/street_navigation.gd")
const ENCOUNTER_DIRECTOR = preload("res://world/encounter_director.gd")
const READABILITY_RENDERER = preload("res://rendering/readability_controller.gd")
const CITY_DETAIL_PASS = preload("res://world/city_detail_pass.gd")
const SETTINGS_MENU = preload("res://ui/settings_menu.gd")
const PERFORMANCE_OVERLAY = preload("res://ui/performance_overlay.gd")
const RUN_GUIDE = preload("res://core/run/run_guide.gd")
const RELIC_CHOICE = preload("res://ui/relic_choice.gd")
const RELIC_OFFERS = preload("res://components/inventory/relic_offers.gd")
const SPAWN_PLACEMENT = preload("res://world/spawn_placement.gd")
const RETICLE = preload("res://ui/reticle.gd")

const ENEMY_GRUNT = 0
const ENEMY_SKITTER = 1
const ENEMY_GUNNER = 2
const ENEMY_BOMBER = 3
const ENEMY_TANK = 4

const ELITE_NONE = 0
const ELITE_OVERCHARGED = 1
const ELITE_VOLATILE = 2

@export var base_spawn_interval: float = 1.12
@export var max_enemies: int = 88
@export_enum("test_arena", "threshold_market") var location_profile: String = "test_arena"

var elapsed: float = 0.0
var spawn_timer: float = 0.0
var difficulty: float = 1.0
var kills: int = 0
var event_active: bool = false
var run_complete: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var teleporter: Variant = null
var boss: Variant = null
var _nearest_interactable: Variant = null
var mobile_profile: bool = false
var _hit_stop_until_msec: int = 0
var _hit_stop_active: bool = false
var _damage_feedback: ColorRect = null
var _boss_phase_label: String = "PHASE 01 // OBSERVER"
var _encounter_director: EncounterDirector = null
var _street_navigation: StreetNavigation = null
var _settings_menu: CanvasLayer = null
var _reticle: Control = null
var _readability_renderer: Node = null
var _run_guide: Node = null
var _relic_choice: CanvasLayer = null
var _starter_cache: Node3D = null
var _sector_secured: bool = false
var _spawn_requests: Array[Dictionary] = []
var _spawn_failures: int = 0
var _upgrade_tween: Tween = null

@onready var player: Variant = $Player
@onready var ascii_rect: ColorRect = $PostFX/ASCII
@onready var timer_label: Label = $HUD/Timer
@onready var difficulty_label: Label = $HUD/Difficulty
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var health_text: Label = $HUD/HealthText
@onready var level_label: Label = $HUD/Level
@onready var xp_bar: ProgressBar = $HUD/XPBar
@onready var credits_label: Label = $HUD/Credits
@onready var items_panel: Panel = $HUD/ItemsPanel
@onready var items_label: Label = $HUD/ItemsPanel/Items
@onready var interaction_label: Label = $HUD/Interaction
@onready var objective_label: Label = $HUD/Objective
@onready var teleporter_bar: ProgressBar = $HUD/TeleporterBar
@onready var teleporter_text: Label = $HUD/TeleporterText
@onready var boss_panel: Control = $HUD/BossPanel
@onready var boss_bar: ProgressBar = $HUD/BossPanel/BossBar
@onready var boss_text: Label = $HUD/BossPanel/BossText
@onready var upgrade_label: Label = $HUD/Upgrade
@onready var death_panel: Control = $HUD/DeathPanel
@onready var complete_panel: Control = $HUD/CompletePanel
@onready var moon_light: DirectionalLight3D = $MoonLight
@onready var controls_label: Label = $HUD/Controls
@onready var weapon_label: Label = $HUD/Weapon
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var legacy_crosshair: Label = $HUD/Crosshair

func _ready() -> void:
    rng.seed = 7319
    SettingsManager.changed.connect(_apply_runtime_profile)
    _apply_runtime_profile()
    _build_readability_pass()
    var collision_pass: Node3D = CITY_COLLISIONS.new() as Node3D
    collision_pass.name = "CityCollisions"
    add_child(collision_pass)
    var audio_lighting: Node3D = AUDIO_REACTIVE_LIGHTING.new() as Node3D
    audio_lighting.name = "AudioReactiveLighting"
    add_child(audio_lighting)
    _street_navigation = STREET_NAVIGATION.new() as StreetNavigation
    _street_navigation.name = "StreetNavigation"
    add_child(_street_navigation)
    _build_runtime_ui()
    _apply_adaptive_hud_layout()
    _build_encounter_director()
    player.health_changed.connect(_on_health_changed)
    player.damaged.connect(_on_player_damaged)
    player.xp_changed.connect(_on_xp_changed)
    player.credits_changed.connect(_on_credits_changed)
    player.inventory_changed.connect(_on_inventory_changed)
    player.upgrade_announced.connect(_on_upgrade_announced)
    player.weapon_changed.connect(_on_weapon_changed)
    player.died.connect(_on_player_died)

    _on_health_changed(player.health, player.max_health)
    _on_xp_changed(player.xp, player.xp_needed, player.level)
    _on_credits_changed(player.credits)
    player.refresh_weapon_ui()
    death_panel.visible = false
    complete_panel.visible = false
    boss_panel.visible = false
    teleporter_bar.visible = false
    teleporter_text.visible = false
    _build_damage_feedback()

    _spawn_chests()
    _spawn_teleporter()
    if location_profile == "threshold_market":
        objective_label.text = "OBJECTIVE  —  RESTORE SCAN NODE / REACH DISTORTION ARENA"
        _show_upgrade_text("LOCATION 01 // THRESHOLD MARKET // ENTRY LIFT")
    else:
        objective_label.text = "OBJECTIVE  —  EXPLORE DISTRICTS / LOCATE TELEPORTER"
        _show_upgrade_text("DISTRICT 01 // THE INDEX // ARRIVAL NODE")
    _build_run_loop()
    GameEvents.run_started.emit()

func _apply_runtime_profile() -> void:
    RuntimeProfile.refresh()
    mobile_profile = RuntimeProfile.is_mobile
    max_enemies = RuntimeProfile.enemy_soft_cap
    base_spawn_interval = RuntimeProfile.base_spawn_interval
    moon_light.shadow_enabled = RuntimeProfile.dynamic_shadow_enabled
    moon_light.light_energy = 0.95 * RuntimeProfile.lighting_boost

    if mobile_profile:
        controls_label.text = "TOUCH: MOVE / LOOK   FIRE / JUMP / DASH / WPN / USE / SET"
    else:
        controls_label.text = "WASD MOVE  //  MOUSE AIM  //  LMB FIRE  //  SPACE JUMP  //  SHIFT DASH  //  ESC SETTINGS"

    var material: ShaderMaterial = ascii_rect.material as ShaderMaterial
    if material != null:
        material.set_shader_parameter("cell_px", RuntimeProfile.ascii_cell_px)
        material.set_shader_parameter("bloom_strength", RuntimeProfile.ascii_bloom_strength)
        material.set_shader_parameter("edge_gain", RuntimeProfile.ascii_edge_gain)
        material.set_shader_parameter("glyph_gain", RuntimeProfile.ascii_glyph_gain)
        material.set_shader_parameter("exposure", RuntimeProfile.ascii_exposure)
        material.set_shader_parameter("readability", SettingsManager.readability_strength)
        material.set_shader_parameter("background_calm", SettingsManager.background_calm)
        material.set_shader_parameter("color_saturation", SettingsManager.color_saturation)
        ATLAS_BINDING.apply(material, RuntimeProfile.ascii_cell_px)

    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set("scaling_3d_scale", RuntimeProfile.render_scale)

    if world_environment != null and world_environment.environment != null:
        world_environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
        world_environment.environment.ambient_light_sky_contribution = 0.0
        world_environment.environment.ambient_light_energy = 0.66 * RuntimeProfile.lighting_boost
        world_environment.environment.background_energy_multiplier = 1.05 * RuntimeProfile.lighting_boost
        world_environment.environment.fog_light_energy = 1.08 * RuntimeProfile.lighting_boost

    var forward_light: SpotLight3D = player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D/ForwardLight") as SpotLight3D
    if forward_light != null:
        forward_light.light_energy = RuntimeProfile.player_forward_light_energy * RuntimeProfile.lighting_boost
        forward_light.spot_range = RuntimeProfile.player_forward_light_range

func _build_runtime_ui() -> void:
    var metrics: CanvasLayer = PERFORMANCE_OVERLAY.new() as CanvasLayer
    metrics.name = "PerformanceOverlay"
    add_child(metrics)
    legacy_crosshair.visible = false
    _reticle = RETICLE.new() as Control
    if _reticle != null:
        _reticle.name = "ReticleV08"
        $HUD.add_child(_reticle)
    _settings_menu = SETTINGS_MENU.new() as CanvasLayer
    if _settings_menu != null:
        _settings_menu.name = "SettingsMenu"
        add_child(_settings_menu)

func _apply_adaptive_hud_layout() -> void:
    # Bottom HUD is anchored to the viewport instead of a fixed 720p Y coordinate.
    # This keeps health/XP visible in embedded editor play, small desktop windows, and Android.
    health_bar.anchor_left = 0.0
    health_bar.anchor_right = 0.0
    health_bar.anchor_top = 1.0
    health_bar.anchor_bottom = 1.0
    health_bar.offset_left = 28.0
    health_bar.offset_right = 310.0
    health_bar.offset_top = -94.0
    health_bar.offset_bottom = -76.0

    health_text.anchor_left = 0.0
    health_text.anchor_right = 0.0
    health_text.anchor_top = 1.0
    health_text.anchor_bottom = 1.0
    health_text.offset_left = 28.0
    health_text.offset_right = 180.0
    health_text.offset_top = -72.0
    health_text.offset_bottom = -44.0

    level_label.anchor_left = 0.0
    level_label.anchor_right = 0.0
    level_label.anchor_top = 1.0
    level_label.anchor_bottom = 1.0
    level_label.offset_left = 28.0
    level_label.offset_right = 100.0
    level_label.offset_top = -39.0
    level_label.offset_bottom = -10.0

    xp_bar.anchor_left = 0.0
    xp_bar.anchor_right = 0.0
    xp_bar.anchor_top = 1.0
    xp_bar.anchor_bottom = 1.0
    xp_bar.offset_left = 102.0
    xp_bar.offset_right = 310.0
    xp_bar.offset_top = -31.0
    xp_bar.offset_bottom = -18.0

    weapon_label.anchor_left = 0.0
    weapon_label.anchor_right = 0.0
    weapon_label.anchor_top = 1.0
    weapon_label.anchor_bottom = 1.0
    weapon_label.offset_left = 28.0
    weapon_label.offset_right = 470.0
    weapon_label.offset_top = -158.0
    weapon_label.offset_bottom = -130.0

    credits_label.anchor_left = 0.0
    credits_label.anchor_right = 0.0
    credits_label.anchor_top = 1.0
    credits_label.anchor_bottom = 1.0
    credits_label.offset_left = 28.0
    credits_label.offset_right = 270.0
    credits_label.offset_top = -126.0
    credits_label.offset_bottom = -100.0

    items_panel.anchor_left = 1.0
    items_panel.anchor_right = 1.0
    items_panel.anchor_top = 1.0
    items_panel.anchor_bottom = 1.0
    items_panel.offset_left = -250.0
    items_panel.offset_right = -20.0
    items_panel.offset_top = -238.0
    items_panel.offset_bottom = -20.0
    if mobile_profile:
        _layout_mobile_hud()
    # Outlines belong to UI, never to world-space decorative glyphs.
    for label in [health_text, credits_label, weapon_label, level_label, timer_label, difficulty_label, controls_label, get_node("HUD/Title")]:
        label.add_theme_color_override("font_outline_color", Color(0.005, 0.009, 0.014, 1.0))
        label.add_theme_constant_override("outline_size", 4)

func _layout_mobile_hud() -> void:
    # Leave the thumb areas free. Relic details remain available in SET.
    controls_label.visible = false
    items_panel.visible = false
    var title: Label = get_node("HUD/Title") as Label
    title.text = "ASCII//RAIN // DISTRICT 01"
    title.add_theme_font_size_override("font_size", 20)
    _top_left_box(health_bar, Rect2(26, 70, 240, 18))
    _top_left_box(health_text, Rect2(26, 92, 120, 28))
    _top_left_box(level_label, Rect2(26, 121, 80, 25))
    _top_left_box(xp_bar, Rect2(112, 128, 154, 10))
    _top_left_box(credits_label, Rect2(26, 148, 250, 24))
    _top_left_box(weapon_label, Rect2(26, 176, 440, 26))
    var archive: Label = get_node_or_null("HUD/RealityArchive") as Label
    if archive != null:
        _top_left_box(archive, Rect2(26, 207, 330, 24))
        archive.add_theme_font_size_override("font_size", 14)
    interaction_label.offset_top = -302.0
    interaction_label.offset_bottom = -270.0
    for label in [health_text, level_label, credits_label, weapon_label, objective_label]:
        label.add_theme_color_override("font_outline_color", Color(0.005, 0.01, 0.015, 0.95))
        label.add_theme_constant_override("outline_size", 4)

func _top_left_box(control: Control, rect: Rect2) -> void:
    control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    control.position = rect.position
    control.size = rect.size
    control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_encounter_director() -> void:
    _encounter_director = ENCOUNTER_DIRECTOR.new() as EncounterDirector
    if _encounter_director == null:
        return
    _encounter_director.name = "EncounterDirector"
    add_child(_encounter_director)
    _encounter_director.configure(player as Node3D)
    _encounter_director.spawn_requested.connect(_on_director_spawn_requested)
    _encounter_director.district_entered.connect(_on_district_entered)

func _process(delta: float) -> void:
    _update_hit_stop()
    if Input.is_action_just_pressed("toggle_ascii"):
        ascii_rect.visible = not ascii_rect.visible
        if _readability_renderer != null:
            _readability_renderer.call("set_effect_enabled", ascii_rect.visible)

    if run_complete or player.health <= 0.0:
        interaction_label.text = ""
        return
    _update_interaction()
    if get_tree().paused:
        return

    elapsed += delta
    difficulty = 1.0 + elapsed / 104.0
    if _encounter_director != null:
        _encounter_director.set_difficulty(difficulty)

    var mins: int = int(elapsed) / 60
    var secs: int = int(elapsed) % 60
    timer_label.text = "%02d:%02d" % [mins, secs]
    difficulty_label.text = "THREAT  %.2f×   KILLS %d" % [difficulty, kills]
    if event_active and teleporter != null and not bool(teleporter.exit_ready):
        var field_status: String = "CHARGING" if bool(teleporter.is_player_in_field()) else "PAUSED // RETURN TO FIELD"
        if float(teleporter.charge) >= 100.0:
            field_status = "CHARGED // DEFEAT WATCHER"
        teleporter_text.text = "TELEPORTER %d%% // %s" % [int(teleporter.charge), field_status]

func request_hit_stop(milliseconds: int) -> void:
    if run_complete or player.health <= 0.0 or get_tree().paused:
        return
    var capped_ms: int = clampi(milliseconds, 8, RuntimeProfile.hit_stop_max_ms)
    var now_ms: int = Time.get_ticks_msec()
    _hit_stop_until_msec = maxi(_hit_stop_until_msec, now_ms + capped_ms)
    if not _hit_stop_active:
        _hit_stop_active = true
        Engine.time_scale = 0.10 if not mobile_profile else 0.16

func _update_hit_stop() -> void:
    if not _hit_stop_active:
        return
    if Time.get_ticks_msec() >= _hit_stop_until_msec:
        _hit_stop_active = false
        _hit_stop_until_msec = 0
        Engine.time_scale = 1.0

func _exit_tree() -> void:
    Engine.time_scale = 1.0

func _on_director_spawn_requested(center: Vector3, count: int, intensity: float) -> void:
    if _sector_secured or run_complete or player.health <= 0.0:
        return
    for i in range(clampi(count, 0, 8)):
        if _spawn_requests.size() < 24:
            _spawn_requests.append({"center": center, "intensity": intensity, "zone": _encounter_director.get_encounter_zone() if _encounter_director != null else &""})

func _spawn_enemy_near(center: Vector3, intensity: float = 1.0, request: Dictionary = {}) -> void:
    if _sector_secured or run_complete or player.health <= 0.0:
        return
    var hard_cap: int = max_enemies + (22 if event_active else 0)
    if get_tree().get_nodes_in_group("enemies").size() >= hard_cap:
        return

    var archetype: int = int(request.get("type",-1))
    if archetype < 0:
        if not event_active and _encounter_director != null:
            archetype = DISTRICT_RULES.select_enemy(_encounter_director.get_current_district_id(),_encounter_director.get_encounter_zone(),elapsed,rng)
        else:
            archetype = _choose_enemy_type()
    var elite_kind: int = ELITE_NONE
    var elite_chance: float = 0.0
    if elapsed > 42.0:
        elite_chance = minf(0.22, 0.03 + (difficulty - 1.0) * 0.04 + maxf(0.0, intensity - 1.0) * 0.08)
    if rng.randf() < elite_chance:
        elite_kind = ELITE_OVERCHARGED if rng.randf() < 0.52 else ELITE_VOLATILE

    var placement: Dictionary = {}
    var living: Node = get_tree().get_first_node_in_group("living_city")
    var zone: StringName = _encounter_director.get_encounter_zone() if _encounter_director != null else &""
    var on_upper: bool = living != null and bool(living.call("requires_authored_spawn", zone))
    if not event_active and living != null and not zone.is_empty():
        var points: Array[Vector3] = living.call("anchors_for",zone)
        placement = SPAWN_PLACEMENT.find_authored(_street_navigation,points,player.global_position,rng,12.0 if on_upper else 18.0)
    if placement.is_empty() and not on_upper:
        placement = SPAWN_PLACEMENT.find_street(get_world_3d(), center, player.global_position, rng, event_active)
    if placement.is_empty():
        _spawn_failures += 1
        return
    if _street_navigation != null:
        placement = _street_navigation.spawn_anchor(placement["position"], player.global_position, 12.0 if on_upper else 18.0)
        if placement.is_empty():
            _spawn_failures += 1
            return
    var spawn_position: Vector3 = placement["position"]
    var enemy: CharacterBody3D = ENEMY_SCENE.instantiate() as CharacterBody3D
    if enemy == null:
        return
    add_child(enemy)
    enemy.global_position = spawn_position
    enemy.call("setup", archetype, elite_kind, difficulty * maxf(0.9, intensity))
    enemy.connect("died", Callable(self, "_on_enemy_died"))
    var event_owner: Node=request.get("owner",null) as Node
    if is_instance_valid(event_owner) and bool(event_owner.call("is_running")):
        event_owner.call("register_spawn",enemy)

func _on_district_entered(district_id: StringName, district_name: String, _center: Vector3) -> void:
    objective_label.text = "OBJECTIVE  —  EXPLORE // %s" % district_name
    _show_upgrade_text("LOCATION DISCOVERED // %s" % district_name)
    if _run_guide != null:
        _run_guide.call("on_district_visit", district_id)

func _choose_enemy_type() -> int:
    var roll: float = rng.randf()
    if elapsed < 12.0:
        return ENEMY_GRUNT if roll < 0.76 else ENEMY_SKITTER
    if elapsed < 30.0:
        if roll < 0.52:
            return ENEMY_GRUNT
        if roll < 0.78:
            return ENEMY_SKITTER
        return ENEMY_GUNNER
    if elapsed < 55.0:
        if roll < 0.36:
            return ENEMY_GRUNT
        if roll < 0.58:
            return ENEMY_SKITTER
        if roll < 0.80:
            return ENEMY_GUNNER
        return ENEMY_BOMBER

    if roll < 0.27:
        return ENEMY_GRUNT
    if roll < 0.45:
        return ENEMY_SKITTER
    if roll < 0.66:
        return ENEMY_GUNNER
    if roll < 0.84:
        return ENEMY_BOMBER
    return ENEMY_TANK

func _spawn_chests() -> void:
    var positions: Array[Vector3] = [
        Vector3(-12, 0.55, 8), Vector3(11, 0.55, 7),
        Vector3(51, 0.55, -22), Vector3(64.6, 5.53, -24),
        Vector3(-39, -5.97, -12), Vector3(-73, -5.97, -31),
        Vector3(38, 0.55, 43), Vector3(40, 5.53, 58.6),
        Vector3(-67, 2.78, 43), Vector3(-39, 5.53, 68.0),
        Vector3(-33, 10.03, -59), Vector3(13, 10.03, -77),
        Vector3(-3, 0.55, 58), Vector3(16, 5.53, 64)
    ]
    if location_profile == "threshold_market":
        positions = [
            Vector3(44, 0.55, 26), Vector3(40, 5.53, 58.6),
            Vector3(70, 0.55, 59)
        ]
    for i in range(positions.size()):
        var chest: Node3D = CHEST_SCENE.instantiate() as Node3D
        if chest == null:
            continue
        chest.set("cost", 0 if i == 0 else 20 + i * 4)
        chest.set("starter_cache", i == 0)
        if i == 0:
            _starter_cache = chest
        add_child(chest)
        chest.global_position = positions[i]
        chest.rotation.y = rng.randf_range(0.0, TAU)

func _spawn_teleporter() -> void:
    teleporter = TELEPORTER_SCENE.instantiate()
    add_child(teleporter)
    teleporter.global_position = Vector3(57.5, 0.15, 62.0) if location_profile == "threshold_market" else Vector3(0.0, 0.15, -56.0)
    teleporter.activated.connect(_on_teleporter_activated)
    teleporter.charge_changed.connect(_on_teleporter_charge_changed)
    teleporter.charge_complete.connect(_on_teleporter_charge_complete)
    teleporter.ready_to_exit.connect(_on_teleporter_ready)
    teleporter.exited.connect(_on_teleporter_exited)

func _on_teleporter_activated() -> void:
    event_active = true
    AudioManager.play_portal_signal()
    var audio_lighting: Node = get_node_or_null("AudioReactiveLighting")
    if audio_lighting != null:
        audio_lighting.call("trigger_portal_chaos", teleporter)
    if _run_guide != null:
        _run_guide.call("on_event_started")
    if _encounter_director != null:
        _encounter_director.set_event_active(true, teleporter.global_position)
    teleporter_bar.visible = true
    teleporter_text.visible = true
    teleporter_bar.value = 0.0
    teleporter_text.text = "TELEPORTER  0%"
    objective_label.text = "OBJECTIVE  —  STAY IN FIELD / ELIMINATE WATCHER"
    _show_upgrade_text("TELEPORTER SIGNAL LOCKED")
    _spawn_boss()

func _on_teleporter_charge_changed(value: float) -> void:
    teleporter_bar.value = value
    teleporter_text.text = "TELEPORTER  %d%%" % int(value)

func _on_teleporter_charge_complete() -> void:
    if _run_guide != null:
        _run_guide.call("on_charge_finished")
    objective_label.text = "OBJECTIVE  —  ELIMINATE WATCHER" if is_instance_valid(boss) else "OBJECTIVE  —  TELEPORTER READY"
    _show_upgrade_text("TELEPORTER CHARGE COMPLETE")

func _on_teleporter_ready() -> void:
    _sector_secured = true
    _stop_hostile_activity(true)
    event_active = false
    if _encounter_director != null:
        _encounter_director.set_event_active(false)
    objective_label.text = "OBJECTIVE  —  ENTER TELEPORTER"
    teleporter_text.text = "TELEPORTER READY"
    _show_upgrade_text("DISTRICT EXIT OPEN")

func _on_teleporter_exited() -> void:
    if run_complete or player.health <= 0.0:
        return
    run_complete = true
    _stop_hostile_activity(false)
    if _run_guide != null:
        _run_guide.call("finish", true)
    player.control_enabled = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    complete_panel.visible = true
    if _reticle != null:
        _reticle.visible = false
    if _encounter_director != null:
        _encounter_director.set_process(false)
    var summary: Label = complete_panel.get_node("Summary") as Label
    summary.text = "DISTRICT CLEARED\nTIME  %02d:%02d   KILLS  %d   LV.%d\nCREDITS  %d" % [int(elapsed) / 60, int(elapsed) % 60, kills, player.level, player.credits]
    if _run_guide != null:
        summary.text = String(_run_guide.call("summary", true))
    interaction_label.text = ""
    objective_label.text = "RUN COMPLETE"
    GameEvents.run_ended.emit(true)

func _spawn_boss() -> void:
    if is_instance_valid(boss):
        return
    boss = BOSS_SCENE.instantiate()
    add_child(boss)
    boss.global_position = teleporter.global_position + Vector3(0.0, 0.5, -10.0)
    boss.setup(maxf(1.0, difficulty * 0.92))
    boss.health_changed.connect(_on_boss_health_changed)
    boss.phase_changed.connect(_on_boss_phase_changed)
    boss.died.connect(_on_boss_died)
    _boss_phase_label = "PHASE 01 // OBSERVER"
    boss_panel.visible = true
    _on_boss_health_changed(boss.health, boss.max_health)

func _on_boss_health_changed(current: float, maximum: float) -> void:
    boss_bar.max_value = maximum
    boss_bar.value = current
    boss_text.text = "WATCHER // %s   %d / %d" % [_boss_phase_label, int(ceil(current)), int(ceil(maximum))]

func _on_boss_phase_changed(phase: int, label: String) -> void:
    _boss_phase_label = "PHASE %02d // %s" % [phase, label]
    if is_instance_valid(boss):
        _on_boss_health_changed(float(boss.health), float(boss.max_health))
    objective_label.text = "OBJECTIVE  —  SURVIVE OVERWRITE / ELIMINATE WATCHER"
    _show_upgrade_text("WATCHER // PHASE %02d // %s" % [phase, label])

func _on_boss_died(_boss: Node, xp_reward: int, credit_reward: int) -> void:
    kills += 1
    player.add_xp(xp_reward)
    player.add_credits(credit_reward)
    boss_panel.visible = false
    boss = null
    _spawn_requests.clear()
    if _encounter_director != null:
        _encounter_director.set_process(false)
    if _run_guide != null:
        _run_guide.call("on_boss_defeated")
    if teleporter != null:
        teleporter.set_boss_dead()
    objective_label.text = "OBJECTIVE  —  CHARGE TELEPORTER" if teleporter.charge < 100.0 else "OBJECTIVE  —  ENTER TELEPORTER"
    _show_upgrade_text("WATCHER DESTROYED")

func _on_enemy_died(_enemy: Node, xp_reward: int, credit_reward: int) -> void:
    kills += 1
    player.add_xp(xp_reward)
    player.add_credits(credit_reward)

func _update_interaction() -> void:
    if get_tree().paused or not bool(player.call("can_interact_now")):
        interaction_label.text = ""
        return
    _nearest_interactable = null
    var nearest_distance: float = 3.5
    for node in get_tree().get_nodes_in_group("interactables"):
        if not is_instance_valid(node) or not (node is Node3D):
            continue
        var node_3d: Node3D = node as Node3D
        var distance: float = player.global_position.distance_to(node_3d.global_position)
        if distance < nearest_distance and _has_interaction_sight(node_3d):
            nearest_distance = distance
            _nearest_interactable = node_3d

    if _nearest_interactable != null and _nearest_interactable.has_method("get_interaction_text"):
        interaction_label.text = _nearest_interactable.get_interaction_text(player)
        if Input.is_action_just_pressed("interact") and not run_complete and player.health > 0.0:
            _nearest_interactable.interact(player)
    else:
        interaction_label.text = ""


func _build_damage_feedback() -> void:
    var feedback: ColorRect = DAMAGE_FEEDBACK.new() as ColorRect
    if feedback == null:
        return
    feedback.name = "DamageFeedback"
    $HUD.add_child(feedback)
    _damage_feedback = feedback

func _on_player_damaged(amount: float) -> void:
    if _damage_feedback != null and _damage_feedback.has_method("flash"):
        var ratio: float = amount / maxf(1.0, float(player.max_health))
        _damage_feedback.call("flash", ratio)
    request_hit_stop(22 if not mobile_profile else 14)

func _on_health_changed(current: float, maximum: float) -> void:
    health_bar.max_value = maximum
    health_bar.value = current
    health_text.text = "%d / %d" % [int(ceil(current)), int(ceil(maximum))]

func _on_xp_changed(current: int, needed: int, current_level: int) -> void:
    xp_bar.max_value = needed
    xp_bar.value = current
    level_label.text = "LV.%02d" % current_level

func _on_credits_changed(current: int) -> void:
    credits_label.text = "CREDITS  %04d¢" % current

func _on_inventory_changed(summary: String) -> void:
    items_label.text = summary

func _on_weapon_changed(name: String, detail: String) -> void:
    weapon_label.text = "WPN  %s // %s" % [name, detail]

func _on_upgrade_announced(text: String) -> void:
    _show_upgrade_text(text)

func _show_upgrade_text(text: String) -> void:
    upgrade_label.text = text
    upgrade_label.modulate.a = 1.0
    if _upgrade_tween != null and _upgrade_tween.is_valid():
        _upgrade_tween.kill()
    _upgrade_tween = create_tween()
    _upgrade_tween.tween_interval(2.8)
    _upgrade_tween.tween_property(upgrade_label, "modulate:a", 0.0, 0.55)

func _on_player_died() -> void:
    _stop_hostile_activity(false)
    if teleporter != null:
        teleporter.set_process(false)
    if _run_guide != null:
        _run_guide.call("finish", false)
    death_panel.visible = true
    if _reticle != null:
        _reticle.visible = false
    if _encounter_director != null:
        _encounter_director.set_process(false)
    GameEvents.run_ended.emit(false)
    var summary: Label = death_panel.get_node("Summary") as Label
    summary.text = "RUN TERMINATED\nTIME  %02d:%02d   KILLS  %d   LV.%d\nCREDITS  %d" % [int(elapsed) / 60, int(elapsed) % 60, kills, player.level, player.credits]
    if _run_guide != null:
        summary.text = String(_run_guide.call("summary", false))

func _on_restart_pressed() -> void:
    get_tree().paused = false
    Engine.time_scale = 1.0
    get_tree().reload_current_scene()

func _build_readability_pass() -> void:
    _readability_renderer = READABILITY_RENDERER.new()
    _readability_renderer.name = "ReadabilityRenderer"
    add_child(_readability_renderer)
    _readability_renderer.call("configure", player.get_node("CameraPivot/SpringArm3D/Camera3D"))
    var detail_pass: Node3D = CITY_DETAIL_PASS.new() as Node3D
    detail_pass.name = "CityDetailPass"
    $City.add_child(detail_pass)

func _physics_process(_delta: float) -> void:
    if run_complete or _sector_secured or player.health <= 0.0:
        _spawn_requests.clear()
        return
    if _street_navigation != null and not _street_navigation.built:
        return
    # At most two spawn-placement attempts per physics tick, including failures.
    for request_index in range(mini(2, _spawn_requests.size())):
        var entry: Dictionary = _spawn_requests.pop_front()
        if not event_active and _encounter_director != null and entry.get("zone",&"") != _encounter_director.get_encounter_zone():
            continue
        var event_owner: Node=entry.get("owner",null) as Node
        if entry.has("owner") and (not is_instance_valid(event_owner) or not bool(event_owner.call("is_running"))):
            continue
        var center: Vector3 = entry["center"]
        _spawn_enemy_near(center, float(entry["intensity"]), entry)

func _build_run_loop() -> void:
    _relic_choice = RELIC_CHOICE.new() as CanvasLayer
    _relic_choice.name = "RelicChoice"
    add_child(_relic_choice)
    _run_guide = RUN_GUIDE.new() as Node
    _run_guide.name = "RunGuide"
    add_child(_run_guide)
    _run_guide.call("configure", self, player, teleporter, _starter_cache)
    _relic_choice.connect("committed", Callable(_run_guide, "on_cache_claimed"))
    _configure_result_panels()
    get_viewport().size_changed.connect(_configure_result_panels)

func open_relic_choice(cache: Node3D, actor: Node3D, cost: int, starter: bool) -> bool:
    if run_complete or player.health <= 0.0 or _relic_choice == null:
        return false
    if not is_instance_valid(cache) or actor != player:
        return false
    var inventory: InventoryComponent = player.get_node("InventoryComponent") as InventoryComponent
    var offered: Array[StringName] = []
    var stored: Array = cache.get("cached_offer")
    if stored.is_empty():
        offered = RELIC_OFFERS.make_offer(inventory, rng, starter)
        cache.set("cached_offer", offered.duplicate())
    else:
        for item_id in stored:
            if inventory.can_grant(StringName(item_id)):
                offered.append(StringName(item_id))
    if offered.is_empty():
        player.announce("THIS CACHE HAS NO AVAILABLE RELICS")
        return false
    _hit_stop_active = false
    _hit_stop_until_msec = 0
    Engine.time_scale = 1.0
    return bool(_relic_choice.call("offer", cache, actor, offered, cost, starter))

func _has_interaction_sight(target: Node3D) -> bool:
    var start: Vector3 = player.global_position + Vector3.UP * 1.25
    var finish: Vector3 = target.global_position + Vector3.UP * 0.70
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, finish, 1)
    query.exclude = [player.get_rid()]
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return true
    var collider: Node = hit.get("collider") as Node
    return collider == target or (collider != null and target.is_ancestor_of(collider))

func _stop_hostile_activity(dissolve: bool) -> void:
    _spawn_requests.clear()
    _hit_stop_active = false
    _hit_stop_until_msec = 0
    Engine.time_scale = 1.0
    if _encounter_director != null:
        _encounter_director.set_process(false)
    for projectile in get_tree().get_nodes_in_group("hostile_projectiles"):
        projectile.call("_request_recycle")
    for hazard in get_tree().get_nodes_in_group("hostile_hazards"):
        hazard.call("cancel")
    for cue in get_tree().get_nodes_in_group("hostile_cues"):
        if is_instance_valid(cue) and not cue.is_queued_for_deletion():
            cue.queue_free()
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
            continue
        enemy.set_physics_process(false)
        enemy.set_process(false)
        enemy.set_deferred("collision_layer", 0)
        enemy.set_deferred("collision_mask", 0)
        if dissolve:
            enemy.remove_from_group("enemies")
            var fade: Tween = create_tween()
            fade.tween_property(enemy, "scale", Vector3.ONE * 0.01, 0.35)
            fade.tween_callback(enemy.queue_free)

func _configure_result_panels() -> void:
    var view: Vector2 = get_viewport().get_visible_rect().size
    var width: float = minf(620.0, view.x - 32.0)
    var height: float = minf(300.0, view.y - 32.0)
    for panel in [death_panel, complete_panel]:
        panel.offset_left = -width * 0.5
        panel.offset_right = width * 0.5
        panel.offset_top = -height * 0.5
        panel.offset_bottom = height * 0.5
        var summary: Label = panel.get_node("Summary") as Label
        summary.offset_left = 16.0
        summary.offset_right = -16.0
        summary.offset_top = 18.0
        summary.offset_bottom = height - 86.0
        summary.add_theme_font_size_override("font_size", 17)
        summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    objective_label.anchor_left = 0.5
    objective_label.anchor_right = 0.5
    var goal_width: float = minf(740.0, view.x - 48.0)
    objective_label.offset_left = -goal_width * 0.5
    objective_label.offset_right = goal_width * 0.5
    objective_label.offset_top = 89.0
    objective_label.offset_bottom = 119.0
    objective_label.add_theme_font_size_override("font_size", 14)

func queue_district_wave(owner_node: Node, district: StringName, types: Array[int]) -> void:
    if _sector_secured or run_complete or event_active or float(player.health)<=0.0:
        return
    if _encounter_director==null or _encounter_director.get_current_district_id()!=district:
        return
    for enemy_type in types:
        if _spawn_requests.size()<24:
            _spawn_requests.append({"center":player.global_position,"intensity":1.0,
                "zone":_encounter_director.get_encounter_zone(),"type":clampi(enemy_type,0,4),
                "owner":owner_node,"event_district":district})

func pending_district_spawns(district: StringName) -> int:
    var count: int=0
    for request in _spawn_requests:
        if request.get("event_district",&"")==district: count+=1
    return count
