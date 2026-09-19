extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for index in range(20):
        await process_frame
    var game: Node3D = current_scene as Node3D
    game.get_node("EncounterDirector").set_process(false)
    game.get_node("HUD").visible = false
    var player: CharacterBody3D = game.get_node("Player") as CharacterBody3D
    player.set_physics_process(false)
    player.global_position = Vector3(44.0, 0.1, 23.0)
    var camera: Camera3D = Camera3D.new()
    camera.fov = 54.0
    camera.far = 45.0
    game.add_child(camera)
    camera.current = true
    camera.global_position = Vector3(44.0, 2.3, 18.8)
    camera.look_at(Vector3(44.0, 1.2, 23.0))
    var ascii: ColorRect = game.get_node("PostFX/ASCII") as ColorRect
    DirAccess.make_dir_recursive_absolute("user://captures")
    for index in range(10):
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://captures/entity01_ascii.png")
    ascii.visible = false
    for index in range(4):
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://captures/entity01_raw.png")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream = null
    game.queue_free()
    for index in range(12):
        await process_frame
    print("ENTITY01_CAPTURE_OK: ascii and raw")
    quit()
