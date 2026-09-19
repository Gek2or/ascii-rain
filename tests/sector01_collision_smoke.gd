extends SceneTree

const FLOOR_PROBES: Array[Vector3] = [
    Vector3(43.0, 0.0, 23.0), Vector3(45.5, 0.0, 30.0),
    Vector3(35.0, 0.0, 40.0), Vector3(46.0, 0.0, 42.0),
    Vector3(70.0, 0.0, 50.0), Vector3(40.0, 5.58, 58.6),
    Vector3(71.7, 0.0, 51.0), Vector3(72.0, 0.0, 59.0),
    Vector3(57.5, 0.0, 62.0), Vector3(76.0, 0.0, 68.0)
]

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for frame in range(12):
        await physics_frame
    var game: Node3D = current_scene
    var living: Node = get_first_node_in_group("living_city")
    var sector: Node3D = living.get_node_or_null("ThresholdMarketSector") as Node3D
    _expect(sector != null, "sector instance exists")
    if sector != null:
        _expect(get_nodes_in_group("sector01_markers").size() == 10, "ten route markers exist")
        for body_name in ["EntryLiftWest", "TutorialWestWall", "CourtyardEastPier", "ArchiveDescent", "PrepRoomNorthWall", "ArenaDistortionPylon", "ExitLiftEast"]:
            var body: StaticBody3D = sector.get_node_or_null(body_name) as StaticBody3D
            _expect(body != null and body.get_shape_owners().size() > 0, "collision body " + body_name)
    var world: World3D = game.get_world_3d()
    var physics: PhysicsDirectSpaceState3D = world.direct_space_state
    for probe in FLOOR_PROBES:
        var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(probe + Vector3.UP * 4.0, probe - Vector3.UP * 2.0, 1)
        var hit: Dictionary = physics.intersect_ray(query)
        _expect(not hit.is_empty(), "supported floor " + str(probe))
    root.get_node("AudioManager").call("stop_all")
    game.queue_free()
    for frame in range(8):
        await physics_frame
    print("SECTOR01_COLLISION_SMOKE: ", checks, " checks / ", failures, " failures")
    quit(0 if failures == 0 else 1)

func _expect(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("SECTOR01_COLLISION: " + message)
