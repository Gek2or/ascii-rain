extends Node
## Smooth mouse-wheel zoom for the player's existing third-person spring arm.

const MIN_DISTANCE: float = 2.8
const MAX_DISTANCE: float = 9.0
const STEP_DISTANCE: float = 0.8
const ZOOM_SPEED: float = 10.0

@onready var _player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var _spring_arm: SpringArm3D = _player.get_node("CameraPivot/SpringArm3D") as SpringArm3D

var _target_distance: float = 5.7

func _ready() -> void:
    process_priority = -10
    _target_distance = clampf(_spring_arm.spring_length, MIN_DISTANCE, MAX_DISTANCE)
    _spring_arm.spring_length = _target_distance

func _unhandled_input(event: InputEvent) -> void:
    if not bool(_player.get("control_enabled")) or not (event is InputEventMouseButton):
        return
    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if not mouse_event.pressed:
        return
    if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
        _target_distance = maxf(MIN_DISTANCE, _target_distance - STEP_DISTANCE)
    elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        _target_distance = minf(MAX_DISTANCE, _target_distance + STEP_DISTANCE)

func _process(delta: float) -> void:
    _spring_arm.spring_length = move_toward(_spring_arm.spring_length, _target_distance, ZOOM_SPEED * delta)
