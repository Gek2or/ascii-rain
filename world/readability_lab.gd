extends Node3D

const ATLAS_BINDING = preload("res://rendering/ascii_atlas_binding.gd")

const ENEMY: PackedScene = preload("res://scenes/Enemy.tscn")
const SETTINGS = preload("res://ui/settings_menu.gd")
const RETICLE = preload("res://ui/reticle.gd")
const METRICS = preload("res://ui/performance_overlay.gd")
const READABILITY = preload("res://rendering/readability_controller.gd")
const DAMAGE = preload("res://components/damage_feedback.gd")

var _targets_down: int = 0
var _status: Label = null
var _weapon_text: Label = null
var _feedback: DamageFeedback = null
var _readability: Node = null
var _robot_positions: Array[Vector3] = [Vector3(-6, 0.03, -5), Vector3(0, 0.03, -5), Vector3(6, 0.03, -5)]
@onready var player: CharacterBody3D = $Player

func _ready() -> void:
    _build_courtyard()
    _build_ui()
    _readability = READABILITY.new()
    add_child(_readability)
    _readability.call("configure", player.get_node("CameraPivot/SpringArm3D/Camera3D"))
    SettingsManager.changed.connect(_apply_settings)
    _apply_settings()
    player.connect("weapon_changed", _on_weapon_changed)
    player.call("refresh_weapon_ui")
    for i in range(_robot_positions.size()):
        _spawn_target(_robot_positions[i], i)

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("toggle_ascii"):
        $PostFX/ASCII.visible = not $PostFX/ASCII.visible
        _readability.call("set_effect_enabled", $PostFX/ASCII.visible)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key: InputEventKey = event as InputEventKey
        if key.pressed and not key.echo and key.keycode == KEY_F6:
            _test_flash()
            get_viewport().set_input_as_handled()

func _apply_settings() -> void:
    RuntimeProfile.refresh()
    var material: ShaderMaterial = $PostFX/ASCII.material as ShaderMaterial
    material.set_shader_parameter("cell_px", SettingsManager.ascii_cell_px)
    material.set_shader_parameter("glyph_gain", SettingsManager.glyph_gain)
    material.set_shader_parameter("exposure", RuntimeProfile.ascii_exposure)
    material.set_shader_parameter("edge_gain", SettingsManager.edge_gain)
    material.set_shader_parameter("bloom_strength", SettingsManager.bloom_strength)
    material.set_shader_parameter("readability", SettingsManager.readability_strength)
    material.set_shader_parameter("background_calm", SettingsManager.background_calm)
    material.set_shader_parameter("color_saturation", SettingsManager.color_saturation)
    ATLAS_BINDING.apply(material, SettingsManager.ascii_cell_px)
    get_viewport().scaling_3d_scale = SettingsManager.render_scale
    $MoonLight.shadow_enabled = RuntimeProfile.dynamic_shadow_enabled
    var environment: Environment = $WorldEnvironment.environment
    environment.ambient_light_energy = 0.95 * SettingsManager.lighting_boost

func _build_courtyard() -> void:
    var street: StandardMaterial3D = _material(Color(0.18, 0.21, 0.24))
    var dark_wall: StandardMaterial3D = _material(Color(0.065, 0.075, 0.09))
    var grey_wall: StandardMaterial3D = _material(Color(0.31, 0.33, 0.35))
    var window: StandardMaterial3D = _material(Color(0.85, 0.58, 0.21), true)
    _box("Floor", Vector3(0, -0.25, 0), Vector3(38, 0.5, 38), street, true)
    _box("ShadowWall", Vector3(-6, 2.6, -7.7), Vector3(5.8, 5.2, 0.6), dark_wall, true)
    _box("BacklitWall", Vector3(0, 2.6, -7.7), Vector3(5.8, 5.2, 0.6), grey_wall, true)
    _box("MidtoneWall", Vector3(6, 2.6, -7.7), Vector3(5.8, 5.2, 0.6), grey_wall, true)
    for i in range(5):
        _box("Window", Vector3(-2.15 + i * 1.06, 2.5, -7.31), Vector3(0.76, 3.5, 0.10), window, false)
    _box("CornerCover", Vector3(-3.1, 1.15, 2.5), Vector3(1.4, 2.3, 3.1), grey_wall, true)
    _box("LowCover", Vector3(2.9, 0.65, 2.0), Vector3(2.8, 1.3, 1.0), grey_wall, true)
    _box("RampLanding", Vector3(11.0, 1.85, -1.0), Vector3(4.0, 0.3, 4.0), street, true)
    var ramp: Node3D = _box("Ramp", Vector3(11.0, 0.95, 4.9), Vector3(4.0, 0.20, sqrt(68.0)), street, true)
    ramp.rotation.x = atan2(2.0, 8.0)
    for side in [-1.0, 1.0]:
        _box("Boundary", Vector3(side * 18.0, 1.1, 0.0), Vector3(0.4, 2.2, 38.0), dark_wall, true)
        _box("Boundary", Vector3(0.0, 1.1, side * 18.0), Vector3(36.0, 2.2, 0.4), dark_wall, true)
    _sign("01 // SHADOW", Vector3(-6.0, 5.7, -7.3))
    _sign("02 // BACKLIGHT", Vector3(0.0, 5.7, -7.3))
    _sign("03 // MIDTONE", Vector3(6.0, 5.7, -7.3))
    _sign("RAMP", Vector3(11.0, 3.0, -1.0))

