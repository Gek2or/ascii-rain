extends SceneTree
var checks: int=0
var failures: Array[String]=[]
var game: Node3D
var player: CharacterBody3D
var director: Node
var nav: StreetNavigation
func _initialize() -> void: call_deferred("_run")
func expect(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures.append(label)
        print("DISTRICT_EVENT_FAIL: ",label)
func relocate(at: Vector3) -> void:
    player.global_position=at
    player.velocity=Vector3.ZERO
    director.set("_floor_poll",0.0)
    for i in range(4): await physics_frame
    for i in range(3): director.call("_update_current_district")
func clear_mobs() -> void:
    # Fixtures remove actors explicitly to test state wiring, not human balance.
    for enemy in get_nodes_in_group("enemies"): enemy.queue_free()
    for i in range(2): await physics_frame
func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for i in range(6): await physics_frame
    game=current_scene
    player=game.get_node("Player")
    director=game.get_node("EncounterDirector")
    nav=game.get_node("StreetNavigation")
    director.set_process(false)
    player.set_physics_process(false)
    player.set("_invulnerability_timer",999999.0)
    for i in range(700):
        if nav.built: break
        await physics_frame
    expect(nav.built,"navigation built")
    var consoles: Array[Node]=get_nodes_in_group("district_terminals")
    expect(consoles.size()==6,"six consoles")
    for console in consoles:
        var point: Vector3=console.global_position
        var id: StringName=console.get("district_id")
        expect(not nav.support_below(point+Vector3(1.1,0,0)).is_empty(),"console approach supported "+str(id))
        await relocate(point+Vector3(1.1,0,0))
        var original_credits: int=player.get("credits")
        console.call("interact",player)
        expect(console.get("status")==1,"console starts warning "+str(id))
        console.call("interact",player)
        expect(console.get("status")==1,"repeat use does not reset")
        expect(player.get("credits")==original_credits,"no free reward on start")
        var before: float=console.get("remaining")
        paused=true
        await create_timer(0.05,true,false,true).timeout
        expect(console.get("remaining")==before,"pause freezes event timer")
        paused=false
        # Advance the real terminal state directly, then let native Main physics
        # process the actual spawn queue. No mock enemies or fake graph services.
        console.set_physics_process(false)
        console.call("_physics_process",4.1)
        for i in range(12): await physics_frame
        expect(console.get("status")==2,"defending state")
        expect(int(console.get("_spawned"))>=1,"first actual defender wave "+str(id))
        var time_before: float=director.get("_ambient_timer")
        director.call("_process",0.5)
        expect(director.get("_ambient_timer")==time_before,"ambient director suspended")
        await clear_mobs()
        console.call("_physics_process",10.1)
        for i in range(12): await physics_frame
        expect(int(console.get("_spawned"))>=3,"second actual wave "+str(id))
        console.call("_physics_process",3.0)
        if id==&"utility_spine":
            expect(get_nodes_in_group("hostile_hazards").size()>=2,"two side pressure telegraphs")
        await clear_mobs()
        console.call("_physics_process",10.0)
        console.call("_physics_process",0.2)
        expect(console.get("status")==4,"clear waves unlock reward "+str(id))
        expect(player.get("credits")==original_credits,"reward not granted until claim")
        console.call("interact",player)
        var reward: int=int(console.get("spec")["reward"])
        expect(player.get("credits")==original_credits+reward,"exact credit reward")
        console.call("interact",player)
        expect(player.get("credits")==original_credits+reward,"repeat claim cannot duplicate credits")
        expect(not console.is_in_group("interactables"),"complete console no longer blocks interaction")
        expect(get_nodes_in_group("active_district_event").is_empty(),"optional director resumes")
        for hazard in get_nodes_in_group("hostile_hazards"):
            if hazard.has_method("cancel"): hazard.call("cancel")
        await physics_frame
    # Reset just one fixture terminal to assert cancellation, not shipped run logic.
    var test: Node=consoles[0]
    test.set("status",0)
    test.add_to_group("interactables")
    await relocate(test.global_position+Vector3(1.1,0,0))
    test.call("interact",player)
    var credits: int=player.get("credits")
    game.set("event_active",true)
    test.call("_physics_process",0.1)
    expect(test.get("status")==6,"boss event aborts local defense")
    expect(player.get("credits")==credits,"abort gives no reward")
    expect(get_nodes_in_group("active_district_event").is_empty(),"abort releases director")
    game.set("event_active",false)
    test.set("status",0)
    test.add_to_group("interactables")
    test.call("interact",player)
    await relocate(Vector3(0,0.1,8))
    test.call("_physics_process",8.1)
    expect(test.get("status")==6,"leaving district aborts after grace")
    expect(player.get("credits")==credits,"leaving cannot farm credits")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    game.queue_free()
    for i in range(12): await physics_frame
    print("DISTRICT_EVENTS_NATIVE: ",checks," checks / ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
