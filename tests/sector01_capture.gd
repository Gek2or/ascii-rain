extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for index in range(10):
        await physics_frame
    var game: Node3D = current_scene
    game.get_node("EncounterDirector").set_process(false)
    game.get_node("HUD").visible = false
    var player: CharacterBody3D = game.get_node("Player") as CharacterBody3D
    player.set_physics_process(false)
    var camera: Camera3D = Camera3D.new()
    camera.fov = 68.0
    camera.far = 150.0
    game.add_child(camera)
    camera.current = true
    var ascii: ColorRect = game.get_node("PostFX/ASCII") as ColorRect
    DirAccess.make_dir_recursive_absolute("user://captures")
    var shots: Array[Dictionary] = [
        {"name": "sector01_entry", "camera": Vector3(44.0, 2.8, 17.0), "target": Vector3(44.0, 1.6, 27.0), "player": Vector3(44.0, 0.1, 23.0)},
        {"name": "sector01_courtyard", "camera": Vector3(32.0, 3.0, 49.0), "target": Vector3(36.0, 1.2, 38.0), "player": Vector3(35.0, 0.1, 40.0)},
        {"name": "sector01_bypass", "camera": Vector3(52.0, 8.2, 53.0), "target": Vector3(60.0, 3.0, 45.0), "player": Vector3(59.0, 5.6, 45.0)},
        {"name": "sector01_arena", "camera": Vector3(57.5, 3.0, 74.0), "target": Vector3(57.5, 1.0, 61.0), "player": Vector3(57.5, 0.1, 62.0)}
    ]
    for entry in shots:
        var name_text: String = String(entry["name"])
        player.global_position = entry["player"]
        camera.global_position = entry["camera"]
        camera.look_at(entry["target"])
        for index in range(8):
            await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("user://captures/" + name_text + ".png")
        if name_text == "sector01_courtyard":
            ascii.visible = false
            for raw_frame in range(4):
                await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("user://captures/sector01_courtyard_raw.png")
            ascii.visible = true
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream = null
    game.queue_free()
    for index in range(12):
        await physics_frame
    print("SECTOR01_CAPTURE_OK: entry, courtyard, bypass and arena")
    quit()
