extends SceneTree

# Visual evidence only. Uses the real portal activation path and does not claim a playtest.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for frame in range(20):
        await process_frame
    var game: Node3D = current_scene as Node3D
    game.get_node("EncounterDirector").set_process(false)
    game.get_node("HUD").visible = false
    var player: CharacterBody3D = game.get_node("Player") as CharacterBody3D
    var portal: Node3D = game.get("teleporter") as Node3D
    player.set_physics_process(false)
    # This evidence camera is separate from the player camera. Hide only the
    # raw-hero composition viewport so it cannot cover the portal frame.
    player.get_node("RawHeroOverlay").visible = false
    player.global_position = portal.global_position + Vector3(4.0, 0.0, 0.0)
    portal.set("route_locked", false)
    portal.call("interact", player)
    var camera: Camera3D = Camera3D.new()
    camera.fov = 58.0
    camera.far = 220.0
    game.add_child(camera)
    camera.current = true
    camera.global_position = portal.global_position + Vector3(31.0, 16.0, 31.0)
    camera.look_at(portal.global_position + Vector3.UP * 17.0)
    for frame in range(14):
        await process_frame
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute("user://captures")
    root.get_texture().get_image().save_png("user://captures/portal_event_ascii.png")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream = null
    game.queue_free()
    for frame in range(12):
        await process_frame
    print("PORTAL_EVENT_CAPTURE_OK")
    quit()
