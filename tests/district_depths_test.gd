extends SceneTree
const SURFACE=preload("res://world/navigation/layered_surface_query.gd")
const SIGHT=preload("res://components/combat/combat_sight.gd")
const RULES=preload("res://data/district_rules.gd")
var checks: int=0
var failures: Array[String]=[]
var game: Node3D
var player: CharacterBody3D
var nav: StreetNavigation
var city: Node3D
var director: Node
func _initialize() -> void: call_deferred("_run")
func expect(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures.append(label)
        print("DEPTHS_FAIL: ",label)
func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for i in range(6): await physics_frame
    game=current_scene
    player=game.get_node("Player")
    director=game.get_node("EncounterDirector")
    city=get_first_node_in_group("living_city")
    nav=game.get_node("StreetNavigation")
    director.set_process(false)
    player.set("_invulnerability_timer",99999.0)
    player.set_physics_process(false)
    for i in range(700):
        if nav.built: break
        await physics_frame
    expect(nav.built,"layered graph built")
    print("DEPTHS_GRAPH: ",nav.graph.get_point_count())
    for name in ["market_ruins","transit_spine","archive_stacks","memory_gardens","utility_depths","rooftop_relay"]:
        expect(city.has_node(name),"district in scene "+name)
    for pair in [[Vector3(-60,-5.92,-20),Vector3(-60,0.08,-20)],[Vector3(-29,0.08,-66),Vector3(-29,10.08,-66)]]:
        var floor_hits: Array[Dictionary]=SURFACE.floors(game.get_world_3d(),pair[0])
        print("DEPTHS_FLOORS: ",pair," -> ",floor_hits)
        expect(floor_hits.size()>=2,"stacked surfaces exist")
        expect(not SIGHT.clear(game.get_world_3d(),pair[0]+Vector3.UP,pair[1]+Vector3.UP),"ceiling blocks bullets")
        expect(not nav.can_travel(pair[0],pair[1]),"cannot walk through ceiling")
        await physics_frame
        var route: Dictionary=nav.request_route(pair[0],pair[1])
        print("DEPTHS_OVERLAP_ROUTE: ",route.get("status")," points=",route.get("path",[]).size())
        expect(route.get("status")=="ok","stacked floors connected by a real detour")
    var routes: Array=[
        [Vector3(-66,0.08,12),Vector3(-66,-5.92,-16)],
        [Vector3(-42,-5.92,-22),Vector3(-42,0.08,-45)],
        [Vector3(-66,-5.92,-16),Vector3(-42,-5.92,-22)],
        [Vector3(-29,0.08,-22),Vector3(-29,10.08,-61)],
        [Vector3(25.5,0.08,-22),Vector3(29,10.08,-61)],
        [Vector3(-29,10.08,-61),Vector3(29,10.08,-61)]]
    for pair in routes:
        await physics_frame
        var route: Dictionary=nav.request_route(pair[0],pair[1])
        print("DEPTHS_ROUTE: ",pair," ",route.get("status")," n=",route.get("path",[]).size())
        expect(route.get("status")=="ok","connected authored route "+str(pair))
    for point in [Vector3(-66,0.08,0),Vector3(-42,0.08,-33)]:
        var support: Dictionary=nav.support_below(point)
        print("DEPTHS_HOLE: ",point," -> ",support)
        expect(not support.is_empty() and (support.get("point",Vector3.ZERO) as Vector3).y < -1.0,"street hole contains visible ramp, not invisible cap")
    # Parent discovery and encounter credit do not reset when moving levels.
    for spec in [[Vector3(-60,0.08,-20),Vector3(-60,-5.92,-20),&"utility_lower"],[Vector3(-29,0.08,-66),Vector3(-29,10.08,-66),&"relay_roofs"]]:
        player.global_position=spec[0]
        director.set("_floor_poll",0.0)
        for i in range(3): await physics_frame
        for i in range(3): director.call("_update_current_district")
        var count: int=director.call("get_visited_count")
        var key: int=director.get("_current_district")
        director.get("_budgets")[key]=3.75
        var intro: float=director.get("_first_wave_timer")
        player.global_position=spec[1]
        director.set("_floor_poll",0.0)
        for i in range(3): await physics_frame
        for i in range(3): director.call("_update_current_district")
        expect(director.call("get_encounter_zone")==spec[2],"correct lower/roof zone")
        expect(director.call("get_visited_count")==count,"one discovery for parent")
        expect(director.get("_budgets")[key]==3.75,"same local budget")
        expect(director.get("_first_wave_timer")==intro,"no repeated intro")
        expect(not city.call("exit_hint",player.global_position).is_empty(),"exit/ascend hint")
        for i in range(5):
            await physics_frame
            game.call("_spawn_enemy_near",player.global_position,1.0)
        var mobs: Array[Node]=get_nodes_in_group("enemies")
        expect(not mobs.is_empty(),"floor has valid spawns")
        var same_floor: bool=true
        for mob in mobs:
            same_floor=same_floor and absf(mob.global_position.y-player.global_position.y)<0.7
            mob.queue_free()
        expect(same_floor,"no street fallback for basement/roof")
        await physics_frame
    # Actual controller traversals: only initial placement, no intermediate teleport.
    player.set_physics_process(true)
    for spec in [[Vector3(-66,0.10,12),0.0,Vector3(-66,-5.9,-14)],[Vector3(-42,-5.90,-22),0.0,Vector3(-42,0.1,-45)],[Vector3(-29,0.1,-22),0.0,Vector3(-29,10.1,-61)],[Vector3(25.5,10.1,-61),PI,Vector3(25.5,0.1,-22)]]:
        player.global_position=spec[0]
        player.rotation.y=spec[1]
        player.velocity=Vector3.ZERO
        Input.action_press("move_forward")
        for i in range(750):
            await physics_frame
            if player.global_position.distance_to(spec[2])<1.2: break
        Input.action_release("move_forward")
        for i in range(10): await physics_frame
        print("DEPTHS_PLAYER: ",player.global_position," target=",spec[2])
        expect(player.global_position.distance_to(spec[2])<3.0,"controller reaches target landing")
    player.set_physics_process(false)
    for spec in [[Vector3(-60,0.08,-20),Vector3(-60,-5.92,-20)],[Vector3(-29,0.08,-66),Vector3(-29,10.08,-66)]]:
        player.global_position=spec[1]
        var enemy: CharacterBody3D=load("res://scenes/Enemy.tscn").instantiate()
        game.add_child(enemy)
        enemy.global_position=spec[0]
        enemy.call("setup",1,0,1.0)
        for i in range(3000):
            await physics_frame
            if enemy.global_position.distance_to(player.global_position)<3: break
        print("DEPTHS_CHASER: ",enemy.global_position," target=",player.global_position)
        expect(absf(enemy.global_position.y-player.global_position.y)<0.5,"real chaser reaches floor")
        expect(enemy.global_position.distance_to(player.global_position)<3.2,"real chaser follows full route")
        enemy.queue_free()
        await physics_frame
    expect(get_nodes_in_group("district_terminals").size()==6,"six optional event consoles")
    var caches: int=0
    for entry in get_nodes_in_group("interactables"):
        if entry.get_script()==load("res://scripts/chest.gd"):
            caches+=1
            expect(not nav.support_below(entry.global_position).is_empty(),"cache supported "+str(entry.global_position))
    expect(caches==14,"fourteen original caches preserved")
    # Distribution identities and early restrictions, not claims of balance quality.
    var random: RandomNumberGenerator=RandomNumberGenerator.new()
    random.seed=1337
    for id in RULES.RULES:
        var safe: bool=true
        for i in range(50): safe=safe and RULES.select_enemy(id,&"ground",0.0,random)<2
        expect(safe,"early enemy types gentle "+str(id))
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    game.queue_free()
    for i in range(12): await physics_frame
    print("DISTRICT_DEPTHS_NATIVE: ",checks," checks / ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
