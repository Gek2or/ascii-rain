extends SceneTree

const SIGHT = preload("res://components/combat/combat_sight.gd")
const SURFACE = preload("res://world/navigation/layered_surface_query.gd")
var checks: int = 0
var failures: Array[String] = []
var game: Node3D = null
var player: CharacterBody3D = null
var nav: StreetNavigation = null
var director: Node = null
var city: Node3D = null

func _initialize() -> void:
    call_deferred("_run")
func _expect(value: bool,label: String) -> void:
    checks += 1
    if not value:
        failures.append(label)
        print("LIVING_FAIL: ",label)

func _run() -> void:
    change_scene_to_file("res://scenes/Main.tscn")
    for i in range(6):
        await physics_frame
    game = current_scene as Node3D
    player = game.get_node("Player") as CharacterBody3D
    director = game.get_node("EncounterDirector")
    director.set_process(false)
    player.set("_invulnerability_timer",5000.0)
    nav = game.get_node("StreetNavigation") as StreetNavigation
    city = get_first_node_in_group("living_city") as Node3D
    for i in range(500):
        if nav.built:
            break
        await physics_frame
    _expect(nav.built,"multi-layer graph finishes in bounded ticks")
    _expect(city != null,"living modules are in the existing Main, not alternate demo")
    _expect(city.get_node("market_ruins").get_child_count()>50,"market has architectural modules")
    _expect(city.get_node("transit_spine").get_child_count()>50,"transit has different structural modules")
    _expect(get_nodes_in_group("walkable_surfaces").size()>=10,"authored surfaces carry stable identity")
    for at in [Vector3(45,0.08,30),Vector3(0,0.08,64)]:
        var floors: Array[Dictionary] = SURFACE.floors(game.get_world_3d(),at)
        var count: int = 0
        for floor_hit in floors:
            var height: float = float((floor_hit["point"] as Vector3).y)
            if absf(height) < 0.1 or absf(height-5.5)<0.1:
                count += 1
        _expect(count==2,"two supported floors at same XZ "+str(at))
        var low: int = nav.nearest_id(at)
        var high: int = nav.nearest_id(at+Vector3.UP*5.5)
        _expect(low>=0 and high>=0 and low!=high,"floor ids distinct "+str(at))
        if low>=0 and high>=0:
            _expect(absf(nav.graph.get_point_position(low).y)<0.2,"street not snapped up")
            _expect(absf(nav.graph.get_point_position(high).y-5.5)<0.2,"gallery not snapped down")
        _expect(not nav.can_travel(at,at+Vector3.UP*5.5),"no vertical shortcut through deck")
        _expect(not SIGHT.clear(game.get_world_3d(),at+Vector3.UP,at+Vector3.UP*6.5),"solid deck blocks line of fire")
        await physics_frame
        var result: Dictionary = nav.request_route(at,at+Vector3.UP*5.5)
        print("LAYER_PATH ",at," -> ",result.get("status")," nodes=",result.get("path",[]).size())
        _expect(result["status"]=="ok","floor-to-floor route exists")
        var path: PackedVector3Array = result.get("path",PackedVector3Array())
        var ramp_nodes: int = 0
        var valid: bool = not path.is_empty()
        for index in range(path.size()):
            if path[index].y > 0.8 and path[index].y < 4.9:
                ramp_nodes += 1
            if index>0:
                valid = valid and nav.can_travel(path[index-1],path[index])
        _expect(ramp_nodes>0,"route actually uses intermediate ramp heights")
        _expect(valid,"all multi-level edges physically supported")
        var jumping: Dictionary = nav.support_below(at+Vector3.UP*2.0)
        _expect(not jumping.is_empty() and (jumping["point"] as Vector3).y<0.2,"jump under bridge selects floor below feet")
    # These two ground points must not activate the encounter on top of them.
    var below_zone: Dictionary = city.call("zone_at",Vector3(0,1,64))
    var upper_zone: Dictionary = city.call("zone_at",Vector3(0,5.6,64))
    _expect(below_zone["id"]==&"transit_ground","underpass has lower encounter id")
    _expect(upper_zone["id"]==&"transit_platform","bridge has upper encounter id")
    _expect(below_zone["district"]==upper_zone["district"],"floors share one progression district")
    # Exercise district/zone routing, not only a bounds function.
    player.set_physics_process(false)
    player.global_position=Vector3(0,0.08,64)
    for i in range(3):
        director.call("_update_current_district")
    var budget_key: int = int(director.get("_current_district"))
    var budget: Dictionary = director.get("_budgets")
    budget[budget_key]=3.75
    var intro_time: float = float(director.get("_first_wave_timer"))
    var visit_count: int = int(director.call("get_visited_count"))
    player.global_position=Vector3(0,5.58,64)
    for i in range(3):
        director.call("_update_current_district")
    _expect(director.call("get_encounter_zone")==&"transit_platform","confirmed upper zone after entry debounce")
    _expect(int(director.call("get_visited_count"))==visit_count,"upper floor does not grant second district")
    _expect(float(director.get("_budgets")[budget_key])==3.75,"floor transition does not reset threat budget")
    _expect(float(director.get("_first_wave_timer"))==intro_time,"floor transition does not repeat introductory wave")
    # Authored upper anchors retain height; no fallback creates enemies underneath.
    var spawn_positions: Array[Vector3] = city.call("anchors_for",&"market_gallery")
    var found: int = 0
    for point in spawn_positions:
        var anchor: Dictionary = nav.spawn_anchor(point,Vector3(44,5.5,56),12.0)
        if not anchor.is_empty():
            found+=1
            _expect((anchor["position"] as Vector3).y>5.4,"upper spawn retains gallery height")
    _expect(found>=2,"several authored upper anchors reachable")
    for pair in [[Vector3(40,5.58,56),Vector3(40,5.58,30)], [Vector3(50,0.08,36),Vector3(50,5.58,55)], [Vector3(-12,0.08,39),Vector3(-12,5.58,60)]]:
        await physics_frame
        var travel: Dictionary=nav.request_route(pair[0],pair[1])
        _expect(travel["status"]=="ok","connected alternate ascent/gallery path "+str(pair))
    # The north gate is a physical six-metre entrance, not a gap in decoration.
    _expect(nav.can_travel(Vector3(44,0.02,20),Vector3(44,0.02,31)),"market entrance is clear below gallery")
    # Exercise the actual game spawning integration on an upper floor.
    player.global_position=Vector3(44,5.58,56)
    for i in range(3):
        director.call("_update_current_district")
    await physics_frame
    game.call("_spawn_enemy_near",player.global_position,1.0)
    var upper_mobs: Array[Node]=get_nodes_in_group("enemies")
    _expect(not upper_mobs.is_empty(),"actual game spawns on authored upper anchors")
    for mob in upper_mobs:
        _expect((mob as Node3D).global_position.y>5.4,"game spawn not under target floor")
        _expect((mob as Node3D).global_position.distance_to(player.global_position)>=12.0,"upper spawn keeps safe materialization distance")
        mob.queue_free()
    await physics_frame
    game.call("_on_director_spawn_requested",player.global_position,2,1.0)
    player.global_position=Vector3(44,0.08,30)
    for i in range(3):
        director.call("_update_current_district")
    await physics_frame
    await physics_frame
    _expect(get_nodes_in_group("enemies").is_empty(),"stale upper-floor queue cancelled after confirmed descent")
    # Preserve upper chests without changing total reward count.
    var upper_chests: int = 0
    for interactable in get_nodes_in_group("interactables"):
        var chest: Node3D = interactable as Node3D
        if chest != null and chest.get_script()==load("res://scripts/chest.gd") and chest.global_position.y>5.5:
            upper_chests+=1
            var floor_hit: Dictionary = nav.support_below(chest.global_position)
            _expect(not floor_hit.is_empty() and (floor_hit["point"] as Vector3).y>5.4,"relocated cache has upper support")
    _expect(upper_chests==6,"six existing caches above 5.5m, total reward count unchanged")
    # Real player traversal: existing controller/physics, no teleport between ends.
    player.set_physics_process(true)
    player.global_position=Vector3(32,0.1,50)
    player.rotation.y=0
    player.velocity=Vector3.ZERO
    Input.action_press("move_forward")
    for i in range(210):
        await physics_frame
        if player.global_position.z<31.8:
            break
    Input.action_release("move_forward")
    for i in range(12):
        await physics_frame
    print("PLAYER_ASCENT ",player.global_position)
    _expect(player.global_position.y>5.3,"existing player climbs market ramp onto gallery")
    player.set_physics_process(false)
    # Real melee agents on two authored ascents, not forced position updates.
    for spec in [[0,Vector3(32,0.08,50),Vector3(32,5.58,30)],[1,Vector3(12,0.08,39),Vector3(12,5.58,60)],[0,Vector3(50,0.08,36),Vector3(50,5.58,57)],[1,Vector3(-12,0.08,39),Vector3(-12,5.58,60)],[0,Vector3(45,0.08,30),Vector3(45,5.58,30)],[1,Vector3(0,0.08,64),Vector3(0,5.58,64)]]:
        player.global_position=spec[2]
        var enemy: CharacterBody3D=load("res://scenes/Enemy.tscn").instantiate() as CharacterBody3D
        game.add_child(enemy)
        enemy.global_position=spec[1]
        enemy.call("setup",spec[0],0,1.0)
        for i in range(1200):
            await physics_frame
            if enemy.global_position.y>5.2 and enemy.global_position.distance_to(player.global_position)<3.1:
                break
        print("LAYER_CHASER ",spec[0]," final=",enemy.global_position)
        _expect(enemy.global_position.y>5.2,"real enemy type "+str(spec[0])+" reaches intended upper floor")
        _expect(enemy.global_position.distance_to(player.global_position)<3.2,"real enemy arrives without attacking from beneath")
        enemy.queue_free()
        await physics_frame
    # Ambient pause and setting are independent of navigable geometry.
    var ambient: Node=city.get_node("AmbientSystems")
    player.global_position=Vector3(48,0.1,42)
    for i in range(20):
        await process_frame
    var position_before: Vector3=(ambient.get("drone") as Node3D).position
    for i in range(30):
        await physics_frame
    _expect((ambient.get("drone") as Node3D).position.distance_to(position_before)>0.01,"maintenance drone actually follows route")
    var time_before: float=float(ambient.get("_clock"))
    paused=true
    await create_timer(0.2,true,false,true).timeout
    _expect(is_equal_approx(time_before,float(ambient.get("_clock"))),"ambient clock pauses with gameplay")
    paused=false
    var solid_before: int=get_nodes_in_group("walkable_surfaces").size()
    SettingsManager.update_ambient_motion(0.0)
    for i in range(3):
        await process_frame
    _expect(not ambient.get("drone").visible and not ambient.get("transit_pod").visible,"motion-off removes only ambient movers")
    _expect(get_nodes_in_group("walkable_surfaces").size()==solid_before,"disabling atmosphere retains all floors/collisions")
    _expect(get_nodes_in_group("enemies").is_empty(),"ambient systems never spawn combat actors")
    SettingsManager.update_ambient_motion(1.0)
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream=null
    await create_timer(0.35,true,false,true).timeout
    game.queue_free()
    for i in range(12):
        await physics_frame
    print("LIVING_CITY_NATIVE: ",checks," checks / ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
