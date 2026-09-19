extends SceneTree

var _failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if condition:
        return
    _failures += 1
    push_error("LOCATION01_SMOKE_FAIL: %s" % message)

func _run() -> void:
    change_scene_to_file("res://scenes/Location01_ThresholdMarket.tscn")
    for frame in range(28):
        await process_frame
    var game: Node3D = current_scene as Node3D
    var city: Node3D = game.get_node_or_null("City") as Node3D
    var living: Node3D = get_first_node_in_group("living_city") as Node3D
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var portal: Node3D = game.get("teleporter") as Node3D
    var soundscape: Node3D = living.get_node_or_null("ThresholdMarketSoundscape") as Node3D if living != null else null
    _expect(game.get("location_profile") == "threshold_market", "location profile is active")
    _expect(city != null and city.get("build_profile") == "threshold_market", "city builds only location 01")
    _expect(living != null and living.get_node_or_null("ThresholdMarketSector") != null, "threshold sector is present")
    _expect(living != null and living.get_node_or_null("transit_spine") == null, "other districts are absent")
    _expect(get_nodes_in_group("sector01_markers").size() == 10, "all ten authored route nodes are present")
    _expect(get_nodes_in_group("walkable_surfaces").size() >= 12, "location decks and ramps expose navigation surfaces")
    _expect(player != null and player.global_position.distance_to(Vector3(44.0, 0.1, 23.0)) < 0.25, "player starts at the entry lift")
    _expect(portal != null and portal.global_position.distance_to(Vector3(57.5, 0.15, 62.0)) < 0.25, "portal is placed in the distortion arena")
    _expect(living != null and living.call("zone_at", Vector3(46.0, 0.1, 42.0)).get("district", &"") == &"market_ruins", "scan node belongs to market ruins")
    _expect(soundscape != null, "location soundscape is loaded")
    _expect(soundscape != null and soundscape.get_node_or_null("BridgeRain") != null, "bridge rain loop is available")
    _expect(soundscape != null and soundscape.get_node_or_null("ScanNodeTyping") != null, "scan node typing loop is available")
    _expect(soundscape != null and soundscape.get_node_or_null("EntryBootGlitch") != null and soundscape.get_node_or_null("CacheAccessGlitch") != null, "location one-shots are available")
    if player != null and soundscape != null:
        player.global_position = Vector3(46.0, 0.1, 42.0)
        soundscape.call("_process", 0.2)
        soundscape.call("_process", 0.2)
        var rain: AudioStreamPlayer3D = soundscape.get_node("BridgeRain") as AudioStreamPlayer3D
        _expect(rain.playing, "bridge rain loop starts while ambience is enabled")
        var typing: AudioStreamPlayer3D = soundscape.get_node("ScanNodeTyping") as AudioStreamPlayer3D
        _expect(typing.playing, "scan node typing starts in range")
        player.global_position = Vector3(44.0, 0.1, 27.0)
        soundscape.call("_process", 0.2)
        var entry_glitch: AudioStreamPlayer3D = soundscape.get_node("EntryBootGlitch") as AudioStreamPlayer3D
        _expect(entry_glitch.playing, "entry glitch plays at the tutorial threshold")
        player.global_position = Vector3(40.0, 5.58, 58.6)
        soundscape.call("_process", 0.2)
        var cache_glitch: AudioStreamPlayer3D = soundscape.get_node("CacheAccessGlitch") as AudioStreamPlayer3D
        _expect(cache_glitch.playing, "cache glitch plays at the optional reward")
    game.queue_free()
    for frame in range(8):
        await process_frame
    print("LOCATION01_SMOKE: %d checks / %d failures" % [17, _failures])
    quit(1 if _failures > 0 else 0)
