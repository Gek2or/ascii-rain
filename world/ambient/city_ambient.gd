extends "res://world/districts/city_modules.gd"

# Decorative infrastructure: no combat groups, hits, pickups or simulation RNG.
# Uses scene delta, so menu/relic pause and hit-stop apply consistently.
var drone: Node3D = null
var transit_pod: Node3D = null
var board: Label3D = null
var _clock: float = 0.0
var _state_timer: float = 0.0
var _actor: Node3D = null
var _drone_base: Vector3 = Vector3(64,3.8,46)
var _near_market: bool = false
var _near_transit: bool = false
var _alert: bool = false
var _recovery: float = 0.0
var active_decorations: int = 0

func _ready() -> void:
    init_palette()
    _actor = get_tree().get_first_node_in_group("player") as Node3D
    drone = _drone()
    transit_pod = _pod()
    board = sign_label("NOW SERVING // 000",Vector3(64,2.5,44),29,-PI*0.5)
    box("ServiceBoard",Vector3(64.1,2.5,44),Vector3(0.12,1.0,4.6),1,false)
    _clock = 8.0
    SettingsManager.changed.connect(_apply_settings)
    _apply_settings()

func _process(delta: float) -> void:
    if not is_instance_valid(_actor):
        _actor = get_tree().get_first_node_in_group("player") as Node3D
        return
    _state_timer -= delta
    if _state_timer <= 0.0:
        _state_timer = 0.20
        _near_market = _actor.global_position.distance_to(_drone_base) < 58.0
        _near_transit = _actor.global_position.distance_to(Vector3(0,10,65)) < 85.0
        var was_alert: bool = _alert
        _alert = false
        for enemy in get_tree().get_nodes_in_group("enemies"):
            var body: Node3D = enemy as Node3D
            if body != null and body.global_position.distance_squared_to(Vector3(45,0,43)) < 28.0*28.0:
                _alert = true
                break
        if was_alert and not _alert:
            _recovery = 6.0
        _apply_settings()
        if _alert:
            board.text = "SERVICE // PLEASE WAIT"
        elif _recovery > 0.0:
            board.text = "RESTORING CONNECTION"
        else:
            board.text = "NOW SERVING // %03d" % (int(_clock / 7.0) % 100)
    _recovery = maxf(0.0,_recovery-delta)
    _clock += delta * SettingsManager.ambient_motion
    if drone.visible:
        var phase: float = fmod(_clock,18.0)
        var t: float = clampf((phase-3.0)/10.0,0.0,1.0)
        var ease: float = t*t*(3.0-2.0*t)
        drone.position = _drone_base+Vector3(-3.0*sin(ease*TAU),sin(_clock*0.8)*0.1,-4.0*(1.0-cos(ease*TAU)))
        drone.rotation.y = -ease*TAU
    if transit_pod.visible:
        # Track ends are outside the playable footprint; no visible teleport in view.
        transit_pod.position = Vector3(fmod(_clock*5.0+80.0,230.0)-115.0,14.0,77.5)
    active_decorations = int(drone.visible)+int(transit_pod.visible)

func _apply_settings() -> void:
    if drone == null:
        return
    var enabled: bool = SettingsManager.ambient_motion > 0.0
    drone.visible = enabled and _near_market
    transit_pod.visible = enabled and _near_transit and SettingsManager.quality_preset > 0
    # Low quality removes only the distant decorative pod, never track or floors.

func _drone() -> Node3D:
    var host: Node3D = Node3D.new()
    host.name = "MaintenanceDrone"
    add_child(host)
    var pieces: Array = [
        [Vector3.ZERO,Vector3(0.65,0.34,0.55),0],
        [Vector3(0,0,-0.3),Vector3(0.24,0.12,0.06),4],
        [Vector3(-0.6,0,0),Vector3(0.60,0.12,0.50),1],
        [Vector3(0.6,0,0),Vector3(0.60,0.12,0.50),1],
        [Vector3(0,-0.30,0),Vector3(0.12,0.35,0.12),2]]
    for piece in pieces:
        var node: Node3D = box("DronePart",piece[0],piece[1],piece[2],false)
        remove_child(node)
        host.add_child(node)
    host.position = _drone_base
    return host

func _pod() -> Node3D:
    var host: Node3D = Node3D.new()
    host.name = "AmbientTransit"
    add_child(host)
    for i in range(3):
        var body: Node3D = box("TransitCar",Vector3(i*7.8,0,0),Vector3(7.0,1.9,2.6),1,false)
        remove_child(body)
        host.add_child(body)
        for x in [-2.0,0.0,2.0]:
            var window: Node3D = box("TransitWindow",Vector3(i*7.8+x,0.2,-1.31),Vector3(1.3,0.5,0.05),3,false)
            remove_child(window)
            host.add_child(window)
    return host
