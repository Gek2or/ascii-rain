extends "res://world/districts/city_modules.gd"

const ENTRY_TINT: Color = Color(0.30, 0.82, 1.0)
const ROUTE_TINT: Color = Color(0.92, 0.74, 0.38)
const DANGER_TINT: Color = Color(1.0, 0.30, 0.20)

func _ready() -> void:
    district_id = &"market_ruins"
    init_palette()
    _configure_market_palette()
    _build_market_shell()
    _build_entry_lift()
    _build_tutorial_corridor()
    _build_broken_courtyard()
    _build_scan_node()
    _build_bypass_route()
    _build_side_cache()
    _build_archive_passage()
    _build_prep_room()
    _build_distortion_arena()
    _build_exit_lift()
    _add_route_markers()
    commit_trim()

func _configure_market_palette() -> void:
    # Sector 01 holds its large surfaces below the glyph threshold. Only route
    # edges, terminals and fixtures carry the cyan/amber/red readout.
    mats[0].albedo_color = Color(0.065, 0.082, 0.11)
    mats[1].albedo_color = Color(0.025, 0.032, 0.05)
    mats[2].albedo_color = Color(0.17, 0.23, 0.29)
    mats[3].albedo_color = Color(0.96, 0.33, 0.13)
    mats[4].albedo_color = Color(0.23, 0.78, 1.0)

func _build_market_shell() -> void:
    # The former generic market is no longer instantiated. These deliberate
    # exterior masses define the first location while keeping its city approach
    # and exit lift open.
    box("MarketWestShell", Vector3(24.0, 4.5, 46.0), Vector3(1.2, 9.0, 54.0), 1)
    box("MarketEastShell", Vector3(80.0, 4.5, 46.0), Vector3(1.2, 9.0, 54.0), 1)
    box("MarketNorthWestShell", Vector3(32.0, 4.5, 19.0), Vector3(16.0, 9.0, 1.2), 1)
    box("MarketNorthEastShell", Vector3(62.0, 4.5, 19.0), Vector3(34.0, 9.0, 1.2), 1)
    box("MarketSouthWestShell", Vector3(47.0, 4.5, 72.0), Vector3(46.0, 9.0, 1.2), 1)
    box("MarketSouthEastShell", Vector3(80.0, 4.5, 72.0), Vector3(1.2, 9.0, 1.2), 1)
    _add_ribs_z(Vector3(24.7, 4.2, 46.0), 12, 4.1, Vector3(0.14, 3.8, 0.18), 2)
    _add_ribs_z(Vector3(79.3, 4.2, 46.0), 12, 4.1, Vector3(0.14, 3.8, 0.18), 2)
    _add_ribs_x(Vector3(32.0, 4.2, 19.7), 8, 2.0, Vector3(0.16, 3.8, 0.14), 2)
    _add_ribs_x(Vector3(62.0, 4.2, 19.7), 16, 2.0, Vector3(0.16, 3.8, 0.14), 2)
    _add_ribs_x(Vector3(47.0, 4.2, 71.3), 20, 2.0, Vector3(0.16, 3.8, 0.14), 2)
    sign_label("SECTOR 01 // THRESHOLD MARKET", Vector3(44.0, 6.5, 19.65), 48, PI)
    lamp(Vector3(34.0, 6.4, 20.0), false)
    lamp(Vector3(54.0, 6.4, 20.0), false)

func _build_entry_lift() -> void:
    var center: Vector3 = Vector3(44.0, 0.04, 23.0)
    deck("Sector01EntryPad", center, Vector2(5.6, 5.6), &"market_entry")
    box("EntryLiftWest", Vector3(40.95, 2.5, 23.0), Vector3(0.45, 5.0, 6.2), 1)
    box("EntryLiftEast", Vector3(47.05, 2.5, 23.0), Vector3(0.45, 5.0, 6.2), 1)
    box("EntryLiftHeader", Vector3(44.0, 5.1, 20.35), Vector3(6.6, 0.65, 0.55), 1)
    box("EntryLiftConsole", Vector3(45.75, 0.65, 21.3), Vector3(0.55, 1.3, 0.48), 4)
    _add_ribs_x(Vector3(44.0, 4.15, 20.70), 5, 1.15, Vector3(0.13, 1.55, 0.16), 2)
    trim(Vector3(44.0, 0.08, 25.9), Vector3(4.8, 0.028, 0.16), 4)
    trim(Vector3(41.30, 1.35, 23.0), Vector3(0.12, 2.7, 4.9), 2)
    trim(Vector3(46.70, 1.35, 23.0), Vector3(0.12, 2.7, 4.9), 2)
    lamp(Vector3(42.0, 4.55, 21.5), false)

