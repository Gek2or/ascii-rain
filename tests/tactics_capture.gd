extends SceneTree
# Staged real-engine illustration of locked warning cues in the existing city.
# Not a human playthrough or performance benchmark.
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for frame in range(4):
        await physics_frame
    var game: Node = current_scene
    game.get_node("EncounterDirector").set_process(false)
    var player: CharacterBody3D = game.get_node("Player") as CharacterBody3D
    player.set("_invulnerability_timer", 500.0)
    for frame in range(165):
        await physics_frame
    var placements: Array[Vector3] = [Vector3(5, 0.1, -8), Vector3(-3.0, 0.1, 1.0), Vector3(-7, 0.1, -12)]
    var kinds: Array[int] = [2, 0, 4]
    for i in range(3):
        var actor: CharacterBody3D = load("res://scenes/Enemy.tscn").instantiate() as CharacterBody3D
        game.add_child(actor)
        actor.global_position = placements[i]
        actor.call("setup", kinds[i], 0, 1.0)
        actor.set_physics_process(false)
        var heading: Vector3 = (player.global_position - actor.global_position).normalized()
        actor.look_at(Vector3(player.global_position.x, actor.global_position.y, player.global_position.z))
        if i == 1:
            actor.call("_begin_melee_windup", heading)
        else:
            actor.call("_begin_ranged_windup", heading)
    paused = true
    # Render/UI continue; combat and the warning countdown remain frozen.
    for frame in range(3):
        await process_frame
    await RenderingServer.frame_post_draw
    var folder: String = "user://captures"
    DirAccess.make_dir_recursive_absolute(folder)
    root.get_texture().get_image().save_png(folder + "/encounter_tactics.png")
    paused = false
    game.call("_stop_hostile_activity", true)
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream = null
    await create_timer(0.35, true, false, true).timeout
    game.queue_free()
    for frame in range(12):
        await physics_frame
    print("TACTICS_CAPTURE_OK")
    quit()
