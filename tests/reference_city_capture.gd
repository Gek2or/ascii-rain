extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for i in range(8): await physics_frame
    var game: Node3D=current_scene
    game.get_node("EncounterDirector").set_process(false)
    var player: CharacterBody3D=game.get_node("Player")
    player.set_physics_process(false)
    var camera: Camera3D=Camera3D.new()
    camera.fov=68
    camera.far=230
    game.add_child(camera)
    camera.current=true
    var post: ColorRect=game.get_node("PostFX/ASCII")
    DirAccess.make_dir_recursive_absolute("user://captures")
    # These are deliberately staged engine views, not a human playthrough.
    var shots: Array=[
        ["reference_market",Vector3(45,3.3,43),Vector3(44,5.4,24),Vector3(44,0.05,37),0.0],
        ["utility_entry",Vector3(-66,3.2,17),Vector3(-66,-2.1,-12),Vector3(-66,-0.4,9),0.0],
        ["utility_hall",Vector3(-66,-2.7,-15),Vector3(-53,-3.9,-34),Vector3(-63,-5.95,-20),-0.45],
        ["relay_roof",Vector3(-29,13.0,-59),Vector3(-22,11.5,-77),Vector3(-28,10.05,-65),0.0],
        ["relay_overview",Vector3(-47,24,-35),Vector3(0,7,-67),Vector3(-29,10.05,-62),0.0],
        ["arrival_gameplay",Vector3(1.15,3.1,18),Vector3(0,2.5,-5),Vector3(0,0.05,12),0.0]]
    for shot in shots:
        player.global_position=shot[3]
        player.rotation.y=shot[4]
        camera.global_position=shot[1]
        camera.look_at(shot[2])
        game.get_node("HUD/Upgrade").visible=false
        for i in range(10): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("user://captures/"+shot[0]+".png")
        if shot[0]=="reference_market":
            var new_shader: Shader=(post.material as ShaderMaterial).shader
            var old: Shader=Shader.new()
            old.code=FileAccess.get_file_as_string("res://tests/fixtures/ascii_post_v012b.gdshader.txt")
            (post.material as ShaderMaterial).shader=old
            # Comparison of algorithms at the same view and 6px; old high bed .64
            # is the user's reported profile, not an assertion of engine defaults.
            (post.material as ShaderMaterial).set_shader_parameter("surface_fill",0.64)
            for i in range(4): await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("user://captures/reference_market_oldbed.png")
            (post.material as ShaderMaterial).shader=new_shader
            root.get_node("SettingsManager").call("apply_visual_style",0)
        if shot[0] in ["utility_hall","relay_overview"]:
            post.visible=false
            for i in range(4): await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("user://captures/"+shot[0]+"_raw.png")
            post.visible=true
    # Renderer style is independent of district geometry.
    root.get_node("SettingsManager").call("apply_visual_style",1)
    camera.global_position=Vector3(-66,-2.7,-15)
    camera.look_at(Vector3(-53,-3.9,-34))
    player.global_position=Vector3(-63,-5.95,-20)
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://captures/utility_readable_style.png")
    root.get_node("SettingsManager").call("apply_visual_style",2)
    for i in range(8): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("user://captures/utility_mobile_style.png")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    game.queue_free()
    for i in range(12): await physics_frame
    print("REFERENCE_CITY_CAPTURE_OK: real Godot scenes, staged cameras, no synthetic art")
    quit()