func _build_tutorial_corridor() -> void:
    deck("Sector01TutorialWalk", Vector3(44.0, 0.04, 30.0), Vector2(5.4, 9.4), &"market_tutorial")
    box("TutorialWestWall", Vector3(40.95, 2.2, 30.0), Vector3(0.45, 4.4, 9.8), 1)
    box("TutorialEastWall", Vector3(47.05, 2.2, 30.0), Vector3(0.45, 4.4, 9.8), 1)
    box("TutorialCoverA", Vector3(43.1, 0.7, 28.2), Vector3(1.2, 1.4, 0.9), 0)
    box("TutorialCoverB", Vector3(44.9, 0.55, 32.4), Vector3(1.0, 1.1, 1.2), 0)
    _add_ribs_z(Vector3(41.25, 2.15, 30.0), 5, 1.8, Vector3(0.14, 2.65, 0.18), 2)
    _add_ribs_z(Vector3(46.75, 2.15, 30.0), 5, 1.8, Vector3(0.14, 2.65, 0.18), 2)
    _add_ribs_z(Vector3(44.0, 4.15, 30.0), 5, 1.8, Vector3(4.9, 0.12, 0.16), 1)
    trim(Vector3(44.0, 0.08, 30.0), Vector3(0.14, 0.028, 7.8), 4)
    box("TutorialExitBulkhead", Vector3(44.0, 3.0, 34.45), Vector3(5.4, 5.6, 0.35), 1)
    box("TutorialExitOpening", Vector3(44.0, 2.6, 34.25), Vector3(2.7, 4.6, 0.18), 4, false)
    sign_label("FOLLOW // LIGHT", Vector3(44.0, 2.55, 34.75), 31, 0.0)
    lamp(Vector3(44.0, 3.9, 31.0), true)

func _build_broken_courtyard() -> void:
    deck("Sector01BrokenCourtyard", Vector3(35.0, 0.04, 40.0), Vector2(16.0, 14.0), &"market_courtyard")
    for wreck in [
        [Vector3(31.0, 0.8, 37.0), Vector3(2.2, 1.6, 1.3)],
        [Vector3(37.2, 0.65, 38.5), Vector3(2.8, 1.3, 1.1)],
        [Vector3(33.0, 0.55, 43.8), Vector3(1.4, 1.1, 2.4)],
        [Vector3(40.1, 0.75, 43.2), Vector3(1.6, 1.5, 1.6)]
    ]:
        var position: Vector3 = wreck[0]
        var dimensions: Vector3 = wreck[1]
        box("BrokenCourtyardCover", position, dimensions, 0)
    box("CourtyardNorthRubble", Vector3(35.0, 1.0, 33.4), Vector3(11.0, 2.0, 1.2), 1)
    box("CourtyardWestPier", Vector3(27.6, 2.5, 39.0), Vector3(0.8, 5.0, 9.0), 1)
    box("CourtyardEastPier", Vector3(42.4, 2.4, 39.2), Vector3(0.70, 4.8, 6.8), 1)
    box("CourtyardBrokenSpire", Vector3(32.2, 2.9, 34.5), Vector3(1.2, 5.8, 1.2), 1)
    box("CourtyardBrokenSpireCap", Vector3(33.1, 4.6, 34.5), Vector3(2.6, 0.55, 1.2), 2, false)
    box("BrokenCourtCore", Vector3(35.0, 1.15, 40.0), Vector3(5.8, 2.3, 3.6), 1)
    var broken_slab: Node3D = box("BrokenCourtSlab", Vector3(37.0, 2.7, 40.0), Vector3(7.0, 0.36, 1.15), 2, false)
    broken_slab.basis = Basis.from_euler(Vector3(0.16, -0.28, -0.10))
    var broken_beam: Node3D = box("BrokenCourtBeam", Vector3(33.5, 3.6, 42.1), Vector3(0.48, 5.6, 0.48), 1, false)
    broken_beam.basis = Basis.from_euler(Vector3(0.0, 0.0, -0.32))
    box("BrokenCourtCanopy", Vector3(39.7, 6.7, 36.1), Vector3(7.2, 0.42, 3.8), 1, false)
    box("BrokenCourtCanopyEdge", Vector3(39.7, 6.2, 38.0), Vector3(7.8, 0.22, 0.16), 3, false)
    _add_ribs_x(Vector3(35.0, 2.55, 34.15), 7, 1.50, Vector3(0.14, 2.2, 0.16), 2)
    trim(Vector3(27.95, 2.4, 39.0), Vector3(0.16, 3.8, 7.8), 2)
    trim(Vector3(42.05, 2.4, 39.2), Vector3(0.16, 3.6, 5.8), 2)
    trim(Vector3(35.0, 0.07, 40.0), Vector3(9.5, 0.028, 0.14), 3)
    trim(Vector3(35.0, 0.07, 40.0), Vector3(0.14, 0.028, 8.2), 3)
    lamp(Vector3(31.0, 4.4, 36.0), true)

