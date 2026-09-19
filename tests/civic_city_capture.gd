extends SceneTree
# Staged real engine cameras. These are not conceptual/generated pictures.
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for i in range(6): await physics_frame
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
    var shots: Array=[
        ["archive_entry",Vector3(51,7.0,15),Vector3(51,6,-24),Vector3(51,0.06,4),0.0],
        ["archive_overview",Vector3(20,22,11),Vector3(51,6,-23),Vector3(40,5.52,-16),0.0],
        ["archive_under",Vector3(51,2.8,-6),Vector3(51,3,-30),Vector3(51,0.06,-10),0.0],
        ["archive_gallery",Vector3(40,8.6,-10),Vector3(54,8.4,-31),Vector3(40,5.52,-15),0.0],
        ["gardens_entry",Vector3(-37,8.8,14),Vector3(-51,3.8,47),Vector3(-43,0.06,24),PI],
        ["gardens_overview",Vector3(-79,22,17),Vector3(-48,4.2,48),Vector3(-64,2.78,42),PI],
        ["gardens_pavilion",Vector3(-57,11,39),Vector3(-35,8.3,60),Vector3(-39,5.53,55),PI],
        ["gardens_underpass",Vector3(-35,2.6,45),Vector3(-35,2.3,63),Vector3(-35,0.06,54),PI]]
    for shot in shots:
        player.global_position=shot[3]
        player.rotation.y=shot[4]
        camera.global_position=shot[1]
        camera.look_at(shot[2])
        for i in range(6): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder+"/"+shot[0]+".png")
        if shot[0]=="archive_overview" or shot[0]=="gardens_overview":
            post.visible=false
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(folder+"/"+shot[0]+"_raw.png")
            post.visible=true
    root.get_node("SettingsManager").call("apply_preset",1)
    camera.global_position=Vector3(-37,8.8,14)
    camera.look_at(Vector3(-51,3.8,47))
    player.global_position=Vector3(-43,0.06,24)
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(folder+"/gardens_medium_8px.png")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    game.queue_free()
    for i in range(12): await physics_frame
    print("CIVIC_CAPTURE_OK: real Main, staged cameras, unchanged 6px + 8px shader profiles")
    quit()
