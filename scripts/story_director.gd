extends Node

const ARTIFACT_SCENE = preload("res://scenes/RealityArtifact.tscn")
const SAVE_PATH = "user://ascii_rain_profile.cfg"

var fragments_found = 0
var fragments_total = 2
var _overlay_layer: CanvasLayer
var _overlay: Control
var _archive_label: Label
var _artifact_root: Node3D
var _player: Node
var _inspection_open = false
var _pause_before_inspection: bool = false
var _control_before_inspection: bool = true
var _unlocked_fragments: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_to_group("story_director")
    _player = get_parent().get_node_or_null("Player")
    _load_profile()
    if not GameEvents.boss_killed.is_connected(_on_boss_killed):
        GameEvents.boss_killed.connect(_on_boss_killed)
    _build_archive_hud()
    _build_inspection_overlay()
    call_deferred("_spawn_story_artifact")

func _process(delta: float) -> void:
    if _inspection_open and is_instance_valid(_artifact_root):
        _artifact_root.rotation.y += delta * 0.26
        _artifact_root.rotation.x = sin(Time.get_ticks_msec() * 0.00045) * 0.06

func _unhandled_input(event: InputEvent) -> void:
    if not _inspection_open:
        return
    if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_E):
        _close_inspection()
        get_viewport().set_input_as_handled()

func _spawn_story_artifact() -> void:
    if not bool(_unlocked_fragments.get("memory_01", false)):
        _spawn_artifact_instance(
            "memory_01",
            "PHOTOGRAPH // FAMILY IN SUNLIGHT",
            "A physical image. No glyph layer. No system provenance.",
            Vector3(-44.0, 0.02, 43.0),
            deg_to_rad(12.0)
        )

func _spawn_artifact_instance(artifact_id: String, display_name: String, short_hint: String, position: Vector3, yaw: float) -> void:
    var artifact: Node3D = ARTIFACT_SCENE.instantiate() as Node3D
    if artifact == null:
        return
    artifact.set("artifact_id", artifact_id)
    artifact.set("display_name", display_name)
    artifact.set("short_hint", short_hint)
    get_parent().add_child(artifact)
    artifact.global_position = position
    artifact.rotation.y = yaw

func _on_boss_killed(_boss: Node, _xp_reward: int, _credit_reward: int) -> void:
    if bool(_unlocked_fragments.get("memory_02", false)):
        return
    call_deferred(
        "_spawn_artifact_instance",
        "memory_02",
        "WOODEN TOY // WHEELED OBJECT",
        "Hand-shaped wood. Four wheels. No serial, no network identity, no owner record.",
        Vector3(7.0, 0.02, -52.0),
        deg_to_rad(-18.0)
    )

func _build_archive_hud() -> void:
    var hud = get_parent().get_node_or_null("HUD")
    if hud == null:
        return
    _archive_label = Label.new()
    _archive_label.name = "RealityArchive"
    _archive_label.offset_left = 26.0
    _archive_label.offset_top = 89.0
    _archive_label.offset_right = 330.0
    _archive_label.offset_bottom = 116.0
    _archive_label.add_theme_color_override("font_color", Color(0.55, 0.77, 0.96, 0.88))
    _archive_label.add_theme_font_size_override("font_size", 12)
    _archive_label.text = "REALITY ARCHIVE   %d / %d" % [fragments_found, fragments_total]
    hud.add_child(_archive_label)