func _build_scan_node() -> void:
    deck("Sector01ScanFloor", Vector3(46.0, 0.04, 42.0), Vector2(9.0, 8.0), &"market_scan")
    box("ScanNodeBackWall", Vector3(46.0, 2.7, 38.0), Vector3(9.5, 5.4, 0.65), 1)
    box("ScanNodeLeftPier", Vector3(41.7, 2.3, 40.0), Vector3(0.65, 4.6, 3.5), 0)
    box("ScanNodeRightPier", Vector3(50.3, 2.3, 40.0), Vector3(0.65, 4.6, 3.5), 0)
    box("ScanNodeCeilingFrame", Vector3(46.0, 5.35, 40.1), Vector3(8.4, 0.34, 0.48), 1, false)
    box("ScanNodeSignalColumn", Vector3(46.0, 2.5, 40.9), Vector3(0.30, 4.8, 0.30), 4, false)
    box("ScanNodeFrame", Vector3(46.0, 3.2, 38.45), Vector3(3.6, 0.35, 0.12), 4, false)
    _add_ribs_x(Vector3(46.0, 2.5, 38.28), 5, 1.55, Vector3(0.12, 2.1, 0.14), 2)
    _add_ribs_x(Vector3(46.0, 4.85, 38.26), 5, 1.55, Vector3(0.62, 0.12, 0.14), 4)
    trim(Vector3(42.05, 2.25, 40.0), Vector3(0.14, 3.8, 2.8), 2)
    trim(Vector3(49.95, 2.25, 40.0), Vector3(0.14, 3.8, 2.8), 2)
    trim(Vector3(46.0, 0.07, 40.1), Vector3(3.8, 0.028, 0.14), 4)
    sign_label("04 // SCAN NODE", Vector3(46.0, 4.7, 38.32), 37, PI)
    lamp(Vector3(48.8, 4.1, 40.0), false)

func _build_bypass_route() -> void:
    ramp("ScanAscent", Vector3(46.0, 0.0, 45.0), Vector3(58.0, 5.5, 45.0), 4.8, &"market_scan_ascent")
    deck("BypassBridge", Vector3(59.0, 5.54, 45.0), Vector2(14.0, 6.0), &"market_bypass")
    ramp("ArchiveDescent", Vector3(59.0, 5.5, 45.0), Vector3(70.0, 0.0, 50.0), 4.8, &"market_archive_descent")
    deck("BypassLanding", Vector3(70.0, 0.04, 50.0), Vector2(8.0, 8.0), &"market_archive_landing")
    box("BridgeHazardBeacon", Vector3(62.5, 6.2, 43.0), Vector3(0.45, 2.2, 0.45), 3, false)
    box("BridgeHazardBeacon", Vector3(65.0, 6.2, 47.0), Vector3(0.45, 2.2, 0.45), 3, false)
    box("BridgeSignalPylon", Vector3(54.2, 7.0, 43.0), Vector3(0.36, 3.0, 0.36), 2, false)
    box("BridgeSignalPylon", Vector3(68.0, 2.3, 49.0), Vector3(0.36, 3.0, 0.36), 2, false)
    rail("BypassNorthEdge", Vector3(52.2, 5.5, 42.2), Vector3(65.8, 5.5, 42.2))
    rail("BypassSouthEdge", Vector3(52.2, 5.5, 47.8), Vector3(65.8, 5.5, 47.8))
    sign_label("05 // BYPASS", Vector3(59.0, 7.1, 42.82), 33, PI)
    lamp(Vector3(59.0, 7.0, 45.0), true)

