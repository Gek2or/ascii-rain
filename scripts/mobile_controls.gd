extends CanvasLayer

const VIEW = preload("res://ui/touch_controls_view.gd")
const LAYOUT = preload("res://components/input/touch_layout.gd")
@export var force_show_on_desktop: bool = false

var _player: Node = null
var _view: Control = null
var _roles: Dictionary = {}
var _move_finger: int = -1
var _look_finger: int = -1
var _aim_toggled: bool = false
var _enabled: bool = false
var _mouse_bindings: Dictionary = {}

func _ready() -> void:
    layer = 115
    process_mode = Node.PROCESS_MODE_ALWAYS
    _player = get_parent().get_node_or_null("Player")
    _enabled = RuntimeProfile.is_mobile or force_show_on_desktop
    if not _enabled:
        return
    _bind_physical_mouse_only()
    _view = VIEW.new() as Control
    _view.name = "TouchRoot"
    add_child(_view)
    SettingsManager.changed.connect(_reset_controls)

func _bind_physical_mouse_only() -> void:
    # Keep mouse emulation for native menu buttons, but do not turn a stick touch
    # into an LMB shot. Use this engine's physical mouse ID (0 on older versions).
    var native_device: int = InputEventMouseButton.new().device
    for action in [&"shoot", &"aim"]:
        var originals: Array[InputEvent] = []
        for binding in InputMap.action_get_events(action):
            if binding is InputEventMouseButton:
                originals.append(binding)
                InputMap.action_erase_event(action, binding)
                var physical: InputEventMouseButton = binding.duplicate() as InputEventMouseButton
                physical.device = native_device
                InputMap.action_add_event(action, physical)
        _mouse_bindings[action] = originals

func _restore_mouse_bindings() -> void:
    for action in _mouse_bindings:
        for binding in InputMap.action_get_events(action):
            if binding is InputEventMouseButton:
                InputMap.action_erase_event(action, binding)
        for binding in _mouse_bindings[action]:
            InputMap.action_add_event(action, binding)
    _mouse_bindings.clear()

func _input(event: InputEvent) -> void:
    if not _enabled:
        return
    if not _can_control():
        _reset_controls()
        return
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed and not touch.canceled:
            _begin_touch(touch.index, touch.position)
        else:
            _end_touch(touch.index)
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        _drag_touch(drag.index, drag.position, drag.relative)

func _begin_touch(index: int, position: Vector2) -> void:
    if _roles.has(index) or _view == null:
        return
    var layout: Dictionary = _view.get("layout")
    if layout.is_empty():
        return
    var buttons: Dictionary = layout["buttons"]
    for action in buttons:
        var button_rect: Rect2 = buttons[action]
        if button_rect.has_point(position):
            if _roles.values().has(action):
                return
            _roles[index] = action
            if action == &"aim":
                _aim_toggled = not _aim_toggled
                if _aim_toggled:
                    Input.action_press("aim")
                else:
                    Input.action_release("aim")
            else:
                Input.action_press(action)
            # The FIRE finger also aims, so running + shooting need only two thumbs.
            if action == &"shoot" and _look_finger == -1:
                _look_finger = index
            get_viewport().set_input_as_handled()
            _refresh_view()
            return
    var center: Vector2 = layout["center"]
    var radius: float = float(layout["radius"])
    if _move_finger == -1 and position.distance_to(center) < radius * 1.55:
        _roles[index] = &"move"
        _move_finger = index
        _update_stick(position)
        get_viewport().set_input_as_handled()
        return
    var look_rect: Rect2 = layout["look"]
    if _look_finger == -1 and look_rect.has_point(position):
        _roles[index] = &"look"
        _look_finger = index
        get_viewport().set_input_as_handled()

func _drag_touch(index: int, position: Vector2, relative: Vector2) -> void:
    if not _roles.has(index):
        return
    if index == _move_finger:
        _update_stick(position)
    elif index == _look_finger and is_instance_valid(_player):
        var height: float = maxf(1.0, get_viewport().get_visible_rect().size.y)
        # Normalize to the logical viewport; sensitivity is not multiplied by FPS.
        var normalized_delta: Vector2 = relative * (720.0 / height)
        _player.call("apply_look_delta", normalized_delta, 0.72 * SettingsManager.touch_look_sensitivity)
    get_viewport().set_input_as_handled()

func _end_touch(index: int) -> void:
    if not _roles.has(index):
        return
    var role: StringName = _roles[index]
    if role == &"move":
        _release_movement()
        _move_finger = -1
        _view.set("stick", Vector2.ZERO)
    elif role != &"look" and role != &"aim":
        Input.action_release(role)
    if index == _look_finger:
        _look_finger = -1
    _roles.erase(index)
    _refresh_view()
    get_viewport().set_input_as_handled()

func _update_stick(position: Vector2) -> void:
    var layout: Dictionary = _view.get("layout")
    var axis: Vector2 = LAYOUT.stick_axis(position, layout["center"], float(layout["radius"]))
    _set_move("move_left", maxf(0.0, -axis.x))
    _set_move("move_right", maxf(0.0, axis.x))
    _set_move("move_forward", maxf(0.0, -axis.y))
    _set_move("move_back", maxf(0.0, axis.y))
    _view.set("stick", axis)
    _view.queue_redraw()

func _set_move(action: StringName, strength: float) -> void:
    if strength > 0.001:
        Input.action_press(action, strength)
    else:
        Input.action_release(action)

func _release_movement() -> void:
    for action in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
        Input.action_release(action)

func _reset_controls() -> void:
    if not _enabled:
        return
    _release_movement()
    for action in [&"shoot", &"dash", &"jump", &"interact", &"weapon_next", &"aim"]:
        Input.action_release(action)
    _roles.clear()
    _move_finger = -1
    _look_finger = -1
    _aim_toggled = false
    if is_instance_valid(_view):
        _view.set("stick", Vector2.ZERO)
        _refresh_view()

func _refresh_view() -> void:
    if not is_instance_valid(_view):
        return
    var held: Dictionary = {}
    for role in _roles.values():
        held[role] = true
    _view.set("held", held)
    _view.set("aim_toggled", _aim_toggled)
    _view.queue_redraw()

func _process(_delta: float) -> void:
    if not _enabled or not is_instance_valid(_view):
        return
    var available: bool = _can_control()
    _view.visible = available
    if not available:
        if not _roles.is_empty() or _aim_toggled:
            _reset_controls()
        return
    _view.set("dash_remaining", float(_player.get("_dash_cd")))
    _view.queue_redraw()

func _can_control() -> bool:
    return not get_tree().paused and is_instance_valid(_player) and bool(_player.get("control_enabled"))

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _reset_controls()

func _exit_tree() -> void:
    _reset_controls()
    _restore_mouse_bindings()
