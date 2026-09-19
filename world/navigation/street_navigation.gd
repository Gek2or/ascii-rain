class_name StreetNavigation
extends Node3D

# Shared layered graph. Each XZ cell can contain several supported floors.
# Authored galleries/ramps supply surface IDs; unmarked high roofs are excluded.
# Queries run ONLY on physics ticks. Baking is budgeted; actors never bake maps.
const SURFACES = preload("res://world/navigation/layered_surface_query.gd")
var point_surfaces: Dictionary = {}

@export var half_extent: float = 80.0
@export var cell_size: float = 2.5
@export var cells_per_tick: int = 160
@export var edges_per_tick: int = 192
var built: bool = false
var graph: AStar3D = AStar3D.new()
var path_queries: int = 0
var _cell_ids: Dictionary = {}
var _components: Dictionary = {}
var _cells: Array[Vector2i] = []
var _cursor: int = 0
var _edge_cursor: int = 0
var _phase: int = 0
var _settle: int = 2
var _queries_this_frame: int = 0
var _query_frame: int = -1
var _capsule: CapsuleShape3D = CapsuleShape3D.new()
const CENTER_HEIGHT: float = 2.50
const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]

func _ready() -> void:
    add_to_group("street_navigation")
    # Includes the collider of the largest ordinary elite Tank. Boss has its
    # own arena movement and is deliberately NOT assigned this graph.
    _capsule.radius = 1.10
    _capsule.height = 4.40
    var count: int = int(floor(half_extent / cell_size))
    for z in range(-count, count + 1):
        for x in range(-count, count + 1):
            _cells.append(Vector2i(x, z))

func _physics_process(_delta: float) -> void:
    if built:
        set_physics_process(false)
        return
    if _settle > 0:
        _settle -= 1
        return
    if _phase == 0:
        for work in range(cells_per_tick):
            if _cursor >= _cells.size():
                _phase = 1
                break
            _sample_cell(_cells[_cursor])
            _cursor += 1
    else:
        for work in range(edges_per_tick):
            if _edge_cursor >= _cells.size() * NEIGHBORS.size():
                _label_components()
                built = true
                break
            var cell: Vector2i = _cells[int(_edge_cursor / NEIGHBORS.size())]
            var offset: Vector2i = NEIGHBORS[_edge_cursor % NEIGHBORS.size()]
            _connect(cell, offset)
            _edge_cursor += 1

func _ground(at: Vector3) -> Dictionary:
    return SURFACES.near(get_world_3d(), at)

func support_below(at: Vector3) -> Dictionary:
    return SURFACES.below(get_world_3d(), at)

func _shape_query(feet: Vector3) -> PhysicsShapeQueryParameters3D:
    var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    query.shape = _capsule
    query.collision_mask = 1
    query.collide_with_areas = false
    query.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * CENTER_HEIGHT)
    return query

func _sample_cell(cell: Vector2i) -> void:
    var floors: Array[Dictionary] = SURFACES.floors(get_world_3d(), Vector3(cell.x*cell_size,0,cell.y*cell_size))
    var ids: Array[int] = []
    for floor_hit in floors:
        var point: Vector3 = floor_hit["point"]
        if not get_world_3d().direct_space_state.intersect_shape(_shape_query(point),1).is_empty():
            continue
        var duplicate: bool = false
        for id_value in ids:
            if absf(graph.get_point_position(id_value).y-point.y) < 0.10:
                duplicate = true
        if duplicate:
            continue
        var point_id: int = graph.get_available_point_id()
        graph.add_point(point_id,point)
        point_surfaces[point_id] = floor_hit["surface"]
        ids.append(point_id)
    if not ids.is_empty():
        _cell_ids[cell] = ids

func _connect(cell: Vector2i, offset: Vector2i) -> void:
    if not _cell_ids.has(cell) or not _cell_ids.has(cell+offset):
        return
    # Surface IDs never create magic links. Every edge needs slope, capsule
    # clearance and support, including diagonal edges and ramp/deck seams.
    for a in _cell_ids[cell]:
        for b in _cell_ids[cell+offset]:
            if can_travel(graph.get_point_position(a),graph.get_point_position(b)):
                graph.connect_points(a,b)