func _build_inspection_overlay() -> void:
    _overlay_layer = CanvasLayer.new()
    _overlay_layer.name = "RealityInspection"
    _overlay_layer.layer = 130
    _overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    # A child ready callback cannot add a sibling while Main is assembling.
    add_child(_overlay_layer)

    _overlay = Control.new()
    _overlay.name = "Root"
    _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    _overlay_layer.add_child(_overlay)

    var veil = ColorRect.new()
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil.color = Color(0.002, 0.004, 0.008, 0.93)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.add_child(veil)

    var header = Label.new()
    header.name = "Header"
    header.anchor_left = 0.5
    header.anchor_right = 0.5
    header.offset_left = -320.0
    header.offset_top = 38.0
    header.offset_right = 320.0
    header.offset_bottom = 76.0
    header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    header.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
    header.add_theme_font_size_override("font_size", 23)
    header.text = "UNFILTERED PHYSICAL RECORD"
    _overlay.add_child(header)

    var warning = Label.new()
    warning.name = "Warning"
    warning.anchor_left = 0.5
    warning.anchor_right = 0.5
    warning.offset_left = -380.0
    warning.offset_top = 78.0
    warning.offset_right = 380.0
    warning.offset_bottom = 110.0
    warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    warning.add_theme_color_override("font_color", Color(1.0, 0.63, 0.38))
    warning.add_theme_font_size_override("font_size", 13)
    warning.text = "SYSTEM: GLYPH TRANSCODER BYPASSED // SOURCE HAS NO INDEX"
    _overlay.add_child(warning)

    var viewport_container = SubViewportContainer.new()
    viewport_container.name = "ArtifactViewportContainer"
    viewport_container.anchor_left = 0.5
    viewport_container.anchor_right = 0.5
    viewport_container.offset_left = -285.0
    viewport_container.offset_top = 126.0
    viewport_container.offset_right = 285.0
    viewport_container.offset_bottom = 488.0
    viewport_container.stretch = true
    _overlay.add_child(viewport_container)

    var viewport = SubViewport.new()
    viewport.name = "ArtifactViewport"
    viewport.size = Vector2i(640, 400)
    viewport.transparent_bg = false
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    viewport_container.add_child(viewport)

    var env_node = WorldEnvironment.new()
    var env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.055, 0.065, 0.085)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72, 0.76, 0.82)
    env.ambient_light_energy = 0.72
    env_node.environment = env
    viewport.add_child(env_node)

    var key_light = DirectionalLight3D.new()
    key_light.rotation_degrees = Vector3(-34.0, -28.0, 0.0)
    key_light.light_color = Color(1.0, 0.92, 0.80)
    key_light.light_energy = 1.7
    key_light.shadow_enabled = true
    viewport.add_child(key_light)

    var fill = OmniLight3D.new()
    fill.position = Vector3(-2.2, 1.2, 2.8)
    fill.light_color = Color(0.45, 0.63, 1.0)
    fill.light_energy = 1.35
    fill.omni_range = 8.0
    viewport.add_child(fill)

    var camera = Camera3D.new()
    camera.position = Vector3(0.0, 0.2, 5.0)
    camera.fov = 45.0
    camera.current = true
    viewport.add_child(camera)

    _artifact_root = Node3D.new()
    _artifact_root.name = "PhysicalArtifact"
    viewport.add_child(_artifact_root)
    _build_physical_artifact(_artifact_root, "memory_01")

    var body_text = Label.new()
    body_text.name = "Body"
    body_text.anchor_left = 0.5
    body_text.anchor_right = 0.5
    body_text.offset_left = -420.0
    body_text.offset_top = 505.0
    body_text.offset_right = 420.0
    body_text.offset_bottom = 620.0
    body_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    body_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_text.add_theme_color_override("font_color", Color(0.86, 0.89, 0.94))
    body_text.add_theme_font_size_override("font_size", 15)
    body_text.text = ""
    _overlay.add_child(body_text)

    var close_button = Button.new()
    close_button.name = "Close"
    close_button.anchor_left = 0.5
    close_button.anchor_right = 0.5
    close_button.offset_left = -110.0
    close_button.offset_top = 632.0
    close_button.offset_right = 110.0
    close_button.offset_bottom = 680.0
    close_button.text = "RETURN TO SIGNAL"
    close_button.process_mode = Node.PROCESS_MODE_ALWAYS
    close_button.pressed.connect(_close_inspection)
    _overlay.add_child(close_button)

    _overlay.visible = false

func _build_physical_artifact(root: Node3D, artifact_id: String) -> void:
    for child in root.get_children():
        child.queue_free()
    if artifact_id == "memory_02":
        _build_physical_toy(root)
    else:
        _build_physical_photograph(root)

