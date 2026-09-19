extends SceneTree
# Integration test uses real scenes, GUI signals, physics and gameplay scripts.
# Scripted kills/teleports accelerate progression; this is NOT a balance playtest.
var checks: int = 0
var failures: int = 0
var _game: Node = null
var _player: CharacterBody3D = null
var _choice: Node = null
var _guide: Node = null

func _initialize() -> void:
    if not OS.get_cmdline_user_args().has("--test-isolated"):
        push_error("Run this test using the isolated test runner; it writes a TEST archive.")
        quit(2)
        return
    call_deferred("_run")

func _run() -> void:
    _expect(change_scene_to_file("res://scenes/Main.tscn") == OK, "Main loads")
    for frame in range(12):
        await physics_frame
    _game = current_scene
    _player = _game.get_node("Player") as CharacterBody3D
    _player.set("_invulnerability_timer", 360.0)
    _choice = _game.get_node("RelicChoice")
    _guide = _game.get_node("RunGuide")
    var starter: Node3D = _game.get("_starter_cache") as Node3D
    var portal: Node3D = _game.get("teleporter") as Node3D
    var director: Node = _game.get_node("EncounterDirector")
    var story: Node = _game.get_node("StoryDirector")
    var menu: Node = _game.get_node("SettingsMenu")
    var inv: InventoryComponent = _player.get_node("InventoryComponent") as InventoryComponent
    _expect(story.get_node("RealityInspection").is_inside_tree(), "story overlay is attached, not orphaned")
    _expect(bool(portal.get("route_locked")), "teleporter locked at arrival")
    portal.call("interact", _player)
    _expect(not bool(portal.get("active")), "locked portal rejects interact")
    _player.global_position = starter.global_position + Vector3(0, 0, 1.4)
    for frame in range(3):
        await physics_frame
    _expect(bool(_game.call("_has_interaction_sight", starter)), "starter is physically reachable")
    starter.call("interact", _player)
    _expect(paused and bool(_choice.get("_open")), "cache opens paused modal")
    var first_offer: Array = starter.get("cached_offer").duplicate()
    _expect(first_offer.size() == 3, "three initial cards")
    var clock: float = float(_game.get("elapsed"))
    var pos: Vector3 = _player.global_position
    Input.action_press("move_forward")
    Input.action_press("shoot")
    menu.call("set_open", true)
    await create_timer(0.22, true, false, true).timeout
    _expect(is_equal_approx(clock, float(_game.get("elapsed"))) and _player.global_position.is_equal_approx(pos), "combat and run timer frozen")
    _expect(not bool(menu.get("_is_open")), "settings cannot steal relic modal")
    _choice.call("_close")
    Input.action_release("move_forward")
    Input.action_release("shoot")
    _expect(not paused and not bool(starter.get("opened")) and int(_player.get("credits")) == 0, "cancel free and leaves chest")
    starter.call("interact", _player)
    _expect(first_offer == starter.get("cached_offer"), "cancel cannot reroll")
    await create_timer(0.20, true, false, true).timeout
    var first_button: Button = (_choice.get("_buttons") as Array)[0] as Button
    first_button.pressed.emit()
    first_button.pressed.emit()
    _expect(not paused and bool(starter.get("opened")), "native GUI button commits starter")
    _expect(inv.stack(&"chain_arc") == 1 and int(_player.get("credits")) == 0, "double click grants once, costs zero")
    var progress: RunProgress = _guide.get("progress") as RunProgress
    _expect(progress.loadout_claimed and progress.caches_opened == 1, "guide observes claim")
    var paid: Node3D = null
    for node in get_nodes_in_group("interactables"):
        if node.get_script() == starter.get_script() and node != starter:
            paid = node as Node3D
            break
    _player.global_position = paid.global_position + Vector3(0, 0, 1.4)
    for frame in range(3):
        await physics_frame
    paid.call("interact", _player)
    await create_timer(0.20, true, false, true).timeout
    _choice.call("_choose", 0)
    _expect(paused and not bool(paid.get("opened")), "insufficient funds do not consume cache")
    _choice.call("_close")
    _player.call("add_credits", 100)
    paid.call("interact", _player)
    await create_timer(0.20, true, false, true).timeout
    var paid_id: StringName = StringName((paid.get("cached_offer") as Array)[0])
    var stack_before: int = inv.stack(paid_id)
    _choice.call("_choose", 0)
    _expect(int(_player.get("credits")) == 100 - int(paid.get("cost")), "only accepted choice debits exact price")
    _expect(inv.stack(paid_id) == stack_before + 1, "paid reward grants one stack")
    # Real district detection; first waves also pass world collision queries.
    director.set("_startup_grace", 0.0)
    _player.global_position = Vector3(50, 0.1, -20)
    for frame in range(210):
        await physics_frame
    _expect(progress.visited.size() >= 1 and get_nodes_in_group("enemies").size() >= 2, "district visit emits materializing wave")
    _player.global_position = Vector3(-50, 0.1, -20)
    for frame in range(30):
        await physics_frame
    _expect(not bool(portal.get("route_locked")), "second physical district unlocks portal")
    # Deliberately put a wall between player and cache: cannot use through it.
    var wall: StaticBody3D = StaticBody3D.new()
    var shape: CollisionShape3D = CollisionShape3D.new()
    var box: BoxShape3D = BoxShape3D.new()
    box.size = Vector3(5, 5, 0.3)
    shape.shape = box
    wall.add_child(shape)
    _game.add_child(wall)
    _player.global_position = starter.global_position + Vector3(0, 0, 2)
    wall.global_position = starter.global_position + Vector3(0, 1, 1)
    for frame in range(3):
        await physics_frame
    _expect(not bool(_game.call("_has_interaction_sight", starter)), "interaction respects a blocking wall")
    wall.queue_free()
    _player.global_position = portal.global_position + Vector3(4, 0, 0)
    for frame in range(3):
        await physics_frame
    portal.call("interact", _player)
    _expect(progress.started_event and is_instance_valid(_game.get("boss")), "activation spawns WATCHER")
    var music_player: AudioStreamPlayer = root.get_node("AudioManager/DistrictMusic") as AudioStreamPlayer
    var audio_lighting: Node3D = _game.get_node("AudioReactiveLighting") as Node3D
    var portal_light: OmniLight3D = audio_lighting.get_node_or_null("PortalPulseLight") as OmniLight3D
    var sky_projector: SpotLight3D = audio_lighting.get_node_or_null("PortalSkyProjector") as SpotLight3D
    var event_light: DirectionalLight3D = audio_lighting.get_node_or_null("PortalEventLight") as DirectionalLight3D
    _expect(music_player.stream.resource_path == "res://assets/music/corrupted_signal.wav" and music_player.playing, "portal activation starts Corrupted Signal")
    _expect(portal_light != null and portal_light.light_energy > 0.0, "portal creates a live local chaos light")
    _expect(sky_projector != null and sky_projector.global_position.y > portal.global_position.y + 60.0 and sky_projector.spot_range >= 180.0, "portal projects music light down from above the sector")
    _expect(event_light != null and event_light.light_energy > 0.0 and not event_light.shadow_enabled, "portal event adds a bounded global light without shadow cost")
    var chaos_before: float = float(audio_lighting.get("_portal_chaos_remaining"))
    audio_lighting.call("_process", 1.0)
    _expect(float(audio_lighting.get("_portal_chaos_remaining")) < chaos_before and float(audio_lighting.get("_portal_chaos_remaining")) > 0.0, "portal light chaos fades over a bounded interval")
    _player.global_position += Vector3(30, 0, 0)
    for frame in range(3):
        await physics_frame
    var outside_charge: float = float(portal.get("charge"))
    for frame in range(15):
        await physics_frame
    _expect(is_equal_approx(outside_charge, float(portal.get("charge"))), "leaving field pauses charge")
    var boss: Node = _game.get("boss") as Node
    boss.call("take_damage", float(boss.get("max_health")) * 0.50)
    _expect(int(boss.get("phase")) == 2, "WATCHER phase 2 triggers")
    boss.call("take_damage", 100000.0)
    for frame in range(3):
        await physics_frame
    _expect(progress.boss_defeated and not bool(portal.get("exit_ready")), "boss before charge does not finish")
    _expect(not director.is_processing(), "no new ambient waves after boss death")
    portal.set("charge_duration", 0.2)
    _player.global_position = portal.global_position + Vector3(4, 0, 0)
    for frame in range(50):
        await physics_frame
    _expect(bool(portal.get("exit_ready")) and bool(_game.get("_sector_secured")), "charge plus boss opens exit")
    _expect(get_nodes_in_group("enemies").is_empty() and get_nodes_in_group("hostile_projectiles").is_empty(), "sector secured removes remaining hostiles without kills")
    _expect(progress.stage == RunProgress.Stage.RECOVER, "unseen physical toy is optional objective")
    var artifact: Node = null
    for node in get_nodes_in_group("interactables"):
        if str(node.get("artifact_id")) == "memory_02":
            artifact = node
            break
    _expect(artifact != null, "actual toy anomaly spawned after boss")
    if artifact != null:
        _player.global_position = (artifact as Node3D).global_position + Vector3(0, 0, 1.4)
        artifact.call("interact", _player)
        await process_frame
        _expect(paused and bool(story.get("_inspection_open")), "unfiltered story viewport visible on pause")
        _expect(story.get("_overlay").visible and story.get("_overlay_layer").is_inside_tree(), "story UI in live tree")
        menu.call("set_open", true)
        _expect(not bool(menu.get("_is_open")), "settings cannot steal story modal")
        story.call("_close_inspection")
        _expect(not paused and progress.stage == RunProgress.Stage.EXIT, "story close restores run and updates goal")
    _player.global_position = portal.global_position + Vector3(1.8, 0, 0)
    portal.call("interact", _player)
    _expect(bool(_game.get("run_complete")) and progress.stage == RunProgress.Stage.COMPLETE, "earned extraction completes")
    _expect(_game.get_node("HUD/CompletePanel").visible, "result screen visible")
    _expect("CACHES 2" in str(_game.get_node("HUD/CompletePanel/Summary").text), "result counts claimed caches")
    _expect("NEW REALITY FRAGMENTS 1" in str(_game.get_node("HUD/CompletePanel/Summary").text), "result counts new archive records")
    _game.call("_on_restart_pressed")
    for frame in range(15):
        await physics_frame
    _game = current_scene
    _player = _game.get_node("Player") as CharacterBody3D
    music_player = root.get_node("AudioManager/DistrictMusic") as AudioStreamPlayer
    _expect(music_player.stream.resource_path == "res://assets/music/deserted_coded_city.mp3", "new run restores city soundtrack")
    progress = _game.get_node("RunGuide").get("progress") as RunProgress
    _expect(progress.stage == RunProgress.Stage.LOADOUT and progress.visited.is_empty(), "restart creates fresh objectives")
    _expect(int(_player.get("credits")) == 0 and int(_player.call("get_item_stack", "chain_arc")) == 0, "combat inventory resets")
    _expect(progress.toy_known and bool(_game.get_node("StoryDirector").call("has_fragment", "memory_02")), "permanent artifact survives restart")
    _player.set("_invulnerability_timer", 0.0)
    _player.call("take_damage", 100000.0)
    _expect(progress.stage == RunProgress.Stage.FAILED and _game.get_node("HUD/DeathPanel").visible, "death gives immutable failure summary")
    _expect(not bool(_player.get("control_enabled")), "death disables character controls")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("PoolManager").call("clear_all")
    _game.queue_free()
    for frame in range(12):
        await physics_frame
    print("RUN_LOOP_NATIVE: ", checks, " checks / ", failures, " failures")
    quit(0 if failures == 0 else 1)

func _expect(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("RUN_LOOP: " + message)
