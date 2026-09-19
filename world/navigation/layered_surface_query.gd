extends RefCounted

# Multiple physical surfaces per XZ. Explicit authored tops may exceed the old
# street-height limit; unmarked high roofs remain scenery, not automatic routes.
static func floors(world: World3D, at: Vector3, top: float = 90.0, bottom: float = -14.0) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var excluded: Array[RID] = []
    var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(at.x,top,at.z), Vector3(at.x,bottom,at.z),1)
    for layer in range(16):
        ray.exclude = excluded
        var hit: Dictionary = world.direct_space_state.intersect_ray(ray)
        if hit.is_empty():
            break
        excluded.append(hit["rid"])
        var point: Vector3 = hit["position"]
        var normal: Vector3 = hit["normal"]
        var body: Node = hit["collider"] as Node
        if body == null or normal.y < 0.84 or bool(body.get_meta("nav_decoration",false)):
            continue
        var surface: StringName = StringName(body.get_meta("nav_surface_id", &"street"))
        if surface == &"street" and (point.y < -0.8 or point.y > 3.6):
            continue
        result.append({"point":point, "surface":surface, "body":body})
    return result

static func near(world: World3D, at: Vector3) -> Dictionary:
    # Start at the expected support height, never above an unrelated ceiling.
    var result: Array[Dictionary] = floors(world,at,at.y+0.42,at.y-0.55)
    for entry in result:
        var point: Vector3 = entry["point"]
        if absf(point.y-at.y) <= 0.50:
            return entry
    return {}

static func below(world: World3D, at: Vector3) -> Dictionary:
    var result: Array[Dictionary] = floors(world,at,at.y+0.18,-14.0)
    return result[0] if not result.is_empty() else {}
