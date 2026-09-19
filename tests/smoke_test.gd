extends SceneTree

# Execute after the editor import: godot --headless --path . --script res://tests/smoke_test.gd
# This exercises GDScript and game logic, NOT GPU shader compilation.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var result: Error = change_scene_to_file("res://scenes/Main.tscn")
    if result != OK:
        _fail("Main scene could not be requested")
        return
    for i in range(12):
        await physics_frame
    if current_scene == null:
        _fail("Main scene did not instantiate")
        return
    var player: CharacterBody3D = current_scene.get_node("Player") as CharacterBody3D
    if player == null:
        _fail("Player is missing")
        return
    player.set("_invulnerability_timer", 60.0)
    var origin: Vector3 = player.global_position
    Input.action_press("move_forward", 0.4)
    for i in range(45):
        await physics_frame
    Input.action_release("move_forward")
    if player.global_position.distance_to(origin) < 0.1:
        _fail("Movement did not advance")
        return
    player.call("grant_item", "chain_arc")
    if int(player.call("get_item_stack", "chain_arc")) != 1:
        _fail("Inventory stack regression")
        return
    var settings: Node = root.get_node("SettingsManager")
    settings.call("update_readability", 0.63)
    settings.call("update_camera_motion", 0.20)
    settings.call("update_depth_contours", false)
    settings.call("update_depth_contours", true)
    var menu: Node = current_scene.get_node("SettingsMenu")
    menu.call("set_open", true)
    await process_frame
    if not paused:
        _fail("Settings menu did not pause")
        return
    menu.call("_toggle_preview")
    await process_frame
    if not paused or bool(menu.get("_panel").visible):
        _fail("Graphics preview must hide the panel without resuming the run")
        return
    menu.call("_toggle_preview")
    settings.call("update_ascii_cell", 4.0)
    var material: ShaderMaterial = current_scene.get_node("PostFX/ASCII").material as ShaderMaterial
    var mask: Texture2D = material.get_shader_parameter("glyph_atlas") as Texture2D
    if mask == null or mask.get_width() != 128 or mask.get_height() != 6:
        _fail("4px cell did not receive its prefiltered 4x6 atlas")
        return
    settings.call("update_ascii_cell", 1.0)
    mask = material.get_shader_parameter("glyph_atlas") as Texture2D
    if not is_equal_approx(float(material.get_shader_parameter("cell_px")), 1.0) or mask == null or mask.get_width() != 32 or mask.get_height() != 2:
        _fail("1px micro-code did not receive its native 1x2 atlas")
        return
    settings.call("reset_readability")
    menu.call("set_open", false)
    var director: Node = current_scene.get_node("EncounterDirector")
    director.set("_startup_grace", 0.0)
    player.global_position = Vector3(50.0, 0.1, -20.0)
    for i in range(210):
        await physics_frame
    if get_nodes_in_group("enemies").size() < 2:
        _fail("District first wave did not spawn")
        return
    Input.action_press("shoot")
    for i in range(45):
        await physics_frame
    Input.action_release("shoot")
    print("ENGINE_SMOKE_OK: movement, settings, pause, item, district wave, shooting")
    root.get_node("AudioManager").call("stop_all")
    for cleanup_frame in range(12):
        await physics_frame
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
