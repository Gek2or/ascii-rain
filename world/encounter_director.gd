class_name EncounterDirector
extends Node

signal spawn_requested(center: Vector3, count: int, intensity: float)
signal district_entered(district_id: StringName, display_name: String, center: Vector3)

var player: Node3D = null
var difficulty: float = 1.0
var event_active: bool = false
var event_center: Vector3 = Vector3.ZERO

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _districts: Array = []
var _visited: Dictionary = {}
var _current_district: int = -1
var _check_timer: float = 0.0
var _ambient_timer: float = 7.5
var _first_wave_timer: float = -1.0
var _event_timer: float = 0.0
var _startup_grace: float = 7.0
var _budgets: Dictionary = {}
var _intro_completed: Dictionary = {}
var _pending_district: int = -1
var encounter_zone_id: StringName = &""
var visited_zones: Dictionary = {}
var _zone_candidate: StringName = &""
var _zone_checks: int = 0
var _living: Node = null
var _floor_service: StreetNavigation = null
var _floor_poll: float = 0.0
var _support_valid: bool = false
var _support_origin: Vector3 = Vector3.ZERO
var _supported_point: Vector3 = Vector3.ZERO

func _ready() -> void:
    _rng.seed = 912731
    _build_districts()

func configure(player_node: Node3D) -> void:
    player = player_node

func set_difficulty(value: float) -> void:
    difficulty = maxf(1.0, value)

func set_event_active(active: bool, center: Vector3 = Vector3.ZERO) -> void:
    event_active = active
    event_center = center
    _event_timer = 0.35 if active else 0.0

func _physics_process(delta: float) -> void:
    # Resolve physical support on physics ticks. A jump under a terrace must not
    # activate a different floor simply because the player's height crosses its band.
    _floor_poll -= delta
    if _floor_poll > 0.0 or not is_instance_valid(player):
        return
    _floor_poll = 0.12
    if not is_instance_valid(_floor_service):
        _floor_service = get_tree().get_first_node_in_group("street_navigation") as StreetNavigation
    if _floor_service == null:
        return
    var floor_hit: Dictionary = _floor_service.support_below(player.global_position)
    _support_origin = player.global_position
    _support_valid = not floor_hit.is_empty()
    if _support_valid:
        _supported_point = (floor_hit["point"] as Vector3) + Vector3.UP * 0.08

func _zone_position() -> Vector3:
    var p: Vector3 = player.global_position
    if _support_valid and Vector2(p.x-_support_origin.x,p.z-_support_origin.z).length() < 3.0 and absf(p.y-_support_origin.y) < 2.0:
        return _supported_point
    return p

func _process(delta: float) -> void:
    if not is_instance_valid(player):
        return
    _startup_grace = maxf(0.0, _startup_grace - delta)
    _check_timer -= delta
    if _check_timer <= 0.0:
        _check_timer = 0.20
        _update_current_district()
    if event_active:
        _event_timer -= delta
        _process_event_spawns()
        return
    if not get_tree().get_nodes_in_group("active_district_event").is_empty():
        return
    if _startup_grace > 0.0 or _current_district <= 0:
        return

    # Clamp at zero BEFORE testing; the old timer required hitting exactly 0.0.
    if _pending_district == _current_district and _first_wave_timer >= 0.0:
        _first_wave_timer = maxf(0.0, _first_wave_timer - delta)
        if _first_wave_timer <= 0.0:
            _spawn_first_wave()
            _intro_completed[_current_district] = true
            _pending_district = -1
            _first_wave_timer = -1.0
            _ambient_timer = 8.0
        return

    # Only the currently visited district earns credits. Inactive areas cannot
    # bank an unlimited ambush, and Arrival remains quiet outside the boss event.
    var budget: float = float(_budgets.get(_current_district, 0.0))
    budget = minf(8.0, budget + delta * clampf(0.27 + difficulty * 0.10, 0.35, 0.85))
    _budgets[_current_district] = budget
    _ambient_timer = maxf(0.0, _ambient_timer - delta)
    var local_cap: int = clampi(8 + int(difficulty * 2.0), 10, 24)
    if _ambient_timer > 0.0 or budget < 2.0:
        return
    var nearby_enemies: int = 0
    for candidate in get_tree().get_nodes_in_group("enemies"):
        var actor: Node3D = candidate as Node3D
        if actor != null and actor.global_position.distance_to(player.global_position) < 45.0:
            nearby_enemies += 1
    if nearby_enemies >= local_cap:
        return
    var count: int = clampi(int(floor(budget)), 2, 4)
    _budgets[_current_district] = budget - float(count)
    spawn_requested.emit(player.global_position, count, minf(1.05, 0.80 + difficulty * 0.04))
    _ambient_timer = _rng.randf_range(6.5, 10.0)

