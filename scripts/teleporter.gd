extends Node3D

signal activated
signal charge_changed(value: float)
signal charge_complete
signal ready_to_exit
signal exited

@export var charge_duration = 42.0
@export var charge_radius = 11.5

var route_locked: bool = false
var route_lock_message: String = ""
var active = false
var charge = 0.0
var boss_alive = false
var exit_ready: bool = false
var _charge_complete_emitted = false
var _player: Node3D

@onready var ring_a: Node3D = $RingA
@onready var ring_b: Node3D = $RingB
@onready var beacon: OmniLight3D = $BeaconLight

func _ready() -> void:
    add_to_group("interactables")
    _player = get_tree().get_first_node_in_group("player") as Node3D

func _process(delta: float) -> void:
    ring_a.rotate_y(delta * (1.6 if active else 0.35))
    ring_b.rotate_y(-delta * (1.15 if active else 0.22))
    if not active or exit_ready:
        return
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Node3D
        if _player == null:
            return

    var flat_delta = _player.global_position - global_position
    flat_delta.y = 0.0
    if flat_delta.length() <= charge_radius:
        charge = minf(100.0, charge + (100.0 / charge_duration) * delta)
        charge_changed.emit(charge)
        beacon.light_energy = 3.2 + sin(Time.get_ticks_msec() * 0.008) * 0.8

    if charge >= 100.0 and not _charge_complete_emitted:
        _charge_complete_emitted = true
        charge_complete.emit()
        _check_ready()

func get_interaction_text(_player_node: Node) -> String:
    if exit_ready:
        return "[E / USE] LEAVE DISTRICT (optional artifacts may be left behind)"
    if not active and route_locked:
        return route_lock_message
    if not active:
        return "[E / USE] ACTIVATE TELEPORTER"
    if charge < 100.0:
        return "TELEPORTER  %d%%   — STAY IN FIELD" % int(charge)
    return "CHARGED   — ELIMINATE BOSS"

func interact(_player_node: Node) -> void:
    if exit_ready:
        exited.emit()
        return
    if active or route_locked:
        return
    active = true
    boss_alive = true
    activated.emit()

func set_boss_dead() -> void:
    boss_alive = false
    _check_ready()

func _check_ready() -> void:
    if charge >= 100.0 and not boss_alive and not exit_ready:
        exit_ready = true
        ready_to_exit.emit()

func set_route_lock(locked: bool, message: String) -> void:
    route_locked = locked
    route_lock_message = message

func is_player_in_field() -> bool:
    if not is_instance_valid(_player):
        return false
    var offset: Vector3 = _player.global_position - global_position
    offset.y = 0.0
    return offset.length() <= charge_radius
