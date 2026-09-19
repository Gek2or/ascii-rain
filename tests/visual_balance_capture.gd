extends SceneTree
const LEGACY_BINDING = preload("res://tests/legacy_glyph_binding.gd")
# Native paused captures; ordinary start position, not generated art.
# No changed difficulty / fake FPS / artist-painted overlays.
func _initialize() -> void:
    if not OS.get_cmdline_user_args().has("--test-isolated"):
        quit(2)
        return
    call_deferred("_run")

func _save(file_name: String) -> void:
    for frame in range(3):
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://captures/" + file_name + ".png")

func _run() -> void:
    DirAccess.make_dir_recursive_absolute("user://captures")
    change_scene_to_file("res://scenes/Main.tscn")
    for frame in range(12):
        await physics_frame
    paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var game: Node = current_scene
    var effect: ColorRect = game.get_node("PostFX/ASCII") as ColorRect
    await _save("balanced_game")
    game.get_node("HUD").visible = false
    await _save("balanced_scene")
    effect.visible = false
    await _save("balanced_raw")
    effect.visible = true
    var material: ShaderMaterial = effect.material as ShaderMaterial
    var corrected: Shader = material.shader
    var legacy: Shader = Shader.new()
    legacy.code = FileAccess.get_file_as_string("res://tests/fixtures/ascii_post_v0_10.gdshader.txt")
    material.shader = legacy
    LEGACY_BINDING.apply(material, int(material.get_shader_parameter("cell_px")))
    await _save("legacy_shader_same_scene")
    material.shader = corrected
    game.get_node("HUD").visible = true
    var menu: Node = game.get_node("SettingsMenu")
    menu.call("set_open", true)
    await _save("balanced_settings")
    menu.call("_toggle_preview")
    await _save("balanced_preview")
    var retained_pause: bool = paused
    menu.call("set_open", false)
    root.get_node("AudioManager").call("stop_all")
    # Allow the asynchronous Dummy audio backend to release playback before exit.
    root.get_node("AudioManager/DistrictMusic").stream = null
    await create_timer(0.35, true, false, true).timeout
    game.queue_free()
    paused = false
    for frame in range(12):
        await physics_frame
    if not retained_pause:
        push_error("Visual preview resumed combat")
    print("VISUAL_CAPTURE_OK: native frames / paused preview: ", retained_pause)
    quit(0 if retained_pause else 1)
