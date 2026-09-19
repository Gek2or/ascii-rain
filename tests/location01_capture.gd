extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://scenes/Location01_ThresholdMarket.tscn")
    for frame in range(34):
        await process_frame
    var game: Node3D = current_scene as Node3D
    game.get_node("EncounterDirector").set_process(false)
    game.get_node("HUD").visible = false
    var metrics: CanvasLayer = game.get_node_or_null("PerformanceOverlay") as CanvasLayer
    if metrics != null:
        metrics.visible = false
    var player: CharacterBody3D = game.get_node("Player") as CharacterBody3D
    player.set_physics_process(false)
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute("user://captures")
    root.get_texture().get_image().save_png("user://captures/location01_threshold_market_ascii.png")
    player.get_node("RawHeroOverlay").visible = false
    var overview: Camera3D = Camera3D.new()
    overview.fov = 64.0
    overview.far = 180.0
    game.add_child(overview)
    overview.current = true
    overview.global_position = Vector3(83.0, 24.0, 85.0)
    overview.look_at(Vector3(52.0, 1.0, 47.0))
    for frame in range(12):
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://captures/location01_threshold_market_overview.png")
    game.queue_free()
    for frame in range(8):
        await process_frame
    print("LOCATION01_CAPTURE_OK")
    quit()
