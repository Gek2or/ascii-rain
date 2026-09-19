extends SceneTree

var _failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for index in range(20):
        await process_frame

    var game: Node = current_scene
    var player: CharacterBody3D = game.get_node("Player") as CharacterBody3D
    var bridge: Node = player.get_node("Entity01Bridge")
    var visual: RainEntityVisual = player.get_node("Entity01Bridge/Entity01Visual") as RainEntityVisual
    var legacy_body: Node3D = player.get_node("Visual/BodyRoot") as Node3D
    var overlay: CanvasLayer = player.get_node("RawHeroOverlay") as CanvasLayer
    var overlay_camera: Camera3D = overlay.get_node("HeroViewportContainer/HeroViewport/HeroCamera") as Camera3D
    var hero_meshes: Array[Node] = visual.find_children("*", "VisualInstance3D", true, false)
    var hero_mesh: VisualInstance3D = hero_meshes[0] as VisualInstance3D if not hero_meshes.is_empty() else null
    var main_viewport: Viewport = root as Viewport
    _expect(visual != null, "Entity01 visual is instanced under Player")
    _expect(not legacy_body.visible, "legacy player body is hidden")
    _expect(player.get_node("CollisionShape3D") != null, "player collision is preserved")
    _expect(overlay_camera.cull_mask == 2, "raw viewport renders only hero layer")
    _expect(bool(overlay.get_node("HeroViewportContainer/HeroViewport").get("transparent_bg")), "hero viewport has transparent background")
    _expect(hero_mesh != null and hero_mesh.layers == 2, "hero meshes use the raw render layer")
    _expect((main_viewport.get_camera_3d().cull_mask & 2) == 0, "world camera excludes hero raw layer")
    var code_materials: Array = visual.get("_shader_materials") as Array
    var subdued_code: bool = false
    for entry: Variant in code_materials:
        var material: ShaderMaterial = entry as ShaderMaterial
        if material != null and material.get_shader_parameter("emission_energy") != null:
            subdued_code = float(material.get_shader_parameter("emission_energy")) <= 0.45 and float(material.get_shader_parameter("color_bleed")) <= 0.10
            break
    _expect(subdued_code, "raw hero uses a restrained code accent over a solid silhouette")

    var required_clips: Array[StringName] = [
        &"Hover_Idle", &"Glide_Loop", &"Dash", &"Human_Echo",
        &"Cast_Pulse", &"Hit_Recoil", &"Dissolve", &"Reconstruct"
    ]
    var clip_names: Array[StringName] = visual.available_clips()
    for clip_name in required_clips:
        _expect(clip_names.has(clip_name), "clip available: " + String(clip_name))

    bridge.set_process(false)
    bridge.call("_on_jump_started")
    _expect(StringName(visual.get("_current")) == &"Glide_Loop", "jump selects the model flight animation")
    root.get_node("GameEvents").emit_signal("reality_fragment_found", &"memory_01")
    _expect(StringName(visual.get("_current")) == &"Human_Echo", "archive fragment triggers human echo")
    visual.clip_finished.emit(&"Human_Echo")
    await process_frame
    _expect(StringName(visual.get("_current")) == &"Reconstruct", "human echo transitions into reconstruct")
    visual.play_clip(&"Hover_Idle", 0.0)

    visual.set_moving(false)
    visual.set_moving(true)
    await process_frame
    _expect(StringName(visual.get("_current")) == &"Glide_Loop", "movement selects glide loop")
    _expect(visual.play_clip(&"Dash", 0.0), "dash clip plays")

    var zoom_controller: Node = player.get_node("CameraZoomController")
    var spring_arm: SpringArm3D = player.get_node("CameraPivot/SpringArm3D") as SpringArm3D
    var initial_zoom: float = spring_arm.spring_length
    var wheel_up: InputEventMouseButton = InputEventMouseButton.new()
    wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
    wheel_up.pressed = true
    zoom_controller.call("_unhandled_input", wheel_up)
    _expect(float(zoom_controller.get("_target_distance")) < initial_zoom, "mouse wheel up targets camera zoom-in")
    for frame in range(10):
        await process_frame
    _expect(spring_arm.spring_length < initial_zoom, "camera zoom eases inward")
    overlay.call("_process", 0.0)
    var camera_alignment_error: float = overlay_camera.global_position.distance_to(player.get_node("CameraPivot/SpringArm3D/Camera3D").global_position)
    _expect(camera_alignment_error < 0.01, "raw hero camera stays aligned during zoom: %.3f m" % camera_alignment_error)
    var zoom_constants: Dictionary = zoom_controller.get_script().get_script_constant_map()
    var min_zoom: float = float(zoom_constants["MIN_DISTANCE"])
    var max_zoom: float = float(zoom_constants["MAX_DISTANCE"])
    var wheel_down: InputEventMouseButton = InputEventMouseButton.new()
    wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
    wheel_down.pressed = true
    for step in range(24):
        zoom_controller.call("_unhandled_input", wheel_up)
    _expect(is_equal_approx(float(zoom_controller.get("_target_distance")), min_zoom), "zoom-in clamps to the minimum distance")
    for step in range(48):
        zoom_controller.call("_unhandled_input", wheel_down)
    _expect(is_equal_approx(float(zoom_controller.get("_target_distance")), max_zoom), "zoom-out clamps to the maximum distance")

    player.set_physics_process(false)
    player.velocity = Vector3.ZERO
    var camera: Camera3D = Camera3D.new()
    game.add_child(camera)
    var player_target: Vector3 = player.global_position + Vector3.UP * 1.28
    camera.global_position = player_target + Vector3(0.0, 0.0, 3.0)
    camera.look_at(player_target)
    camera.current = true
    for frame in range(3):
        await process_frame
    overlay.call("_update_occlusion_state")
    overlay.call("_update_occlusion_state")
    _expect(bool(overlay.get("_raw_pass_active")), "clear camera view enables raw hero pass")

    var wall: StaticBody3D = StaticBody3D.new()
    wall.collision_layer = 1
    var wall_shape: CollisionShape3D = CollisionShape3D.new()
    var wall_box: BoxShape3D = BoxShape3D.new()
    wall_box.size = Vector3(5.0, 5.0, 0.8)
    wall_shape.shape = wall_box
    wall.add_child(wall_shape)
    game.add_child(wall)
    wall.global_position = camera.global_position.lerp(player_target, 0.68)
    wall.look_at(player_target)
    for frame in range(3):
        await physics_frame
    overlay.call("_update_occlusion_state")
    overlay.call("_update_occlusion_state")
    _expect(not bool(overlay.get("_raw_pass_active")), "occluded hero returns to depth-tested ASCII pass")
    _expect(hero_mesh.layers == 1, "occluded hero is restored to the world render layer")
    wall.queue_free()
    for frame in range(3):
        await physics_frame
    overlay.call("_update_occlusion_state")
    overlay.call("_update_occlusion_state")
    _expect(bool(overlay.get("_raw_pass_active")), "hero returns to raw pass after obstruction clears")

    root.get_node("AudioManager").call("stop_all")
    for cleanup_frame in range(12):
        await physics_frame
    if _failures == 0:
        print("ENTITY01_SMOKE_OK: model, clips, player collision and locomotion bridge")
        quit()
    else:
        print("ENTITY01_SMOKE_FAILED: %d failures" % _failures)
        quit(1)

func _expect(condition: bool, description: String) -> void:
    if condition:
        return
    _failures += 1
    push_error("Entity01 smoke: " + description)