func _build_side_cache() -> void:
    var cache_position: Vector3 = Vector3(40.0, 5.58, 58.6)
    deck("SideCachePlatform", cache_position, Vector2(6.0, 6.0), &"market_cache")
    deck("CacheApproach", Vector3(42.0, 5.54, 54.0), Vector2(5.0, 5.0), &"market_cache_walk")
    deck("CacheCatwalk", Vector3(48.0, 5.54, 51.0), Vector2(12.0, 4.0), &"market_cache_walk")
    deck("CacheTurn", Vector3(54.0, 5.54, 48.5), Vector2(6.0, 7.0), &"market_cache_walk")
    rail("CacheWestEdge", Vector3(37.2, 5.5, 55.8), Vector3(37.2, 5.5, 61.4))
    rail("CacheSouthEdge", Vector3(37.2, 5.5, 61.4), Vector3(42.8, 5.5, 61.4))
    rail("CacheCatwalkNorth", Vector3(41.0, 5.5, 53.0), Vector3(52.0, 5.5, 53.0))
    rail("CacheTurnWest", Vector3(51.2, 5.5, 48.0), Vector3(51.2, 5.5, 51.8))
    box("SideCacheCrate", cache_position + Vector3(0.0, 0.62, 0.0), Vector3(1.8, 1.24, 1.15), 2)
    box("SideCacheScreen", cache_position + Vector3(0.0, 1.38, -0.60), Vector3(0.68, 0.22, 0.08), 4, false)
    trim(cache_position + Vector3(0.0, 0.08, 0.0), Vector3(3.2, 0.028, 2.4), 3)
    box("SideCacheAntenna", cache_position + Vector3(-1.2, 1.8, 0.4), Vector3(0.12, 2.4, 0.12), 4, false)
    sign_label("06 // SIDE CACHE", cache_position + Vector3(0.0, 2.0, -0.75), 28, PI)

func _build_archive_passage() -> void:
    deck("ArchivePassageFloor", Vector3(70.0, 0.04, 51.0), Vector2(8.0, 10.0), &"market_archive_passage")
    box("ArchivePassageEastWall", Vector3(74.25, 2.35, 51.0), Vector3(0.45, 4.7, 10.4), 1)
    box("ArchivePassageWestWall", Vector3(65.75, 2.35, 51.0), Vector3(0.45, 4.7, 10.4), 1)
    box("ArchivePassageLintel", Vector3(70.0, 4.7, 47.2), Vector3(8.9, 0.42, 0.5), 1)
    box("ArchivePassageCover", Vector3(68.9, 0.65, 53.0), Vector3(1.1, 1.3, 1.1), 0)
    _add_ribs_z(Vector3(66.05, 2.2, 51.0), 5, 1.75, Vector3(0.14, 2.45, 0.18), 2)
    _add_ribs_z(Vector3(73.95, 2.2, 51.0), 5, 1.75, Vector3(0.14, 2.45, 0.18), 2)
    _add_ribs_z(Vector3(70.0, 4.35, 51.0), 5, 1.75, Vector3(7.3, 0.12, 0.16), 1)
    trim(Vector3(70.0, 0.08, 51.0), Vector3(0.14, 0.028, 8.6), 4)
    sign_label("07 // ARCHIVE PASSAGE", Vector3(70.0, 3.8, 46.88), 28, PI)
    lamp(Vector3(70.0, 4.25, 53.5), false)

