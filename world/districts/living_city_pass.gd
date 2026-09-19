extends Node3D

const UTILITY: PackedScene = preload("res://world/districts/utility_depths.tscn")
const ROOFTOPS: PackedScene = preload("res://world/districts/rooftop_relay.tscn")
const TRANSIT: PackedScene = preload("res://world/districts/transit_spine.tscn")
const ARCHIVE: PackedScene = preload("res://world/districts/archive_stacks.tscn")
const GARDENS: PackedScene = preload("res://world/districts/memory_gardens.tscn")
const THRESHOLD_SECTOR = preload("res://world/districts/threshold_market_sector.gd")
const THRESHOLD_SOUNDS = preload("res://world/ambient/threshold_market_soundscape.gd")
const CIVIC_AMBIENT = preload("res://world/ambient/civic_atmosphere.gd")
const AMBIENT = preload("res://world/ambient/city_ambient.gd")
@export var first_location_only: bool = false
var zones: Array[Dictionary] = []
var anchors: Array[Dictionary] = []

func _ready() -> void:
    add_to_group("living_city")
    var threshold_sector: Node3D = THRESHOLD_SECTOR.new() as Node3D
    threshold_sector.name = "ThresholdMarketSector"
    add_child(threshold_sector)
    if first_location_only:
        _register_threshold_location()
        var soundscape: Node3D = THRESHOLD_SOUNDS.new() as Node3D
        soundscape.name = "ThresholdMarketSoundscape"
        add_child(soundscape)
        # Shared ambience/events are city-wide systems with hard references to
        # later districts. Location 01 receives only authored sector fixtures.
        return
    add_child(TRANSIT.instantiate())
    add_child(ARCHIVE.instantiate())
    add_child(GARDENS.instantiate())
    add_child(UTILITY.instantiate())
    add_child(ROOFTOPS.instantiate())
    var frontage: Node3D=preload("res://world/districts/reference_street.gd").new()
    frontage.name="ReferenceFrontage"
    add_child(frontage)
    _register_last_districts()
    _zone(&"market_ground",&"market_ruins","MARKET / COURTYARD",AABB(Vector3(24,-1,20),Vector3(55,5.6,51)))
    _zone(&"market_gallery",&"market_ruins","MARKET / GALLERY +5.5m",AABB(Vector3(24,4.8,25),Vector3(42,6.5,37)))
    _zone(&"transit_ground",&"signal_concourse","TRANSIT / LOWER HALL",AABB(Vector3(-23,-1,38),Vector3(46,5.6,37)))
    _zone(&"transit_platform",&"signal_concourse","TRANSIT / PLATFORM +5.5m",AABB(Vector3(-20,4.8,55),Vector3(40,6.5,19)))
    for point in [Vector3(29,0.08,55),Vector3(45,0.08,22),Vector3(60,0.08,45),Vector3(67,0.08,55),Vector3(38,0.08,42)]:
        _anchor(&"market_ground",point)
    for point in [Vector3(44,0.08,23),Vector3(44,0.08,30),Vector3(35,0.08,40),Vector3(46,0.08,42),Vector3(70,0.08,51),Vector3(70,0.08,59),Vector3(57.5,0.08,62),Vector3(76,0.08,68)]:
        _anchor(&"market_ground",point)
    for point in [Vector3(40,5.58,58.6),Vector3(47,5.58,52),Vector3(55,5.58,48.5),Vector3(59,5.58,45)]:
        _anchor(&"market_gallery",point)
    for point in [Vector3(-21,0.08,58),Vector3(21,0.08,58),Vector3(0,0.08,72),Vector3(0,0.08,43)]:
        _anchor(&"transit_ground",point)
    for point in [Vector3(-15,5.58,58),Vector3(-8,5.58,68),Vector3(15,5.58,60),Vector3(8,5.58,68),Vector3(0,5.58,64)]:
        _anchor(&"transit_platform",point)
    _zone(&"archive_ground",&"archive_row","ARCHIVE / INDEX COURT",AABB(Vector3(29,-1,-44),Vector3(47,5.6,51)))
    _zone(&"archive_gallery",&"archive_row","ARCHIVE / READING GALLERY +5.5m",AABB(Vector3(29,4.8,-44),Vector3(47,8,51)))
    _zone(&"gardens_ground",&"memory_gardens","GARDENS / CATCHMENT WALK",AABB(Vector3(-74,-1,18),Vector3(49,3.3,55)))
    _zone(&"gardens_terrace",&"memory_gardens","GARDENS / TERRACES +2.75m",AABB(Vector3(-74,2.3,18),Vector3(49,2.4,55)))
    _zone(&"gardens_pavilion",&"memory_gardens","GARDENS / PAVILION +5.5m",AABB(Vector3(-74,4.8,18),Vector3(49,8,55)))
    for point in [Vector3(51,0.08,5),Vector3(51,0.08,-39),Vector3(51,0.08,-30),Vector3(40,0.08,-27),Vector3(62,0.08,-22),Vector3(51,0.08,-37)]:
        _anchor(&"archive_ground",point)
    for point in [Vector3(40,5.58,-35),Vector3(62,5.58,-35),Vector3(51,5.58,-30),Vector3(40,5.58,-16),Vector3(62,5.58,-16),Vector3(51,5.58,-16)]:
        _anchor(&"archive_gallery",point)
    for point in [Vector3(-43,0.08,21),Vector3(-51,0.08,30),Vector3(-47,0.08,46),Vector3(-35,0.08,59),Vector3(-66,0.08,70),Vector3(-70,0.08,31)]:
        _anchor(&"gardens_ground",point)
    for point in [Vector3(-67,2.83,39),Vector3(-57,2.83,39),Vector3(-64,2.83,46),Vector3(-64,2.83,53)]:
        _anchor(&"gardens_terrace",point)
    for point in [Vector3(-31,5.58,51),Vector3(-40,5.58,51),Vector3(-35,5.58,61),Vector3(-32,5.58,67),Vector3(-40,5.58,65)]:
        _anchor(&"gardens_pavilion",point)
    var atmosphere: Node3D = CIVIC_AMBIENT.new() as Node3D
    atmosphere.name = "CivicAtmosphere"
    add_child(atmosphere)
    var ambient: Node3D = AMBIENT.new() as Node3D
    ambient.name = "AmbientSystems"
    add_child(ambient)
    var events: Node3D=preload("res://world/events/district_events.gd").new()
    events.name="DistrictEvents"
    add_child(events)

