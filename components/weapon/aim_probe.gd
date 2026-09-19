extends RefCounted

# Called on a physics tick. Includes the shoulder-to-muzzle segment: a camera ray
# alone can see a target while the gun clips through the corner beside the player.
static func sample(actor: CharacterBody3D, muzzle: Marker3D, aim_point: Vector3) -> Dictionary:
    var origin: Vector3 = muzzle.global_position
    var shoulder: Vector3 = actor.global_position + Vector3.UP * 1.42
    var space: PhysicsDirectSpaceState3D = actor.get_world_3d().direct_space_state
    var barrel_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(shoulder, origin, 1)
    barrel_query.exclude = [actor.get_rid()]
    barrel_query.hit_from_inside = true
    var barrel_hit: Dictionary = space.intersect_ray(barrel_query)
    if not barrel_hit.is_empty():
        return {"blocked": true, "barrel_blocked": true, "point": barrel_hit["position"], "origin": shoulder, "target": aim_point}
    if origin.distance_squared_to(aim_point) < 0.001:
        return {"blocked": false, "barrel_blocked": false, "point": aim_point, "origin": origin, "target": aim_point}
    var line_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, aim_point, 0b101)
    line_query.exclude = [actor.get_rid()]
    line_query.hit_from_inside = true
    var line_hit: Dictionary = space.intersect_ray(line_query)
    if not line_hit.is_empty():
        var hit_position: Vector3 = line_hit["position"]
        var collider: Object = line_hit["collider"]
        var is_wall: bool = collider == null or not collider.has_method("take_damage")
        var obstructed: bool = is_wall and hit_position.distance_to(aim_point) > 0.35
        return {"blocked": obstructed, "barrel_blocked": false, "point": hit_position, "origin": origin, "target": aim_point}
    return {"blocked": false, "barrel_blocked": false, "point": aim_point, "origin": origin, "target": aim_point}