func _material(color: Color, unlit: bool = false) -> StandardMaterial3D:
    var result: StandardMaterial3D = StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.82
    if unlit:
        result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return result

func _box(label: String, center: Vector3, dimensions: Vector3, material: Material, collision: bool) -> Node3D:
    var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
    root.name = label
    root.position = center
    add_child(root)
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = dimensions
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = material
    root.add_child(visual)
    if collision:
        var shape: BoxShape3D = BoxShape3D.new()
        shape.size = dimensions
        var collider: CollisionShape3D = CollisionShape3D.new()
        collider.shape = shape
        root.add_child(collider)
    return root

func _sign(text: String, at: Vector3) -> void:
    var label: Label3D = Label3D.new()
    label.text = text
    label.font_size = 40
    label.pixel_size = 0.014
    label.modulate = Color(0.76, 0.82, 0.85)
    label.position = at
    add_child(label)

func _spawn_target(at: Vector3, archetype: int) -> void:
    if not is_inside_tree():
        return
    var target: CharacterBody3D = ENEMY.instantiate() as CharacterBody3D
    target.position = at
    target.rotation.y = PI
    add_child(target)
    target.call("setup", archetype, 0, 1.0)
    target.set_physics_process(false)
    target.add_to_group("practice_targets")
    target.connect("died", _on_target_down.bind(at, archetype))

func _on_target_down(_target: Node, _xp: int, _credits: int, at: Vector3, archetype: int) -> void:
    _targets_down += 1
    _status.text = "FIXED TARGETS // %d DOWN // NO WAVES / NO SAVE PROGRESS" % _targets_down
    get_tree().create_timer(1.8).timeout.connect(_spawn_target.bind(at, archetype))

func _build_ui() -> void:
    var heading: Label = _label("TEST COURTYARD // CLARITY & CONTROLS", Vector2(26, 22), 22)
    heading.add_theme_constant_override("outline_size", 4)
    _status = _label("FIXED TARGETS // NO WAVES / NO SAVE PROGRESS", Vector2(26, 57), 15)
    _label("Dark wall / bright windows / ramp / corner cover\nFIRE + drag = aim. AIM toggles precision. PC: F6 tests hit flash.", Vector2(26, 90), 16)
    _weapon_text = _label("", Vector2(26, 150), 16)
    var reticle: Control = RETICLE.new() as Control
    $HUD.add_child(reticle)
    var menu: CanvasLayer = SETTINGS.new() as CanvasLayer
    menu.name = "SettingsMenu"
    add_child(menu)
    var metrics: CanvasLayer = METRICS.new() as CanvasLayer
    add_child(metrics)
    _feedback = DAMAGE.new() as DamageFeedback
    $HUD.add_child(_feedback)
    var flash_button: Button = Button.new()
    flash_button.text = "TEST HIT FLASH"
    flash_button.anchor_left = 1.0
    flash_button.anchor_right = 1.0
    flash_button.offset_left = -252.0
    flash_button.offset_right = -100.0
    flash_button.offset_top = 76.0
    flash_button.offset_bottom = 122.0
    flash_button.focus_mode = Control.FOCUS_NONE
    flash_button.pressed.connect(_test_flash)
    $HUD.add_child(flash_button)

func _label(text: String, at: Vector2, font_size: int) -> Label:
    var result: Label = Label.new()
    result.position = at
    result.text = text
    result.mouse_filter = Control.MOUSE_FILTER_IGNORE
    result.add_theme_font_size_override("font_size", font_size)
    result.add_theme_color_override("font_outline_color", Color(0.005, 0.01, 0.02, 0.9))
    result.add_theme_constant_override("outline_size", 3)
    $HUD.add_child(result)
    return result

func _test_flash() -> void:
    _feedback.flash(0.15)
    AudioManager.play_damage()

func _on_weapon_changed(name: String, detail: String) -> void:
    _weapon_text.text = "%s // %s" % [name, detail]

func _exit_tree() -> void:
    Engine.time_scale = 1.0
