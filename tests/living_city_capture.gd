extends SceneTree
# Reproducible staged cameras in the actual Main scene, not concept art.
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for i in range(6):
        await physics_frame
    var game: Node3D=current_scene as Node3D
    game.get_node("EncounterDirector").set_process(false)
    var player: CharacterBody3D=game.get_node("Player") as CharacterBody3D
    player.set_physics_process(false)
    var camera: Camera3D=Camera3D.new()
    camera.fov=72.0
    camera.far=230.0
    game.add_child(camera)
    camera.current=true
    var post: ColorRect=game.get_node("PostFX/ASCII") as ColorRect
    var folder: String="user://captures"
    DirAccess.make_dir_recursive_absolute(folder)
    game.get_node("HUD/Upgrade").visible=false
    var shots: Array = [
        ["market_entry",Vector3(43,3.8,17),Vector3(44,3.0,39),Vector3(44,0.02,25),PI],
        ["market_under",Vector3(45,2.5,39),Vector3(45,2.0,26),Vector3(45,0.02,35),0.0],
        ["market_overview",Vector3(19,15,69),Vector3(46,3.8,42),Vector3(40,5.52,56),PI],
        ["transit_entry",Vector3(0,7.0,34),Vector3(0,4.7,65),Vector3(0,0.02,44),PI],
        ["transit_upper",Vector3(3,8.4,56),Vector3(0,6.0,71),Vector3(0,5.52,64),PI]]
    for shot in shots:
        player.global_position=shot[3]
        player.rotation.y=shot[4]
        camera.global_position=shot[1]
        camera.look_at(shot[2])
        for i in range(5):
            await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+shot[0]+".png")
        if shot[0]=="market_overview" or shot[0]=="transit_entry":
            post.visible=false
            await RenderingServer.frame_post_draw
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(folder+"/"+shot[0]+"_raw.png")
            post.visible=true
    # Mobile profile rendering is not a physical-device performance benchmark.
    var settings: Node=root.get_node("SettingsManager")
    settings.call("apply_preset",1)
    camera.global_position=Vector3(0,7.0,34)
    camera.look_at(Vector3(0,4.7,65))
    player.global_position=Vector3(0,0.02,44)
    for i in range(5):
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(folder+"/transit_8px_medium.png")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    await create_timer(0.35,true,false,true).timeout
    game.queue_free()
    for i in range(10):
        await physics_frame
    print("LIVING_CAPTURE_OK: staged real Main cameras, 6px + 8px, raw comparisons")
    quit()