func _build_prep_room() -> void:
    var center: Vector3 = Vector3(70.0, 0.04, 59.0)
    deck("PrepRoomFloor", center, Vector2(8.5, 7.2), &"market_prep")
    box("PrepRoomNorthWall", center + Vector3(0.0, 2.4, -3.8), Vector3(8.9, 4.8, 0.5), 1)
    box("PrepRoomEastWall", center + Vector3(4.45, 2.4, 0.0), Vector3(0.5, 4.8, 7.6), 1)
    box("PrepRoomSouthWall", center + Vector3(0.0, 2.4, 3.8), Vector3(8.9, 4.8, 0.5), 1)
    box("PrepRoomTerminal", center + Vector3(1.8, 0.8, -2.7), Vector3(1.3, 1.6, 0.7), 4)
    box("PrepRoomSupply", center + Vector3(-1.7, 0.55, 2.2), Vector3(1.8, 1.1, 1.2), 2)
    _add_ribs_x(center + Vector3(0.0, 2.4, -3.48), 5, 1.55, Vector3(0.14, 2.1, 0.16), 2)
    _add_ribs_z(center + Vector3(4.12, 2.4, 0.0), 4, 1.8, Vector3(0.14, 2.1, 0.16), 2)
    trim(center + Vector3(0.0, 0.08, -1.35), Vector3(6.7, 0.028, 0.14), 4)
    trim(center + Vector3(-3.4, 0.08, 0.7), Vector3(0.14, 0.028, 3.4), 3)
    sign_label("08 // PREP ROOM", center + Vector3(0.0, 3.7, -3.45), 30, PI)
    lamp(center + Vector3(-2.8, 4.3, 0.0), true)

func _build_distortion_arena() -> void:
    var center: Vector3 = Vector3(57.5, 0.04, 62.0)
    deck("DistortionArenaFloor", center, Vector2(22.0, 14.0), &"market_arena")
    for angle_index in range(8):
        var angle: float = float(angle_index) / 8.0 * TAU
        var cover_position: Vector3 = center + Vector3(cos(angle) * 6.0, 0.75, sin(angle) * 4.2)
        box("ArenaCover", cover_position, Vector3(1.6, 1.5, 1.2), 0)
        trim(cover_position + Vector3.UP * 0.78, Vector3(0.74, 0.032, 0.10), 3)
    trim(center + Vector3(0.0, 0.07, -4.5), Vector3(14.0, 0.030, 0.14), 3)
    trim(center + Vector3(0.0, 0.07, 4.5), Vector3(14.0, 0.030, 0.14), 3)
    trim(center + Vector3(-6.5, 0.07, 0.0), Vector3(0.14, 0.030, 9.0), 3)
    trim(center + Vector3(6.5, 0.07, 0.0), Vector3(0.14, 0.030, 9.0), 3)
    for pylon in [Vector3(-7.2, 2.5, -5.0), Vector3(7.2, 2.5, -5.0), Vector3(-7.2, 2.5, 5.0), Vector3(7.2, 2.5, 5.0)]:
        box("ArenaDistortionPylon", center + pylon, Vector3(0.55, 5.0, 0.55), 1)
        box("ArenaPylonSignal", center + pylon + Vector3.UP * 1.5, Vector3(0.82, 0.16, 0.82), 3, false)
    trim(center + Vector3(0.0, 0.08, 0.0), Vector3(8.0, 0.028, 0.16), 4)
    trim(center + Vector3(0.0, 0.08, 0.0), Vector3(0.16, 0.028, 5.5), 4)
    sign_label("09 // DISTORTION ARENA", center + Vector3(0.0, 3.5, -6.9), 34, PI)
    lamp(center + Vector3(-6.2, 4.25, -4.2), true)
    lamp(center + Vector3(6.2, 4.25, 4.2), true)

