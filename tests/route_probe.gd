extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for i in range(6): await physics_frame
    var g: Node3D=current_scene
    g.get_node("EncounterDirector").set_process(false)
    g.get_node("Player").set_physics_process(false)
    var nav: StreetNavigation=g.get_node("StreetNavigation")
    for i in range(700):
        if nav.built: break
        await physics_frame
    for x in [-66.0,-42.0,29.0]:
        for z in range(-60,16,2):
            var p: Vector3=Vector3(x,11,z)
            var floor_hit: Dictionary=nav.support_below(p)
            if floor_hit.is_empty(): continue
            var foot: Vector3=floor_hit["point"]
            var q: PhysicsShapeQueryParameters3D=nav.call("_shape_query",foot)
            var blocks: Array[Dictionary]=g.get_world_3d().direct_space_state.intersect_shape(q,8)
            var names: Array[String]=[]
            for b in blocks: names.append(str(b["collider"].get_path()))
            var id: int=nav.nearest_id(foot+Vector3.UP*0.08)
            print("PROBE: ",foot," id=",id," component=",nav.get("_components").get(id,-1)," collision=",names)
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    g.queue_free()
    for i in range(8): await physics_frame
    print("ROUTE_PROBE_OK")
    quit()
