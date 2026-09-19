extends SceneTree

# Actual Godot regression test, NOT executed by the Python source checks.
# Run through tools/run_engine_checks.py for a temporary isolated save directory.
const TOUCH_LAYOUT = preload("res://components/input/touch_layout.gd")
const AIM_PROBE = preload("res://components/weapon/aim_probe.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var result: Error = change_scene_to_file("res://scenes/ReadabilityLab.tscn")
    if result != OK:
        _fail("Readability courtyard could not load")
        return
    for frame in range(8):
        await physics_frame
    if current_scene == null or get_nodes_in_group("practice_targets").size() != 3:
        _fail("Courtyard or its three fixed targets missing")
        return
    if current_scene.get_node_or_null("StoryDirector") != null or current_scene.get_node_or_null("EncounterDirector") != null:
        _fail("Practice scene should not have a run/story director")
        return

    var control: Node = current_scene.get_node("MobileControls")
    var player: CharacterBody3D = current_scene.get_node("Player") as CharacterBody3D
    var view: Control = control.get("_view") as Control
    if view == null:
        _fail("Touch preview missing: this test requires -- --touch-preview")
        return
    var layout: Dictionary = view.get("layout")
    var buttons: Dictionary = layout["buttons"]
    var center: Vector2 = layout["center"]
    var radius: float = float(layout["radius"])
    var fire: Rect2 = buttons[&"shoot"]
    var aim: Rect2 = buttons[&"aim"]
    var axis: Vector2 = TOUCH_LAYOUT.stick_axis(center + Vector2(radius * 0.5, 0.0), center, radius)
    if absf(axis.x - 0.5) > 0.001 or absf(axis.y) > 0.001:
        _fail("Actual analog layout helper lost magnitude")
        return

    # Native GUI still receives emulated mouse events; combat InputMap must not.
    var emulated: InputEventMouseButton = InputEventMouseButton.new()
    emulated.device = InputEvent.DEVICE_ID_EMULATION
    emulated.button_index = MOUSE_BUTTON_LEFT
    emulated.position = Vector2(600, 300)
    emulated.pressed = true
    Input.parse_input_event(emulated)
    if Input.is_action_pressed("shoot"):
        _fail("An emulated LMB from touching the screen triggered a shot")
        return
    var released: InputEventMouseButton = emulated.duplicate() as InputEventMouseButton
    released.pressed = false
    Input.parse_input_event(released)

    control.call("_begin_touch", 101, center)
    control.call("_drag_touch", 101, center + Vector2(0.0, -radius * 0.45), Vector2.ZERO)
    control.call("_begin_touch", 102, fire.get_center())
    var strength: float = Input.get_action_strength("move_forward")
    if strength < 0.2 or strength > 0.8 or not Input.is_action_pressed("shoot"):
        _fail("Two thumbs must support analog movement and fire simultaneously")
        return
    var yaw: float = player.rotation.y
    control.call("_drag_touch", 102, fire.get_center() + Vector2(20, 0), Vector2(20, 0))
    if is_equal_approx(yaw, player.rotation.y):
        _fail("Dragging the FIRE finger did not aim")
        return
    control.call("_end_touch", 102)
    if Input.is_action_pressed("shoot") or not Input.is_action_pressed("move_forward"):
        _fail("Releasing FIRE should not release the other thumb")
        return
    control.call("_end_touch", 101)
    control.call("_begin_touch", 103, aim.get_center())
    control.call("_end_touch", 103)
    if not Input.is_action_pressed("aim"):
        _fail("Touch AIM toggle was not retained after release")
        return
    var menu: Node = current_scene.get_node("SettingsMenu")
    menu.call("set_open", true)
    for frame in range(3):
        await process_frame
    if not paused or Input.is_action_pressed("aim") or Input.is_action_pressed("move_forward"):
        _fail("Pausing must clear all held touch input")
        return
    menu.call("set_open", false)

    # Isolated shoulder/barrel geometry within the courtyard; no render needed.
    var dummy: CharacterBody3D = CharacterBody3D.new()
    dummy.position = Vector3(14.0, 0.0, 13.0)
    current_scene.add_child(dummy)
    var muzzle: Marker3D = Marker3D.new()
    muzzle.position = Vector3(1.4, 1.42, 0.0)
    dummy.add_child(muzzle)
    var blocker: StaticBody3D = StaticBody3D.new()
    blocker.position = Vector3(14.7, 1.42, 13.0)
    var box: BoxShape3D = BoxShape3D.new()
    box.size = Vector3(0.16, 0.6, 0.6)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = box
    blocker.add_child(collision)
    current_scene.add_child(blocker)
    for frame in range(3):
        await physics_frame
    var hit: Dictionary = AIM_PROBE.sample(dummy, muzzle, Vector3(14.0, 1.42, 7.0))
    if not bool(hit["barrel_blocked"]):
        _fail("Shoulder-to-muzzle blocker was ignored")
        return
    blocker.queue_free()
    for frame in range(3):
        await physics_frame
    var clear: Dictionary = AIM_PROBE.sample(dummy, muzzle, Vector3(14.0, 1.42, 7.0))
    if bool(clear["barrel_blocked"]):
        _fail("Removed barrel blocker still blocks")
        return
    dummy.queue_free()
    current_scene.call("_test_flash")
    root.get_node("SettingsManager").call("update_background_calm", 0.55)
    for frame in range(20):
        await physics_frame
    print("MOBILE_CLARITY_SMOKE_OK: courtyard, analog touch, FIRE drag, AIM reset, barrel occlusion, vignette setup")
    root.get_node("AudioManager").call("stop_all")
    for cleanup_frame in range(12):
        await physics_frame
    quit(0)

func _fail(message: String) -> void:
    paused = false
    Input.action_release("shoot")
    Input.action_release("move_forward")
    Input.action_release("aim")
    push_error(message)
    quit(1)
