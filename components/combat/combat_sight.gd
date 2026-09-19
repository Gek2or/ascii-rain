extends RefCounted

# World mask only. Other actors do not make a warning flicker on/off, while all
# solid walls, vehicles and decks still block hits. Call on a physics tick.
static func clear(world: World3D, start: Vector3, finish: Vector3) -> bool:
    if world == null:
        return false
    if start.distance_squared_to(finish) < 0.0001:
        return true
    var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, finish, 1)
    ray.hit_from_inside = true
    return world.direct_space_state.intersect_ray(ray).is_empty()

static func melee(world: World3D, feet: Vector3, victim: Vector3, facing: Vector3,
        reach: float = 2.25, half_angle: float = 55.0) -> bool:
    var offset: Vector3 = victim - feet
    if offset.length() > reach or absf(offset.y) > 1.45:
        return false
    offset.y = 0.0
    var forward: Vector3 = Vector3(facing.x, 0.0, facing.z).normalized()
    if offset.length_squared() > 0.01 and forward.dot(offset.normalized()) < cos(deg_to_rad(half_angle)):
        return false
    return clear(world, feet + Vector3.UP, victim + Vector3.UP)