func _build_exit_lift() -> void:
    var center: Vector3 = Vector3(76.0, 0.04, 68.0)
    deck("ArenaExitWalk", Vector3(71.0, 0.04, 68.0), Vector2(6.0, 4.0), &"market_exit_walk")
    deck("Sector01ExitPad", center, Vector2(5.4, 6.2), &"market_exit")
    box("ExitLiftWest", center + Vector3(-3.0, 2.5, 0.0), Vector3(0.45, 5.0, 6.7), 1)
    box("ExitLiftEast", center + Vector3(3.0, 2.5, 0.0), Vector3(0.45, 5.0, 6.7), 1)
    box("ExitLiftHeader", center + Vector3(0.0, 5.1, 2.9), Vector3(6.6, 0.65, 0.55), 1)
    box("ExitLiftArrow", center + Vector3(0.0, 2.8, 2.58), Vector3(1.2, 2.1, 0.10), 4, false)
    _add_ribs_x(center + Vector3(0.0, 4.15, 2.55), 5, 1.15, Vector3(0.13, 1.55, 0.16), 2)
    trim(center + Vector3(0.0, 0.08, -2.25), Vector3(4.8, 0.028, 0.16), 4)
    trim(center + Vector3(-2.7, 1.35, 0.0), Vector3(0.12, 2.7, 5.2), 2)
    trim(center + Vector3(2.7, 1.35, 0.0), Vector3(0.12, 2.7, 5.2), 2)
    sign_label("10 // EXIT LIFT", center + Vector3(0.0, 4.35, 2.48), 31, PI)
    lamp(center + Vector3(0.0, 4.35, 0.0), false)

func _add_route_markers() -> void:
    var nodes: Array[Dictionary] = _route_nodes()
    for entry in nodes:
        var data: Dictionary = entry
        var node_id: int = int(data["id"])
        var title_text: String = String(data["title"])
        var position: Vector3 = data["position"]
        var accent: Color = data["accent"]
        var marker: Node3D = box("Sector01Node%02d" % node_id, position + Vector3(0.0, 0.06, 0.0), Vector3(1.15, 0.08, 1.15), 3, false)
        marker.add_to_group("sector01_markers")
        var label: Label3D = _route_label("%02d // %s" % [node_id, title_text], position + Vector3(0.0, 1.95, 0.0), accent)
        label.modulate = accent

func _add_ribs_x(center: Vector3, count: int, spacing: float, dimensions: Vector3, material: int) -> void:
    var first: float = -0.5 * float(count - 1) * spacing
    for index in range(count):
        trim(center + Vector3(first + float(index) * spacing, 0.0, 0.0), dimensions, material)

func _add_ribs_z(center: Vector3, count: int, spacing: float, dimensions: Vector3, material: int) -> void:
    var first: float = -0.5 * float(count - 1) * spacing
    for index in range(count):
        trim(center + Vector3(0.0, 0.0, first + float(index) * spacing), dimensions, material)

func _route_label(text: String, at: Vector3, accent: Color) -> Label3D:
    var label: Label3D = Label3D.new()
    label.text = text
    label.font_size = 26
    label.pixel_size = 0.012
    label.modulate = accent
    label.outline_modulate = Color(0.03, 0.025, 0.02)
    label.outline_size = 8
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.position = at
    add_child(label)
    return label

func _route_nodes() -> Array[Dictionary]:
    return [
        {"id": 1, "title": "ENTRY", "position": Vector3(44.0, 0.04, 23.0), "accent": ENTRY_TINT, "yaw": PI},
        {"id": 2, "title": "TUTORIAL", "position": Vector3(44.0, 0.04, 30.0), "accent": ENTRY_TINT, "yaw": PI},
        {"id": 3, "title": "BROKEN COURT", "position": Vector3(35.0, 0.04, 40.0), "accent": DANGER_TINT, "yaw": PI},
        {"id": 4, "title": "SCAN NODE", "position": Vector3(46.0, 0.04, 42.0), "accent": ENTRY_TINT, "yaw": PI},
        {"id": 5, "title": "BYPASS", "position": Vector3(59.0, 5.58, 45.0), "accent": ROUTE_TINT, "yaw": PI},
        {"id": 6, "title": "SIDE CACHE", "position": Vector3(40.0, 5.58, 58.6), "accent": ROUTE_TINT, "yaw": PI},
        {"id": 7, "title": "ARCHIVE", "position": Vector3(70.0, 0.04, 51.0), "accent": ENTRY_TINT, "yaw": PI},
        {"id": 8, "title": "PREP", "position": Vector3(70.0, 0.04, 59.0), "accent": ROUTE_TINT, "yaw": PI},
        {"id": 9, "title": "ARENA", "position": Vector3(57.5, 0.04, 62.0), "accent": DANGER_TINT, "yaw": PI},
        {"id": 10, "title": "EXIT", "position": Vector3(76.0, 0.04, 68.0), "accent": ENTRY_TINT, "yaw": PI}
    ]