func _zone(id: StringName, district: StringName, title: String, bounds: AABB) -> void:
    zones.append({"id":id,"district":district,"title":title,"bounds":bounds})

func _register_threshold_location() -> void:
    _zone(&"market_ground", &"market_ruins", "MARKET / COURTYARD", AABB(Vector3(24, -1, 20), Vector3(55, 5.6, 51)))
    _zone(&"market_gallery", &"market_ruins", "MARKET / GALLERY +5.5m", AABB(Vector3(24, 4.8, 25), Vector3(42, 6.5, 37)))
    for point in [Vector3(29, 0.08, 55), Vector3(45, 0.08, 22), Vector3(60, 0.08, 45), Vector3(67, 0.08, 55), Vector3(38, 0.08, 42), Vector3(44, 0.08, 23), Vector3(44, 0.08, 30), Vector3(35, 0.08, 40), Vector3(46, 0.08, 42), Vector3(70, 0.08, 51), Vector3(70, 0.08, 59), Vector3(57.5, 0.08, 62), Vector3(76, 0.08, 68)]:
        _anchor(&"market_ground", point)
    for point in [Vector3(40, 5.58, 58.6), Vector3(47, 5.58, 52), Vector3(55, 5.58, 48.5), Vector3(59, 5.58, 45)]:
        _anchor(&"market_gallery", point)

func _anchor(zone: StringName, point: Vector3) -> void:
    anchors.append({"zone":zone,"position":point})

func zone_at(point: Vector3) -> Dictionary:
    # Non-overlapping height bands avoid upper-wave activation from underneath.
    for zone in zones:
        var bounds: AABB = zone["bounds"]
        if bounds.has_point(point):
            return zone
    return {}

func anchors_for(zone_id: StringName) -> Array[Vector3]:
    var points: Array[Vector3] = []
    for entry in anchors:
        if entry["zone"] == zone_id:
            points.append(entry["position"])
    return points

