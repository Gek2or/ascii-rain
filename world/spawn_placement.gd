extends RefCounted

# Bounded queries; called from the game's physics tick, not the draw/update tick.
# This prevents materialising in solid walls/on rooftops. It is NOT pathfinding.
static func find_street(world: World3D, center: Vector3, player_position: Vector3, rng: RandomNumberGenerator, event: bool) -> Dictionary:
    if world == null:
        return {}
    var space: PhysicsDirectSpaceState3D = world.direct_space_state
    var capsule: CapsuleShape3D = CapsuleShape3D.new()
    capsule.radius = 0.68
    capsule.height = 2.35
    var check: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    check.shape = capsule
    check.collision_mask = 1
    check.collide_with_areas = false
    var near_radius: float = 22.0 if event else 27.0
    var far_radius: float = 31.0 if event else 39.0
    for attempt in range(10):
        var angle: float = rng.randf_range(0.0, TAU)
        var radius: float = rng.randf_range(near_radius, far_radius)
        var candidate: Vector3 = center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
        # Do not clamp a spawn on top of the player at the map's border.
        if absf(candidate.x) > 78.0 or absf(candidate.z) > 78.0:
            continue
        var flat: Vector3 = candidate - player_position
        flat.y = 0.0
        if flat.length() < 18.0:
            continue
        var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
            Vector3(candidate.x, 90.0, candidate.z), Vector3(candidate.x, -3.0, candidate.z), 1)
        var floor_hit: Dictionary = space.intersect_ray(ray)
        if floor_hit.is_empty():
            continue
        var point: Vector3 = floor_hit["position"]
        var normal: Vector3 = floor_hit["normal"]
        if point.y > 3.6 or point.y < -0.8 or normal.y < 0.82:
            continue
        var origin: Vector3 = point + Vector3.UP * 0.15
        check.transform = Transform3D(Basis.IDENTITY, origin + Vector3.UP * 1.20)
        if not space.intersect_shape(check, 1).is_empty():
            continue
        return {"position": origin}
    return {}

static func find_authored(nav: StreetNavigation, points: Array[Vector3], target: Vector3, rng: RandomNumberGenerator, minimum_distance: float = 12.0) -> Dictionary:
    if nav == null or not nav.built or points.is_empty():
        return {}
    var first: int = rng.randi_range(0,points.size()-1)
    for offset in range(mini(8,points.size())):
        var candidate: Vector3 = points[(first+offset)%points.size()]
        var result: Dictionary = nav.spawn_anchor(candidate,target,minimum_distance)
        if result.is_empty():
            continue
        var at: Vector3 = result["position"]
        var occupied: bool = false
        for actor in nav.get_tree().get_nodes_in_group("enemies"):
            if (actor as Node3D).global_position.distance_squared_to(at) < 3.5*3.5:
                occupied = true
                break
        if not occupied:
            return result
    return {}