func can_travel(start: Vector3, finish: Vector3) -> bool:
    var flat: float = Vector2(finish.x - start.x, finish.z - start.z).length()
    if absf(finish.y - start.y) > maxf(0.35, flat * 0.47):
        return false
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var query: PhysicsShapeQueryParameters3D = _shape_query(start)
    if not space.intersect_shape(query, 1).is_empty():
        return false
    query.motion = finish - start
    var sweep: PackedFloat32Array = space.cast_motion(query)
    if sweep.size() != 2 or sweep[0] < 0.995:
        return false
    # A free line above a hole/ledge is not a walkable path. Short segments suffice
    # for graph edges; long direct shortcuts sample support every 1.25 m.
    var steps: int = maxi(1, int(ceil(flat / 1.25)))
    for i in range(1, steps + 1):
        var point: Vector3 = start.lerp(finish, float(i) / float(steps))
        var floor_hit: Dictionary = _ground(point)
        if floor_hit.is_empty():
            return false
        var surface: Vector3 = floor_hit["point"]
        if absf(surface.y - point.y) > 0.48:
            return false
    return true

func nearest_id(at: Vector3, require_link: bool = true) -> int:
    var support: Dictionary = support_below(at)
    if support.is_empty():
        return -1
    var foot: Vector3 = support["point"]
    var cell: Vector2i = Vector2i(roundi(at.x/cell_size),roundi(at.z/cell_size))
    var candidates: Array[Dictionary] = []
    for z in range(-2,3):
        for x in range(-2,3):
            var key: Vector2i = cell+Vector2i(x,z)
            if not _cell_ids.has(key):
                continue
            for point_id in _cell_ids[key]:
                var point: Vector3 = graph.get_point_position(point_id)
                var flat: float = Vector2(point.x-foot.x,point.z-foot.z).length()
                if absf(point.y-foot.y) > maxf(0.6,flat*0.47):
                    continue
                # Even a jumping target projects onto its support, not the
                # Euclidean-nearest upper floor through a ceiling.
                candidates.append({"id":point_id,"distance":foot.distance_squared_to(point)})
    candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a["distance"] < b["distance"])
    for entry in candidates:
        var point_id: int = int(entry["id"])
        var point: Vector3 = graph.get_point_position(point_id)
        if can_travel(foot,point):
            return point_id
        if not require_link and absf(point.y-foot.y) < 0.45:
            # A small target can stand nearer a wall than the conservative horde
            # capsule. Project to the same floor with line-of-sight, not through it.
            var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(foot+Vector3.UP*0.8,point+Vector3.UP*0.8,1)
            if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
                return point_id
    return -1

func request_route(start: Vector3, finish: Vector3) -> Dictionary:
    if not built:
        return {"status": "building"}
    var frame: int = Engine.get_physics_frames()
    if _query_frame != frame:
        _query_frame = frame
        _queries_this_frame = 0
    var limit: int = 2 if RuntimeProfile.is_mobile else 4
    if _queries_this_frame >= limit:
        return {"status": "busy"}
    _queries_this_frame += 1
    path_queries += 1
    var from_id: int = nearest_id(start)
    # Jumping targets project to their nearest sampled floor. Final melee checks
    # still include actual height/range; no airborne hit through a platform.
    var to_id: int = nearest_id(finish, false)
    if from_id < 0 or to_id < 0 or _components.get(from_id, -1) != _components.get(to_id, -2):
        return {"status": "blocked", "path": PackedVector3Array()}
    return {"status": "ok", "path": graph.get_point_path(from_id, to_id)}

func spawn_anchor(candidate: Vector3, target: Vector3, min_distance: float = 18.0) -> Dictionary:
    if not built:
        return {}
    var a: int = nearest_id(candidate, false)
    var b: int = nearest_id(target, false)
    if a < 0 or b < 0 or _components.get(a, -1) != _components.get(b, -2):
        return {}
    var point: Vector3 = graph.get_point_position(a)
    if point.distance_to(candidate) > 4.0 or point.distance_to(target) < min_distance:
        return {}
    return {"position": point + Vector3.UP * 0.08, "surface_id": point_surfaces.get(a, &"street")}

func _label_components() -> void:
    var component: int = 0
    for id_value in graph.get_point_ids():
        if _components.has(id_value):
            continue
        var queue: Array[int] = [id_value]
        _components[id_value] = component
        var index: int = 0
        while index < queue.size():
            var node_id: int = queue[index]
            index += 1
            for neighbor in graph.get_point_connections(node_id):
                if not _components.has(neighbor):
                    _components[neighbor] = component
                    queue.append(neighbor)
        component += 1