func _build_districts() -> void:
    _districts = [
        {"id": StringName("arrival"), "name": "ARRIVAL NODE", "center": Vector3(0, 0, 8), "radius": 26.0},
        {"id": StringName("archive_row"), "name": "ARCHIVE STACKS", "center": Vector3(50, 0, -20), "radius": 28.0},
        {"id": StringName("utility_spine"), "name": "UTILITY DEPTHS", "center": Vector3(-52, 0, -18), "radius": 28.0},
        {"id": StringName("market_ruins"), "name": "MARKET RUINS", "center": Vector3(45, 0, 43), "radius": 29.0},
        {"id": StringName("memory_gardens"), "name": "MEMORY GARDENS", "center": Vector3(-45, 0, 44), "radius": 29.0},
        {"id": StringName("null_terminal"), "name": "ROOFTOP RELAY", "center": Vector3(0, 0, -64), "radius": 27.0},
        {"id": StringName("signal_concourse"), "name": "TRANSIT SPINE", "center": Vector3(0, 0, 65), "radius": 26.0}
    ]
    _visited[StringName("arrival")] = true

func _update_current_district() -> void:
    var best_index: int = -1
    var best_distance: float = INF
    for i in range(_districts.size()):
        var entry: Dictionary = _districts[i]
        var center: Vector3 = entry.get("center", Vector3.ZERO)
        var radius: float = float(entry["radius"])
        var flat_delta: Vector3 = player.global_position - center
        flat_delta.y = 0.0
        var distance: float = flat_delta.length()
        if distance <= radius and distance < best_distance:
            best_distance = distance
            best_index = i

    _update_layer_zone()
    if _living != null:
        var layer: Dictionary = _living.call("zone_at", _zone_position())
        if not layer.is_empty():
            for i in range(_districts.size()):
                if _districts[i]["id"] == layer["district"]:
                    best_index = i
                    break
    if best_index == _current_district:
        return
    _current_district = best_index
    # A scheduled first wave belongs to its district, not wherever the player runs next.
    _pending_district = -1
    _first_wave_timer = -1.0
    _ambient_timer = 7.5
    if _current_district < 0:
        return

    var district: Dictionary = _districts[_current_district]
    var district_id: StringName = StringName(district.get("id", StringName("unknown")))
    var district_name: String = String(district["name"])
    var district_center: Vector3 = district.get("center", Vector3.ZERO)
    if not _visited.has(district_id):
        _visited[district_id] = true
        district_entered.emit(district_id, district_name, district_center)
        GameEvents.emit_district_entered(district_id, district_name)
    if _current_district > 0 and not _intro_completed.has(_current_district):
        _pending_district = _current_district
        _first_wave_timer = 2.60
    if not _budgets.has(_current_district):
        _budgets[_current_district] = 0.0

func _spawn_first_wave() -> void:
    if _current_district <= 0 or not is_instance_valid(player):
        return
    var count: int = clampi(2 + int((difficulty - 1.0) * 0.50), 2, 4)
    spawn_requested.emit(player.global_position, count, 1.0)

func _process_event_spawns() -> void:
    if _event_timer > 0.0:
        return
    var center: Vector3 = event_center
    if is_instance_valid(player):
        center = player.global_position.lerp(event_center, 0.35)
    var count: int = clampi(2 + int((difficulty - 1.0) * 0.75), 2, 6)
    spawn_requested.emit(center, count, 1.35)
    _event_timer = _rng.randf_range(2.1, 3.4) / clampf(difficulty * 0.75, 1.0, 2.0)

func get_current_district_name() -> String:
    if _current_district < 0 or _current_district >= _districts.size():
        return "TRANSIT"
    var district: Dictionary = _districts[_current_district]
    return String(district["name"])

func get_visited_count() -> int:
    return _visited.size()

func get_district_catalog() -> Array:
    return _districts.duplicate(true)

func _update_layer_zone() -> void:
    if not is_instance_valid(_living):
        _living = get_tree().get_first_node_in_group("living_city")
    if _living == null:
        return
    var entry: Dictionary = _living.call("zone_at",_zone_position())
    var candidate: StringName = StringName(entry.get("id",&""))
    if candidate != _zone_candidate:
        _zone_candidate = candidate
        _zone_checks = 1
        return
    _zone_checks += 1
    if _zone_checks >= 2:
        encounter_zone_id = candidate
        if not candidate.is_empty():
            visited_zones[candidate] = true
    # Floor changes never emit district_entered, reset budget, or repeat intro.

func get_encounter_zone() -> StringName:
    return encounter_zone_id

func get_current_district_id() -> StringName:
    if _current_district<0 or _current_district>=_districts.size(): return &""
    return StringName(_districts[_current_district]["id"])
