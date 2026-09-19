extends SceneTree
# Optional real-engine screenshots, requires a rendering display, not --headless.
# Test data and GUI captures, not a player performance benchmark.
func _initialize() -> void:
    if not OS.get_cmdline_user_args().has("--test-isolated"):
        quit(2)
        return
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for frame in range(8):
        await process_frame
    var game: Node = current_scene
    var player: CharacterBody3D = game.get_node("Player") as CharacterBody3D
    player.set("_invulnerability_timer", 120.0)
    var out_dir: String = "user://captures"
    DirAccess.make_dir_recursive_absolute(out_dir)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out_dir + "/city.png")
    var starter: Node3D = game.get("_starter_cache") as Node3D
    player.global_position = starter.global_position + Vector3(0, 0, 1.4)
    starter.call("interact", player)
    for frame in range(5):
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out_dir + "/relic_choice.png")
    var choice: Node = game.get_node("RelicChoice")
    var cards: Array = choice.get("_buttons")
    var in_bounds: bool = true
    for card in cards:
        in_bounds = in_bounds and root.get_visible_rect().encloses(card.get_global_rect())
    if not in_bounds:
        push_error("CHOICE_CAPTURE: card overflows viewport")
    print("RENDER_CAPTURE_OK: ", ProjectSettings.globalize_path(out_dir), " / cards inside viewport: ", in_bounds)
    choice.call("_close")
    root.get_node("AudioManager").call("stop_all")
    # Allow the asynchronous Dummy audio backend to release playback before exit.
    root.get_node("AudioManager/DistrictMusic").stream = null
    await create_timer(0.35, true, false, true).timeout
    game.queue_free()
    for frame in range(12):
        await physics_frame
    quit(0 if in_bounds else 1)
