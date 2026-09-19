extends Node3D

const CUES = preload("res://components/combat_telegraph.gd")
const BLAST = preload("res://components/combat/delayed_blast.gd")
enum Status { AVAILABLE, WARNING, DEFENDING, CLEAR_REMAINDER, REWARD, COMPLETE, ABORTED }
var district_id: StringName = &""
var spec: Dictionary = {}
var status: int = Status.AVAILABLE
var remaining: float = 0.0
var _wave: int = 0
var _outside: float = 0.0
var _spawned: int = 0
var _paid: bool = false
var _hazard_fired: bool = false
var _actor: Node3D = null
var _game: Node = null
var _board: Label3D = null
var _indicator: MeshInstance3D = null
var _indicator_mat: StandardMaterial3D = null
var _poll: float = 0.0

func _ready() -> void:
    add_to_group("interactables")
    add_to_group("district_terminals")
    _build_console()
    _update_board()

func _build_console() -> void:
    var shell: StandardMaterial3D=StandardMaterial3D.new()
    shell.albedo_color=Color(0.10,0.12,0.14)
    shell.roughness=0.5
    var geometry: BoxMesh=BoxMesh.new()
    geometry.size=Vector3(0.85,1.15,0.55)
    var body: MeshInstance3D=MeshInstance3D.new()
    body.mesh=geometry
    body.material_override=shell
    body.position.y=0.575
    add_child(body)
    _indicator_mat=StandardMaterial3D.new()
    _indicator_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    _indicator_mat.albedo_color=Color(0.92,0.71,0.36)
    var screen: BoxMesh=BoxMesh.new()
    screen.size=Vector3(0.65,0.10,0.56)
    _indicator=MeshInstance3D.new()
    _indicator.mesh=screen
    _indicator.material_override=_indicator_mat
    _indicator.position.y=1.23
    add_child(_indicator)
    _board=Label3D.new()
    _board.font_size=28
    _board.pixel_size=0.008
    _board.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    _board.position.y=2.1
    _board.modulate=Color(0.95,0.80,0.50)
    _board.outline_size=6
    add_child(_board)

func get_interaction_text(_player: Node) -> String:
    if status == Status.AVAILABLE:
        return "[E / USE] OPTIONAL / %s / DEFEND THEN +%dc" % [spec["event"],int(spec["reward"])]
    if status == Status.REWARD:
        return "[E / USE] CLAIM SYNCHRONIZATION REWARD / +%dc" % int(spec["reward"])
    return ""

func interact(actor: Node) -> void:
    if actor == null or not actor is Node3D:
        return
    _game=get_tree().current_scene
    _actor=actor as Node3D
    if _game == null or not _game.has_method("queue_district_wave"):
        return
    if _actor.global_position.distance_to(global_position)>3.6 or float(_actor.get("health"))<=0.0:
        return
    if bool(_game.get("event_active")) or bool(_game.get("run_complete")) or bool(_game.get("_sector_secured")):
        return
    if status == Status.REWARD:
        _claim_reward()
        return
    if status != Status.AVAILABLE or not get_tree().get_nodes_in_group("active_district_event").is_empty():
        return
    var nav: StreetNavigation=get_tree().get_first_node_in_group("street_navigation") as StreetNavigation
    if nav == null or not nav.built:
        _actor.call("announce","NAVIGATION INITIALIZING / PLEASE WAIT")
        return
    status=Status.WARNING
    remaining=4.0
    _outside=0.0
    _wave=0
    _spawned=0
    add_to_group("active_district_event")
    _actor.call("announce",String(spec["event"])+" // DEFENSE IN 4 SECONDS")
    _update_board()

func is_running() -> bool:
    return status in [Status.WARNING,Status.DEFENDING,Status.CLEAR_REMAINDER]