func _build_physical_toy(root: Node3D) -> void:
    var wood_mat: StandardMaterial3D = StandardMaterial3D.new()
    wood_mat.albedo_color = Color(0.58, 0.27, 0.09)
    wood_mat.roughness = 0.78

    var dark_wood_mat: StandardMaterial3D = StandardMaterial3D.new()
    dark_wood_mat.albedo_color = Color(0.21, 0.08, 0.025)
    dark_wood_mat.roughness = 0.72

    var body: MeshInstance3D = MeshInstance3D.new()
    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(2.55, 0.58, 1.15)
    body.mesh = body_mesh
    body.material_override = wood_mat
    body.position = Vector3(0.0, 0.05, 0.0)
    root.add_child(body)

    var cabin: MeshInstance3D = MeshInstance3D.new()
    var cabin_mesh: BoxMesh = BoxMesh.new()
    cabin_mesh.size = Vector3(1.05, 0.58, 0.95)
    cabin.mesh = cabin_mesh
    cabin.material_override = wood_mat
    cabin.position = Vector3(0.30, 0.56, 0.0)
    root.add_child(cabin)

    for side in [-1.0, 1.0]:
        for x in [-0.72, 0.72]:
            var wheel: MeshInstance3D = MeshInstance3D.new()
            var wheel_mesh: CylinderMesh = CylinderMesh.new()
            wheel_mesh.top_radius = 0.30
            wheel_mesh.bottom_radius = 0.30
            wheel_mesh.height = 0.18
            wheel.mesh = wheel_mesh
            wheel.material_override = dark_wood_mat
            wheel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
            wheel.position = Vector3(x, -0.27, side * 0.61)
            root.add_child(wheel)

    var scratch: MeshInstance3D = MeshInstance3D.new()
    var scratch_mesh: BoxMesh = BoxMesh.new()
    scratch_mesh.size = Vector3(0.80, 0.035, 0.03)
    scratch.mesh = scratch_mesh
    var scratch_mat: StandardMaterial3D = StandardMaterial3D.new()
    scratch_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    scratch_mat.albedo_color = Color(0.96, 0.80, 0.48)
    scratch.material_override = scratch_mat
    scratch.position = Vector3(-0.30, 0.07, -0.59)
    scratch.rotation.z = deg_to_rad(-8.0)
    root.add_child(scratch)

func _build_physical_photograph(root: Node3D) -> void:
    var frame_mat = StandardMaterial3D.new()
    frame_mat.albedo_color = Color(0.22, 0.10, 0.045)
    frame_mat.metallic = 0.05
    frame_mat.roughness = 0.62

    var photo_mat = StandardMaterial3D.new()
    photo_mat.albedo_color = Color(0.78, 0.88, 0.96)
    photo_mat.roughness = 0.88

    var frame = MeshInstance3D.new()
    var frame_mesh = BoxMesh.new()
    frame_mesh.size = Vector3(3.25, 2.15, 0.16)
    frame.mesh = frame_mesh
    frame.material_override = frame_mat
    root.add_child(frame)

    var photo = MeshInstance3D.new()
    var photo_mesh = BoxMesh.new()
    photo_mesh.size = Vector3(2.86, 1.76, 0.035)
    photo.mesh = photo_mesh
    photo.material_override = photo_mat
    photo.position = Vector3(0.0, 0.0, 0.105)
    root.add_child(photo)

    var sky = MeshInstance3D.new()
    var sky_mesh = BoxMesh.new()
    sky_mesh.size = Vector3(2.72, 0.96, 0.012)
    sky.mesh = sky_mesh
    var sky_mat = StandardMaterial3D.new()
    sky_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    sky_mat.albedo_color = Color(0.32, 0.66, 0.94)
    sky.material_override = sky_mat
    sky.position = Vector3(0.0, 0.36, 0.132)
    root.add_child(sky)

    var field = MeshInstance3D.new()
    var field_mesh = BoxMesh.new()
    field_mesh.size = Vector3(2.72, 0.72, 0.014)
    field.mesh = field_mesh
    var field_mat = StandardMaterial3D.new()
    field_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    field_mat.albedo_color = Color(0.24, 0.53, 0.22)
    field.material_override = field_mat
    field.position = Vector3(0.0, -0.49, 0.136)
    root.add_child(field)

    var sun = MeshInstance3D.new()
    var sun_mesh = SphereMesh.new()
    sun_mesh.radius = 0.16
    sun_mesh.height = 0.32
    sun.mesh = sun_mesh
    var sun_mat = StandardMaterial3D.new()
    sun_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    sun_mat.albedo_color = Color(1.0, 0.87, 0.36)
    sun_mat.emission_enabled = true
    sun_mat.emission = Color(1.0, 0.74, 0.20)
    sun_mat.emission_energy_multiplier = 1.8
    sun.material_override = sun_mat
    sun.position = Vector3(0.92, 0.53, 0.18)
    root.add_child(sun)

    for i in range(3):
        var person = MeshInstance3D.new()
        var body = CapsuleMesh.new()
        body.radius = 0.12 + i * 0.015
        body.height = 0.58 + i * 0.08
        person.mesh = body
        var pm = StandardMaterial3D.new()
        pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        pm.albedo_color = [Color(0.80, 0.22, 0.14), Color(0.93, 0.70, 0.18), Color(0.16, 0.28, 0.62)][i]
        person.material_override = pm
        person.position = Vector3(-0.55 + i * 0.55, -0.22 + (0.03 if i == 1 else 0.0), 0.18)
        root.add_child(person)

