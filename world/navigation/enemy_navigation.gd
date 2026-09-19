extends RefCounted

# Per-actor cached route. No physics-body teleports and no direct-through-wall
# fallback when a route cannot be found. The shared graph bounds A* requests.
var service: StreetNavigation = null
var _path: PackedVector3Array = PackedVector3Array()
var _waypoint: int = 0
var _timer: float = 0.0
var _goal: Vector3 = Vector3(INF, INF, INF)
var _last_position: Vector3 = Vector3.ZERO
var _stationary: float = 0.0
var _initialised: bool = false

func direction(actor: CharacterBody3D, goal: Vector3, delta: float) -> Vector3:
    if not is_instance_valid(service):
        service = actor.get_tree().get_first_node_in_group("street_navigation") as StreetNavigation
    if service == null:
        return Vector3.ZERO
    _timer -= delta
    var feet: Vector3 = actor.global_position
    if not _initialised:
        _last_position = feet
        _initialised = true
    # Collision can set velocity to zero; detect requested path progress instead.
    var following: bool=_waypoint<_path.size() and feet.distance_to(_path[_waypoint])>0.9
    if Vector2(feet.x - _last_position.x, feet.z - _last_position.z).length() < 0.008 and following:
        _stationary += delta
    else:
        _stationary = 0.0
    _last_position = feet
    if _stationary > 0.7:
        _timer = minf(_timer, 0.0)
        _path = PackedVector3Array()
        _stationary = 0.0
    if _timer <= 0.0:
        # Use only close, physically supported shortcuts. This avoids repeatedly
        # casting across an entire city while a player crosses a distant district.
        if feet.distance_to(goal) < 12.0 and service.can_travel(feet, goal):
            _path = PackedVector3Array([goal])
            _waypoint = 0
            _goal = goal
            _timer = 0.24
        elif _path.is_empty() or _waypoint >= _path.size() or goal.distance_to(_goal) > 2.0:
            var response: Dictionary = service.request_route(feet, goal)
            if response["status"] == "busy" or response["status"] == "building":
                _timer = 0.04 + float(actor.get_instance_id() % 5) * 0.012
            else:
                _path = response.get("path", PackedVector3Array())
                _waypoint = 0
                _goal = goal
                _timer = 0.48 + float(actor.get_instance_id() % 7) * 0.04
        else:
            _timer = 0.28
    while _waypoint < _path.size():
        var offset: Vector3 = _path[_waypoint] - feet
        offset.y = 0.0
        if offset.length() < 0.60 and absf(_path[_waypoint].y - feet.y) < 0.9:
            _waypoint += 1
        else:
            return offset.normalized()
    return Vector3.ZERO

func reset() -> void:
    _path = PackedVector3Array()
    _waypoint = 0
    _timer = 0.0
    _goal = Vector3(INF, INF, INF)
    _stationary = 0.0
