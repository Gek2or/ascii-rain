extends SceneTree

const SURFACE = preload("res://world/navigation/layered_surface_query.gd")
const SIGHT = preload("res://components/combat/combat_sight.gd")
var checks: int = 0
var failures: Array[String] = []
var game: Node3D = null
var player: CharacterBody3D = null
var nav: StreetNavigation = null
var city: Node3D = null
var director: Node = null

func _initialize() -> void:
    call_deferred("_run")
func _expect(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        print("CIVIC_FAIL: ",label)

func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for i in range(6):
        await physics_frame
    game=current_scene as Node3D
    player=game.get_node("Player") as CharacterBody3D
    director=game.get_node("EncounterDirector")
    nav=game.get_node("StreetNavigation") as StreetNavigation
    city=get_first_node_in_group("living_city") as Node3D
    director.set_process(false)
    player.set("_invulnerability_timer",9999.0)
    player.set_physics_process(false)
    for i in range(500):
        if nav.built:
            break
        await physics_frame
    _expect(nav.built,"layered graph completed")
    print("CIVIC_GRAPH_POINTS: ",nav.graph.get_point_count())
    _expect(city.has_node("archive_stacks") and city.has_node("memory_gardens"),"both districts included in Main")
    _expect(city.has_node("market_ruins") and city.has_node("transit_spine"),"previous two districts preserved")
    for p in [Vector3(51,0.08,-30),Vector3(-35,0.08,59)]:
        var floors: Array[Dictionary]=SURFACE.floors(game.get_world_3d(),p)
        var heights: Array[float]=[]
        for floor_hit in floors:
            heights.append((floor_hit["point"] as Vector3).y)
        print("CIVIC_FLOORS: ",p," -> ",heights)
        _expect(heights.size()>=2,"street and gallery both exist "+str(p))
        _expect(nav.nearest_id(p)>=0,"street nav valid "+str(p))
        _expect(nav.nearest_id(p+Vector3.UP*5.5)>=0,"upper nav valid "+str(p))
        _expect(not nav.can_travel(p,p+Vector3.UP*5.5),"no vertical shortcut")
        _expect(not SIGHT.clear(game.get_world_3d(),p+Vector3.UP,p+Vector3.UP*6.5),"ceiling blocks bullets")
        await physics_frame
        var route: Dictionary=nav.request_route(p,p+Vector3.UP*5.5)
        _expect(route["status"]=="ok","find real floor-to-floor route "+str(p))
    var routes: Array=[
        [Vector3(40,0.08,6),Vector3(40,5.58,-15)],
        [Vector3(62,0.08,6),Vector3(62,5.58,-15)],
        [Vector3(40,5.58,-30),Vector3(62,5.58,-16)],
        [Vector3(-36,0.08,40),Vector3(-64,2.83,42)],
        [Vector3(-64,0.08,18),Vector3(-64,2.83,42)],
        [Vector3(-64,2.83,42),Vector3(-35,5.58,59)],
        [Vector3(-31,0.08,27),Vector3(-35,5.58,59)],
        [Vector3(-35,5.58,59),Vector3(-64,0.08,18)]]
    for pair in routes:
        await physics_frame
        var route: Dictionary=nav.request_route(pair[0],pair[1])
        print("CIVIC_ROUTE ",pair," ",route.get("status")," nodes=",route.get("path",[]).size())
        _expect(route["status"]=="ok","connected ascent/alternative descent "+str(pair))
    for spec in [[&"archive_row",Vector3(51,0.08,-30),Vector3(51,5.58,-30),&"archive_gallery"],[&"memory_gardens",Vector3(-43,0.08,25),Vector3(-64,2.83,42),&"gardens_terrace"],[&"memory_gardens",Vector3(-64,2.83,42),Vector3(-35,5.58,59),&"gardens_pavilion"]]:
        player.global_position=spec[1]
        for i in range(3): director.call("_update_current_district")
        var visited: int=int(director.call("get_visited_count"))
        var key: int=int(director.get("_current_district"))
        director.get("_budgets")[key]=3.75
        var timer: float=float(director.get("_first_wave_timer"))
        player.global_position=spec[2]
        for i in range(3): director.call("_update_current_district")
        _expect(director.call("get_encounter_zone")==spec[3],"correct floor zone "+str(spec[3]))
        _expect(int(director.call("get_visited_count"))==visited,"one visit per district")
        _expect(float(director.get("_budgets")[key])==3.75,"floor does not reset threat")
        _expect(float(director.get("_first_wave_timer"))==timer,"floor does not repeat intro wave")
        _expect(city.call("is_elevated_zone",spec[3]),"elevated spawn routing used")
        _expect(not city.call("exit_hint",player.global_position).is_empty(),"descent hint available")
    # A jump below the pavilion crosses the terrace band, but remains ground combat.
    player.global_position=Vector3(-35,3.0,59)
    director.set("_floor_poll",0.0)
    await physics_frame
    await physics_frame
    for i in range(3): director.call("_update_current_district")
    _expect(director.call("get_encounter_zone")==&"gardens_ground","airborne under pavilion retains ground encounter")
    player.global_position=Vector3(-64,5.7,42)
    director.set("_floor_poll",0.0)
    await physics_frame
    await physics_frame
    for i in range(3): director.call("_update_current_district")
    _expect(director.call("get_encounter_zone")==&"gardens_terrace","jump on low terrace cannot activate pavilion wave")
    # Real spawn integration must preserve the gallery/terrace/pavilion height.
    for spec in [[Vector3(40,5.58,-16),5.4],[Vector3(-67,2.83,39),2.7],[Vector3(-31,5.58,51),5.4]]:
        player.global_position=spec[0]
        for i in range(3): director.call("_update_current_district")
        for i in range(4):
            await physics_frame
            game.call("_spawn_enemy_near",player.global_position,1.0)
        var mobs: Array[Node]=get_nodes_in_group("enemies")
        _expect(not mobs.is_empty(),"actual spawn available "+str(spec[0]))
        var same_floor: bool=true
        var safe: bool=true
        for mob in mobs:
            var p: Vector3=(mob as Node3D).global_position
            same_floor=same_floor and absf(p.y-player.global_position.y)<0.65
            safe=safe and p.distance_to(player.global_position)>10.0
            mob.queue_free()
        _expect(same_floor,"no ground fallback from upper zone")
        _expect(safe,"spawn grace starts outside player")
        await physics_frame
    # Starting directly underneath forces the enemy to find a ramp, not fall back.
    for spec in [[0,Vector3(51,0.08,-30),Vector3(51,5.58,-30)],[1,Vector3(-35,0.08,59),Vector3(-35,5.58,59)],[0,Vector3(-64,0.08,18),Vector3(-64,2.83,42)]]:
        player.global_position=spec[2]
        var enemy: CharacterBody3D=load("res://scenes/Enemy.tscn").instantiate() as CharacterBody3D
        game.add_child(enemy)
        enemy.global_position=spec[1]
        enemy.call("setup",spec[0],0,1.0)
        for i in range(2700):
            await physics_frame
            if absf(enemy.global_position.y-player.global_position.y)<0.45 and enemy.global_position.distance_to(player.global_position)<3.0: break
        print("CIVIC_CHASER ",spec[0]," final=",enemy.global_position," target=",player.global_position)
        _expect(absf(enemy.global_position.y-player.global_position.y)<0.6,"real chaser reaches intended elevation")
        if enemy.global_position.distance_to(player.global_position)>=3.2:
            var follow: RefCounted=enemy.get("_navigation")
            print("CIVIC_FOLLOW_DEBUG: ",follow.get("_path")," cursor=",follow.get("_waypoint")," nearest=",nav.nearest_id(enemy.global_position)," velocity=",enemy.velocity)
        _expect(enemy.global_position.distance_to(player.global_position)<3.2,"real chaser reaches player")
        enemy.queue_free()
        await physics_frame
    # Actual player input: a ramp is not accepted on pathfinding alone.
    player.set_physics_process(true)
    for spec in [[Vector3(62,0.10,6),0.0,Vector3(62,5.58,-15),5.3],[Vector3(-64,0.10,18),PI,Vector3(-64,2.83,40),2.6],[Vector3(-31,0.10,27),PI,Vector3(-31,5.58,52),5.3]]:
        player.global_position=spec[0]
        player.rotation.y=spec[1]
        player.velocity=Vector3.ZERO
        Input.action_press("move_forward")
        for i in range(480):
            await physics_frame
            if player.global_position.distance_to(spec[2]) < 1.3: break
        Input.action_release("move_forward")
        for i in range(10): await physics_frame
        print("CIVIC_PLAYER_ASCENT ",player.global_position)
        _expect(player.global_position.y>spec[3],"player controller reaches authored landing")
        _expect(player.global_position.distance_to(spec[2])<3.0,"no jump or teleport required along ramp")
    player.set_physics_process(false)
    var chest_count: int=0
    var support_ok: bool=true
    for entry in get_nodes_in_group("interactables"):
        if entry.get_script()==load("res://scripts/chest.gd"):
            chest_count+=1
            var floor_hit: Dictionary=nav.support_below((entry as Node3D).global_position)
            support_ok=support_ok and not floor_hit.is_empty()
    _expect(chest_count==14,"same fourteen caches, not inflated reward count")
    _expect(support_ok,"all relocated caches on physical support")
    var ambience: Node=city.get_node("CivicAtmosphere")
    player.global_position=Vector3(51,0.08,-10)
    ambience.call("_update_proximity")
    for i in range(30): await physics_frame
    _expect(ambience.get("carrier").visible,"near archive courier active")
    var before: float=float(ambience.get("_clock"))
    paused=true
    await create_timer(0.2,true,false,true).timeout
    _expect(is_equal_approx(before,float(ambience.get("_clock"))),"new ambience pauses with game")
    paused=false
    var solids: int=get_nodes_in_group("walkable_surfaces").size()
    SettingsManager.update_ambient_motion(0.0)
    var rotation_before: Vector3=ambience.get("irrigation").rotation
    for i in range(5): await physics_frame
    _expect(not ambience.get("carrier").visible,"motion setting hides courier")
    _expect(ambience.get("irrigation").rotation==rotation_before,"motion off freezes irrigation")
    _expect(get_nodes_in_group("walkable_surfaces").size()==solids,"motion does not remove terrain")
    SettingsManager.update_ambient_volume(0.0)
    for voice in ambience.get("voices"):
        _expect(not voice.playing,"ambient volume zero stops positional voice")
        _expect(voice.max_distance>0.0,"positional sound finite range")
    SettingsManager.update_ambient_volume(0.55)
    SettingsManager.update_ambient_motion(1.0)
    _expect(get_nodes_in_group("enemies").is_empty(),"ambience never creates hostiles")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    game.queue_free()
    for i in range(12): await physics_frame
    print("CIVIC_CITY_NATIVE: ",checks," checks / ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