func present_artifact(artifact_id: String, display_name: String, short_hint: String) -> void:
    if _inspection_open or get_tree().paused or not get_tree().get_nodes_in_group("exclusive_ui").is_empty():
        return
    if not bool(_unlocked_fragments.get(artifact_id, false)):
        _unlocked_fragments[artifact_id] = true
        fragments_found = mini(fragments_total, fragments_found + 1)
        GameEvents.emit_reality_fragment_found(StringName(artifact_id))
        _save_profile()
    if is_instance_valid(_archive_label):
        _archive_label.text = "REALITY ARCHIVE   %d / %d" % [fragments_found, fragments_total]

    var header: Label = _overlay.get_node("Header") as Label
    header.text = display_name
    var body: Label = _overlay.get_node("Body") as Label
    _build_physical_artifact(_artifact_root, artifact_id)
    AudioManager.play_artifact()
    if artifact_id == "memory_02":
        body.text = "%s\n\nSYSTEM: object purpose unresolved.\nSUBJECT RESPONSE: The wheels were not for transport. They were for play.\nRecovered word: CHILDHOOD." % short_hint
    else:
        body.text = "%s\n\nThe system calls it corrupt data. But corruption does not cast a shadow.\nFor 0.7 seconds, the subject remembers the word: SUNLIGHT." % short_hint

    _pause_before_inspection = get_tree().paused
    _control_before_inspection = bool(_player.get("control_enabled")) if _player != null else false
    _inspection_open = true
    add_to_group("exclusive_ui")
    _overlay.visible = true
    if _player != null:
        _player.set("control_enabled", false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_tree().paused = true

func _close_inspection() -> void:
    if not _inspection_open:
        return
    _inspection_open = false
    _overlay.visible = false
    remove_from_group("exclusive_ui")
    get_tree().paused = _pause_before_inspection
    if _player != null:
        _player.set("control_enabled", _control_before_inspection)
        if _player.has_method("suppress_actions_after_ui"):
            _player.call("suppress_actions_after_ui")
    if not _is_mobile_runtime() and _control_before_inspection and not get_tree().paused:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _load_profile() -> void:
    var config = ConfigFile.new()
    var error = config.load(SAVE_PATH)
    if error != OK:
        fragments_found = 0
        return
    _unlocked_fragments["memory_01"] = bool(config.get_value("reality_archive", "memory_01", false))
    _unlocked_fragments["memory_02"] = bool(config.get_value("reality_archive", "memory_02", false))
    fragments_found = 0
    for fragment_id in ["memory_01", "memory_02"]:
        if bool(_unlocked_fragments.get(fragment_id, false)):
            fragments_found += 1

func _save_profile() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("reality_archive", "memory_01", bool(_unlocked_fragments.get("memory_01", false)))
    config.set_value("reality_archive", "memory_02", bool(_unlocked_fragments.get("memory_02", false)))
    config.save(SAVE_PATH)

func _is_mobile_runtime() -> bool:
    return OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS"

func has_fragment(artifact_id: String) -> bool:
    return bool(_unlocked_fragments.get(artifact_id, false))
