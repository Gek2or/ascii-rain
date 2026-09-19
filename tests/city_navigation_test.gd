extends SceneTree
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")
func _expect(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        print("CITY_NAV_FAIL: ", label)
func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for frame in range(4):
        await physics_frame
    var game: Node3D = current_scene as Node3D
    var nav: StreetNavigation = game.get_node("StreetNavigation") as StreetNavigation
    var director: Node = game.get_node("EncounterDirector")
    director.set_process(false)
    var player: CharacterBody3D = game.get_node("Player") as CharacterBody3D
    player.set("_invulnerability_timer", 500.0)
    var bake_ticks: int = 0
    for frame in range(300):
        if nav.built:
            break
        bake_ticks += 1
        await physics_frame
    _expect(nav.built, "actual procedural city graph completes")
    _expect(nav.graph.get_point_count() > 500, "city contains connected street samples")
    # Rebuilt districts own their colliders directly, not via the legacy pass.
    # Count usable physical bodies across BOTH paths; retaining only the old
    # counter would falsely report lost collision when a district is replaced.
    var physical_count: int = 0
    for item in game.get_node("City").find_children("*","StaticBody3D",true,false):
        var body: StaticBody3D = item as StaticBody3D
        if (body.collision_layer & 1) == 0:
            continue
        for child in body.get_children():
            var shape: CollisionShape3D = child as CollisionShape3D
            if shape != null and shape.shape != null and not shape.disabled:
                physical_count += 1
                break
    var legacy_count: int = int(game.get_node("CityCollisions").get("collider_count"))
    print("CITY_COLLISION_BODIES: ",physical_count," (legacy attachments: ",legacy_count,")")
    _expect(physical_count >= 70 and legacy_count > 0, "legacy and authored buildings/cars/consoles have usable physical colliders")
    var sight = load("res://components/combat/combat_sight.gd")
    _expect(not sight.clear(game.get_world_3d(), Vector3(0, 1, -63), Vector3(0, 1, -70)), "monument facade stops line of fire")
    print("CITY_NAV_GRAPH: nodes=", nav.graph.get_point_count(), " remaining_bake_ticks=", bake_ticks)
    for district in director.call("get_district_catalog"):
        var center: Vector3 = district["center"]
        await physics_frame
        var response: Dictionary = nav.request_route(player.global_position, center)
        _expect(response["status"] == "ok", "route from arrival to " + str(district["id"]))
    # Sample regular spawns in actual district geometry, not only a synthetic box.
    game.set("elapsed", 70.0)
    player.global_position = Vector3(50, 0.1, -20)
    for frame in range(4):
        await physics_frame
    for attempt in range(10):
        game.call("_spawn_enemy_near", player.global_position, 1.0)
        await physics_frame
    _expect(get_nodes_in_group("enemies").size() >= 2, "district spawns survive connected-floor filter")
    var all_clear: bool = true
    for actor in get_nodes_in_group("enemies"):
        var body: Node3D = actor as Node3D
        var capsule: CapsuleShape3D = CapsuleShape3D.new()
        capsule.radius = 0.55 * body.scale.x
        capsule.height = 2.2 * body.scale.y
        var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
        query.shape = capsule
        query.collision_mask = 1
        query.transform = Transform3D(Basis.IDENTITY, body.global_position + Vector3.UP * (capsule.height * 0.5 + 0.10))
        all_clear = all_clear and game.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
    _expect(all_clear, "actual scaled colliders spawn outside walls")
    var elite: CharacterBody3D = load("res://scenes/Enemy.tscn").instantiate() as CharacterBody3D
    game.add_child(elite)
    elite.global_position = Vector3(0, 0.1, 12)
    elite.call("setup", 0, 2, 1.0)
    elite.call("take_damage", 99999.0)
    _expect(not get_nodes_in_group("hostile_hazards").is_empty(), "game receives delayed volatile hazard")
    game.call("_stop_hostile_activity", true)
    for frame in range(6):
        await physics_frame
    _expect(get_nodes_in_group("hostile_hazards").is_empty(), "sector end cancels hazards")
    _expect(get_nodes_in_group("hostile_cues").is_empty(), "sector end removes stale warnings")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream = null
    await create_timer(0.35, true, false, true).timeout
    game.queue_free()
    for frame in range(12):
        await physics_frame
    print("CITY_NAV_NATIVE: ", checks, " checks / ", failures.size(), " failures")
    quit(0 if failures.is_empty() else 1)