func _physics_process(delta: float) -> void:
    if not is_running(): return
    if not is_instance_valid(_actor) or float(_actor.get("health"))<=0.0:
        abort_event()
        return
    if bool(_game.get("run_complete")) or bool(_game.get("event_active")) or bool(_game.get("_sector_secured")):
        abort_event()
        return
    var director: Node=_game.get_node_or_null("EncounterDirector")
    var local: bool=director != null and director.call("get_current_district_id")==district_id
    local=local and _actor.global_position.distance_to(global_position)<float(spec["radius"])
    _outside=0.0 if local else _outside+delta
    if _outside > 8.0:
        abort_event()
        return
    _poll-=delta
    if _poll<=0.0:
        _poll=0.20
        _update_board()
    if not local: return
    remaining=maxf(0.0,remaining-delta)
    if status==Status.WARNING and remaining<=0.0:
        status=Status.DEFENDING
        remaining=20.0
        _queue_wave()
    elif status==Status.DEFENDING:
        if remaining<=10.0 and _wave==1:
            _queue_wave()
        if remaining<=8.0 and not _hazard_fired and district_id==&"utility_spine":
            _hazard_fired=true
            _pressure_warning()
        if remaining<=0.0:
            status=Status.CLEAR_REMAINDER
            remaining=45.0
    elif status==Status.CLEAR_REMAINDER:
        var waiting: int=int(_game.call("pending_district_spawns",district_id))
        if waiting==0 and _living_defenders()==0:
            if _spawned<3:
                abort_event()
            else:
                status=Status.REWARD
                remove_from_group("active_district_event")
                _actor.call("announce","LOCAL SYSTEM RESTORED // RETURN TO CONSOLE")
                _update_board()
        elif remaining<=0.0:
            abort_event()

func _queue_wave() -> void:
    var waves: Array=spec.get("waves",[])
    if _wave>=waves.size(): return
    var types: Array[int]=[]
    for value in waves[_wave]: types.append(int(value))
    _game.call("queue_district_wave",self,district_id,types)
    _wave+=1

func register_spawn(enemy: Node3D) -> void:
    if not is_running(): return
    _spawned+=1
    enemy.set_meta("district_event",district_id)

func _living_defenders() -> int:
    var count: int=0
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if enemy.get_meta("district_event",&"")==district_id and float(enemy.get("health"))>0.0:
            count+=1
    return count

func _claim_reward() -> void:
    if _paid or status!=Status.REWARD: return
    _paid=true
    status=Status.COMPLETE
    _actor.call("add_credits",int(spec["reward"]))
    _actor.call("add_xp",25)
    _actor.call("announce",spec["message"])
    remove_from_group("interactables")
    _update_board()

func abort_event() -> void:
    if not is_running(): return
    status=Status.ABORTED
    remove_from_group("active_district_event")
    remove_from_group("interactables")
    _update_board()
    # No reward on death/leaving/starting the boss. Already-spawned enemies remain
    # ordinary combat threats; they are not silently despawned while attacking.
    for hazard in get_tree().get_nodes_in_group("hostile_hazards"):
        if hazard.get_meta("district_event",&"")==district_id and hazard.has_method("cancel"):
            hazard.call("cancel")

func _pressure_warning() -> void:
    # Two side bays only; centre corridor and both exits remain safe.
    for feet in [Vector3(-67,-5.98,-28),Vector3(-43,-5.98,-9)]:
        var hazard: Node3D=BLAST.new() as Node3D
        hazard.set("remaining",2.1)
        hazard.set("radius",3.0)
        hazard.set("damage",12.0)
        hazard.set("label_text","PRESSURE VENT // CLEAR THE RING")
        hazard.set_meta("district_event",district_id)
        hazard.call("arm",_game,feet)

func _update_board() -> void:
    if _board==null: return
    var title: String=String(spec.get("event","LOCAL SYSTEM"))
    match status:
        Status.AVAILABLE: _board.text=title+"\nOPTIONAL / E"
        Status.WARNING: _board.text="DEFENSE IN %d" % int(ceil(remaining))
        Status.DEFENDING: _board.text="SYNCHRONIZING %d%%" % int(100.0*(1.0-remaining/20.0))
        Status.CLEAR_REMAINDER: _board.text="CLEAR LOCAL DEFENDERS / %d" % _living_defenders()
        Status.REWARD: _board.text="SYSTEM RESTORED / CLAIM REWARD"
        Status.COMPLETE: _board.text="SYNCHRONIZED // THANK YOU"
        Status.ABORTED: _board.text="CONNECTION LOST // NO REWARD"
    _indicator_mat.albedo_color=Color(0.48,0.83,0.67) if status>=Status.REWARD and status<Status.ABORTED else Color(0.92,0.71,0.36)