func entrance_for(district: StringName) -> Vector3:
    match district:
        &"archive_row": return Vector3(51,0,4)
        &"memory_gardens": return Vector3(-43,0,24)
        &"market_ruins": return Vector3(44,0,23)
        &"utility_spine": return Vector3(-66,0,12)
        &"null_terminal": return Vector3(-29,0,-21)
    return Vector3(0,0,44)

func exit_hint(at: Vector3) -> Dictionary:
    var zone: Dictionary = zone_at(at)
    if not zone.is_empty() and zone["district"] == &"utility_spine" and at.y < -0.6:
        var south: Vector3 = Vector3(-66,-6,-10)
        var north: Vector3 = Vector3(-42,-6,-23)
        return {"position":south if south.distance_squared_to(at)<north.distance_squared_to(at) else north,"caption":"ASCENT / STREET"}
    if zone.is_empty() or at.y < 2.3:
        return {}
    var entrances: Array[Vector3] = []
    if zone["district"] == &"market_ruins":
        entrances = [Vector3(32,5.5,34),Vector3(50,5.5,52)]
    elif zone["district"] == &"archive_row":
        entrances = [Vector3(40,5.5,-12),Vector3(62,5.5,-12)]
    elif zone["district"] == &"memory_gardens":
        if at.y >= 4.8:
            entrances = [Vector3(-31,5.5,48)]
        else:
            entrances = [Vector3(-52,2.75,40),Vector3(-64,2.75,36)]
    elif zone["district"] == &"null_terminal":
        entrances = [Vector3(-29,10,-56),Vector3(25.5,10,-56)]
    else:
        entrances = [Vector3(-12,5.5,56),Vector3(12,5.5,56)]
    var best: Vector3 = entrances[0]
    for point in entrances:
        if point.distance_squared_to(at) < best.distance_squared_to(at):
            best = point
    return {"position":best,"caption":"DESCENT / STREET"}

func is_elevated_zone(zone_id: StringName) -> bool:
    for zone in zones:
        if zone["id"] == zone_id:
            return (zone["bounds"] as AABB).position.y > 1.0
    return false

func requires_authored_spawn(zone_id: StringName) -> bool:
    return is_elevated_zone(zone_id) or zone_id == &"utility_lower"

func _register_last_districts() -> void:
    _zone(&"utility_lower",&"utility_spine","UTILITY / PRESSURE HALL -6m",AABB(Vector3(-77,-7,-48),Vector3(43,6.3,60)))
    _zone(&"utility_street",&"utility_spine","UTILITY / SERVICE ACCESS",AABB(Vector3(-77,-0.7,-48),Vector3(43,5.5,62)))
    _zone(&"relay_roofs",&"null_terminal","RELAY / UPPER NETWORK +10m",AABB(Vector3(-38,6.0,-81),Vector3(76,18,40)))
    _zone(&"relay_street",&"null_terminal","RELAY / ARENA APPROACH",AABB(Vector3(-38,-1,-81),Vector3(76,7.0,40)))
    # Slim entrance corridors claim the relay district without swallowing archives.
    _zone(&"relay_street",&"null_terminal","RELAY / WEST ASCENT",AABB(Vector3(-33.2,-0.7,-41),Vector3(8.4,6.7,22)))
    _zone(&"relay_street",&"null_terminal","RELAY / EAST ASCENT",AABB(Vector3(21.3,-0.7,-41),Vector3(7.9,6.7,22)))
    for point in [Vector3(-66,-5.92,-16),Vector3(-68,-5.92,-36),Vector3(-42,-5.92,-16),Vector3(-62,-5.92,2),Vector3(-46,-5.92,2),Vector3(-53,-5.92,-38),Vector3(-51,-5.92,-21)]:
        _anchor(&"utility_lower",point)
    for point in [Vector3(-73,0.08,-38),Vector3(-52,0.08,-39),Vector3(-56,0.08,4),Vector3(-38,0.08,-10)]:
        _anchor(&"utility_street",point)
    for point in [Vector3(-29,10.08,-61),Vector3(-29,10.08,-73),Vector3(-17,10.08,-77),Vector3(0,10.08,-77),Vector3(17,10.08,-77),Vector3(29,10.08,-61),Vector3(29,10.08,-72)]:
        _anchor(&"relay_roofs",point)
    for point in [Vector3(-15,0.08,-46),Vector3(15,0.08,-47),Vector3(20,0.08,-72),Vector3(-20,0.08,-71)]:
        _anchor(&"relay_street",point)
