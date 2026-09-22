extends CharacterBody3D

const AIM_PROBE = preload("res://components/weapon/aim_probe.gd")
const ACTOR_STYLE = preload("res://rendering/actor_readability.gd")
const ASCII_FX = preload("res://scripts/ascii_fx.gd")
const TRACER_SCENE: PackedScene = preload("res://scenes/Tracer.tscn")
signal health_changed(current: float, maximum: float)
signal damaged(amount: float)
signal xp_changed(current: int, needed: int, level: int)
signal credits_changed(current: int)
signal inventory_changed(summary: String)
signal died
signal upgrade_announced(text: String)
signal weapon_changed(name: String, detail: String)

const WEAPON_PULSE = 0
const WEAPON_SCATTER = 1
const WEAPON_ARC = 2

@export var move_speed: float = 8.6
@export var ground_acceleration: float = 38.0
@export var ground_deceleration: float = 46.0
@export var air_acceleration: float = 12.0
@export var jump_velocity: float = 7.4
@export var mouse_sensitivity: float = 0.00205
@export var coyote_time: float = 0.11
@export var jump_buffer_time: float = 0.13
@export var max_health: float = 200.0
@export var damage: float = 28.0
@export var fire_rate: float = 7.0
@export var shoot_range: float = 120.0
@export var dash_speed: float = 24.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 1.0

var health: float = 200.0
var level: int = 1
var xp: int = 0
var xp_needed: int = 40
var credits: int = 0
var control_enabled: bool = true
var current_weapon: int = WEAPON_PULSE

var _gravity: float = 20.0
var _pitch: float = -0.18
var _pending_yaw: float = 0.0
var _shot_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _dash_fx_timer: float = 0.0
var _impact_hit_this_shot: bool = false
var _impact_crit_this_shot: bool = false
var _invulnerability_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _last_horizontal_velocity: Vector3 = Vector3.ZERO
var _aim_solution: Dictionary = {}
var _ui_lock_until_msec: int = 0
var _ui_fire_release_required: bool = false

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var muzzle: Marker3D = $Visual/WeaponPivot/Muzzle
@onready var animator: Node = $Visual
@onready var weapon_controller: WeaponController = $WeaponController
@onready var inventory_component: InventoryComponent = $InventoryComponent

func _ready() -> void:
    add_to_group("player")
    health = max_health
    _rng.randomize()
    var spring: SpringArm3D = $CameraPivot/SpringArm3D
    spring.add_excluded_object(get_rid())
    camera_pivot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    $Visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    reset_physics_interpolation()
    floor_snap_length = 0.30
    floor_stop_on_slope = true
    floor_max_angle = deg_to_rad(48.0)
    weapon_controller.weapon_changed.connect(_on_weapon_controller_changed)
    current_weapon = weapon_controller.current_index
    if not _is_mobile_runtime():
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if OS.has_feature("web") else Input.MOUSE_MODE_CAPTURED
    health_changed.emit(health, max_health)
    xp_changed.emit(xp, xp_needed, level)
    credits_changed.emit(credits)
    _emit_inventory()
    _emit_weapon()
    ACTOR_STYLE.apply($Visual, true)

func _input(event: InputEvent) -> void:
    if not control_enabled:
        return
    if OS.has_feature("web") and event is InputEventMouseButton:
        var button: InputEventMouseButton = event as InputEventMouseButton
        if button.pressed and button.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            _ui_fire_release_required = true
            get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
    if not control_enabled:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        apply_look_delta(motion.screen_relative, 1.0)

func _physics_process(delta: float) -> void:
    if not control_enabled:
        _pending_yaw = 0.0
        velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, ground_deceleration * delta)
        move_and_slide()
        return

    rotate_y(_pending_yaw)
    _pending_yaw = 0.0
    var ui_locked: bool = Time.get_ticks_msec() < _ui_lock_until_msec
    if _ui_fire_release_required and not Input.is_action_pressed("shoot"):
        _ui_fire_release_required = false
    _shot_timer = maxf(0.0, _shot_timer - delta)
    _dash_cd = maxf(0.0, _dash_cd - delta)
    _dash_timer = maxf(0.0, _dash_timer - delta)
    _dash_fx_timer = maxf(0.0, _dash_fx_timer - delta)
    _invulnerability_timer = maxf(0.0, _invulnerability_timer - delta)
    _coyote_timer = maxf(0.0, _coyote_timer - delta)
    _jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

    if not ui_locked and Input.is_action_just_pressed("weapon_next"):
        cycle_weapon()
    elif not ui_locked and Input.is_action_just_pressed("weapon_1"):
        select_weapon(WEAPON_PULSE)
    elif not ui_locked and Input.is_action_just_pressed("weapon_2"):
        select_weapon(WEAPON_SCATTER)
    elif not ui_locked and Input.is_action_just_pressed("weapon_3"):
        select_weapon(WEAPON_ARC)

    if not ui_locked and Input.is_action_just_pressed("jump"):
        _jump_buffer_timer = jump_buffer_time

    if is_on_floor():
        _coyote_timer = coyote_time
        if velocity.y < 0.0:
            velocity.y = -0.6
    else:
        velocity.y -= _gravity * delta

    if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
        velocity.y = jump_velocity
        _jump_buffer_timer = 0.0
        _coyote_timer = 0.0

    if Input.is_action_just_released("jump") and velocity.y > 2.0:
        velocity.y *= 0.54

    var input_vec: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back", 0.10)
    var local_dir: Vector3 = Vector3(input_vec.x, 0.0, input_vec.y)
    var wish_dir: Vector3 = global_transform.basis * local_dir

    if not ui_locked and Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
        _dash_dir = wish_dir if wish_dir.length_squared() > 0.01 else -global_transform.basis.z
        _dash_dir.y = 0.0
        _dash_dir = _dash_dir.normalized()
        _dash_timer = dash_duration
        _dash_cd = dash_cooldown
        _invulnerability_timer = maxf(_invulnerability_timer, minf(0.18, dash_duration + 0.02))
        AudioManager.play_dash()
        if animator.has_method("trigger_dash"):
            animator.call("trigger_dash")

    if _dash_timer > 0.0:
        velocity.x = _dash_dir.x * dash_speed
        velocity.z = _dash_dir.z * dash_speed
        if _dash_fx_timer <= 0.0:
            _dash_fx_timer = 0.045
            ASCII_FX.dash_echo(get_tree().current_scene, global_position, Color(0.30, 0.72, 1.0))
    else:
        var target_velocity: Vector3 = wish_dir * move_speed
        var on_ground: bool = is_on_floor()
        var response_accel: float = ground_acceleration if on_ground else air_acceleration
        var response_decel: float = ground_deceleration if on_ground else air_acceleration * 0.70
        if wish_dir.length_squared() > 0.001:
            velocity.x = move_toward(velocity.x, target_velocity.x, response_accel * delta)
            velocity.z = move_toward(velocity.z, target_velocity.z, response_accel * delta)
        else:
            velocity.x = move_toward(velocity.x, 0.0, response_decel * delta)
            velocity.z = move_toward(velocity.z, 0.0, response_decel * delta)

    _last_horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)
    move_and_slide()
    _aim_solution = AIM_PROBE.sample(self, muzzle, _resolve_camera_aim_point())

    if not ui_locked and not _ui_fire_release_required and Input.is_action_pressed("shoot") and _shot_timer <= 0.0 and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or _is_mobile_runtime()):
        _shot_timer = 1.0 / maxf(0.1, _get_weapon_fire_rate())
        _shoot()

func apply_look_delta(delta_pixels: Vector2, sensitivity_scale: float = 1.0) -> void:
    if not control_enabled:
        return
    var aim_sensitivity: float = 0.62 if Input.is_action_pressed("aim") else 1.0
    var final_sensitivity: float = mouse_sensitivity * SettingsManager.mouse_sensitivity_scale * sensitivity_scale * aim_sensitivity
    if _is_mobile_runtime():
        rotate_y(-delta_pixels.x * final_sensitivity)
    else:
        _pending_yaw -= delta_pixels.x * final_sensitivity
    _pitch = clamp(_pitch - delta_pixels.y * final_sensitivity, -1.05, 0.55)
    camera_pivot.rotation.x = _pitch

func _is_mobile_runtime() -> bool:
    return RuntimeProfile.is_mobile

func _shoot() -> void:
    _impact_hit_this_shot = false
    _impact_crit_this_shot = false
    AudioManager.play_weapon(current_weapon)
    var origin: Vector3 = muzzle.global_position
    var aim_point: Vector3 = _aim_solution.get("target", origin - camera.global_transform.basis.z * shoot_range)
    var base_direction: Vector3 = (aim_point - origin).normalized()
    var camera_right: Vector3 = camera.global_transform.basis.x.normalized()
    var camera_up: Vector3 = camera.global_transform.basis.y.normalized()
    var split_stack: int = get_item_stack("split_core")
    var extra_per_stack: int = 2 if current_weapon == WEAPON_SCATTER else 1
    var shot_count: int = mini(12, _get_weapon_pellets() + split_stack * extra_per_stack)
    var spread_degrees: float = _get_weapon_spread_degrees()
    var damage_scale: float = _get_weapon_damage_scale()
    var tracer_color: Color = _get_weapon_color()
    var weapon_data: WeaponData = _get_weapon_data()
    if animator.has_method("trigger_shot"):
        var recoil: float = weapon_data.shot_recoil if weapon_data != null else 1.0
        var flash_duration: float = weapon_data.muzzle_flash_duration if weapon_data != null else 0.072
        var light_energy: float = weapon_data.muzzle_light_energy if weapon_data != null else 6.8
        animator.call("trigger_shot", tracer_color, recoil, flash_duration, light_energy)

    if bool(_aim_solution.get("barrel_blocked", false)):
        var obstruction: Vector3 = _aim_solution["point"]
        var safe_origin: Vector3 = _aim_solution["origin"]
        _spawn_tracer(safe_origin, obstruction, tracer_color)
        ASCII_FX.impact(get_tree().current_scene, obstruction, Color(0.85, 0.64, 0.31), false)
        GameEvents.emit_shot_feedback(false, false)
        return

    for i in range(shot_count):
        var offset_index: float = float(i) - float(shot_count - 1) * 0.5
        var horizontal_spread: float = deg_to_rad(offset_index * spread_degrees)
        var vertical_pattern: float = 0.0
        if shot_count > 1:
            vertical_pattern = sin(float(i) * 2.399963) * deg_to_rad(spread_degrees * 0.42)
        var direction: Vector3 = (base_direction + camera_right * tan(horizontal_spread) + camera_up * tan(vertical_pattern)).normalized()
        _fire_ray(origin, direction, damage_scale, tracer_color)

    GameEvents.emit_shot_feedback(_impact_hit_this_shot, _impact_crit_this_shot)

func _resolve_camera_aim_point() -> Vector3:
    var camera_origin: Vector3 = camera.global_position
    var camera_direction: Vector3 = -camera.global_transform.basis.z
    var camera_destination: Vector3 = camera_origin + camera_direction * shoot_range
    var camera_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(camera_origin, camera_destination)
    camera_query.exclude = [get_rid()]
    camera_query.collision_mask = 0b101
    var camera_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(camera_query)
    if not camera_hit.is_empty():
        return camera_hit.position
    return camera_destination

func _fire_ray(origin: Vector3, direction: Vector3, damage_scale: float, tracer_color: Color) -> void:
    var destination: Vector3 = origin + direction * shoot_range
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, destination)
    query.exclude = [get_rid()]
    query.collision_mask = 0b101
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    var hit_point: Vector3 = destination

    if not hit.is_empty():
        hit_point = hit.position
        var collider: Object = hit.collider
        if collider != null and collider.has_method("take_damage"):
            var shot_damage: float = damage * damage_scale
            var crit_chance: float = minf(0.65, 0.05 * float(get_item_stack("lens_fragment")))
            var is_crit: bool = _rng.randf() < crit_chance
            if is_crit:
                shot_damage *= 2.0
                _impact_crit_this_shot = true

            if get_item_stack("execution_rune") > 0 and collider.has_method("get_health_ratio"):
                var ratio: float = float(collider.call("get_health_ratio"))
                if ratio <= 0.35:
                    shot_damage *= 1.0 + 0.22 * float(get_item_stack("execution_rune"))

            collider.call("take_damage", shot_damage)
            if collider.has_method("apply_stagger"):
                collider.call("apply_stagger", _get_weapon_stagger_power(), global_position)
            _apply_on_hit_effects(collider, hit_point, shot_damage)
            var weapon_data: WeaponData = _get_weapon_data()
            if weapon_data != null and weapon_data.intrinsic_chain_jumps > 0:
                _chain_arc(collider, shot_damage * weapon_data.intrinsic_chain_damage_ratio, weapon_data.intrinsic_chain_jumps)
            ASCII_FX.impact(get_tree().current_scene, hit_point, tracer_color, is_crit or current_weapon == WEAPON_SCATTER)
            if animator.has_method("trigger_impact"):
                animator.call("trigger_impact", 1.0 if is_crit else 0.58)
            if not _impact_hit_this_shot:
                _impact_hit_this_shot = true
                AudioManager.play_hit(is_crit or current_weapon == WEAPON_SCATTER)
                _request_hit_stop(36 if is_crit or current_weapon == WEAPON_SCATTER else 18)

        elif collider != null:
            # Wall impacts are feedback, never enemy hit markers.
            ASCII_FX.impact(get_tree().current_scene, hit_point, Color(0.76, 0.60, 0.35), false)

    _spawn_tracer(origin, hit_point, tracer_color)

func _apply_on_hit_effects(primary: Object, hit_point: Vector3, dealt_damage: float) -> void:
    var leech_stack: int = get_item_stack("leech_wire")
    if leech_stack > 0:
        heal(dealt_damage * 0.015 * float(leech_stack))

    var chain_stack: int = get_item_stack("chain_arc")
    if chain_stack > 0 and _rng.randf() < minf(0.85, 0.16 * float(chain_stack)):
        _chain_arc(primary, dealt_damage * 0.34, mini(5, 1 + chain_stack))

    var blast_stack: int = get_item_stack("blast_glyph")
    if blast_stack > 0 and _rng.randf() < minf(0.70, 0.12 * float(blast_stack)):
        _blast(hit_point, dealt_damage * 0.42, 3.0 + 0.35 * float(blast_stack))

func _chain_arc(primary: Object, arc_damage: float, jumps: int) -> void:
    if not (primary is Node3D):
        return
    var current: Node3D = primary as Node3D
    var used: Array = [primary]
    for _jump in range(jumps):
        var next_enemy: Node3D = null
        var best_distance: float = 8.0
        for candidate in get_tree().get_nodes_in_group("enemies"):
            if not is_instance_valid(candidate) or candidate in used or not (candidate is Node3D):
                continue
            var candidate_3d: Node3D = candidate as Node3D
            var d: float = current.global_position.distance_to(candidate_3d.global_position)
            if d < best_distance:
                best_distance = d
                next_enemy = candidate_3d
        if next_enemy == null:
            break
        if next_enemy.has_method("take_damage"):
            next_enemy.call("take_damage", arc_damage)
        _spawn_tracer(current.global_position + Vector3.UP, next_enemy.global_position + Vector3.UP, Color(0.38, 0.72, 1.0))
        used.append(next_enemy)
        current = next_enemy

func _blast(center: Vector3, blast_damage: float, radius: float) -> void:
    ASCII_FX.burst(get_tree().current_scene, center, Color(1.0, 0.55, 0.08), 9, radius * 0.75)
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not (candidate is Node3D):
            continue
        var candidate_3d: Node3D = candidate as Node3D
        var distance: float = candidate_3d.global_position.distance_to(center)
        if distance <= radius and candidate.has_method("take_damage"):
            var falloff: float = clampf(1.0 - distance / (radius * 1.25), 0.25, 1.0)
            candidate.call("take_damage", blast_damage * falloff)

func _spawn_tracer(from: Vector3, to: Vector3, color: Color) -> void:
    if from.distance_to(to) <= 0.05:
        return
    var tracer_node: Node = PoolManager.spawn(TRACER_SCENE, get_tree().current_scene)
    if tracer_node == null:
        return
    tracer_node.call("configure", from, to, color, 0.055)

func get_reticle_gap_px() -> float:
    var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
    var speed_ratio: float = clampf(horizontal_speed / maxf(1.0, move_speed), 0.0, 1.5)
    var base_gap: float = 8.0 + _get_weapon_spread_degrees() * 1.15
    if not is_on_floor():
        base_gap += 3.0
    if _dash_timer > 0.0:
        base_gap += 5.0
    return clampf(base_gap + speed_ratio * 2.6, 7.0, 23.0)

func refresh_weapon_ui() -> void:
    _emit_weapon()

func cycle_weapon() -> void:
    if weapon_controller.count() <= 0:
        return
    select_weapon((current_weapon + 1) % weapon_controller.count())

func select_weapon(index: int) -> void:
    if not weapon_controller.select(index):
        return
    _shot_timer = minf(_shot_timer, 0.10)
    if animator.has_method("trigger_weapon_swap"):
        animator.call("trigger_weapon_swap")

func _on_weapon_controller_changed(index: int, data: WeaponData) -> void:
    current_weapon = index
    _emit_weapon()
    if data != null:
        GameEvents.emit_weapon_selected(data.id, data.display_name)

func _get_weapon_data() -> WeaponData:
    return weapon_controller.current()

func _get_weapon_fire_rate() -> float:
    var data: WeaponData = _get_weapon_data()
    return fire_rate * data.fire_rate_multiplier if data != null else fire_rate

func _get_weapon_damage_scale() -> float:
    var data: WeaponData = _get_weapon_data()
    return data.damage_multiplier if data != null else 1.0

func _get_weapon_pellets() -> int:
    var data: WeaponData = _get_weapon_data()
    return data.pellets if data != null else 1

func _get_weapon_spread_degrees() -> float:
    var data: WeaponData = _get_weapon_data()
    return data.spread_degrees if data != null else 0.0

func _get_weapon_color() -> Color:
    var data: WeaponData = _get_weapon_data()
    return data.tracer_color if data != null else Color.WHITE

func _get_weapon_stagger_power() -> float:
    var data: WeaponData = _get_weapon_data()
    return data.stagger_power if data != null else 0.5

func _get_weapon_name() -> String:
    var data: WeaponData = _get_weapon_data()
    return data.display_name if data != null else "WEAPON"

func _emit_weapon() -> void:
    var data: WeaponData = _get_weapon_data()
    var detail: String = "%d DMG // %.1f RPS" % [int(round(damage * _get_weapon_damage_scale())), _get_weapon_fire_rate()]
    if data != null and not data.hud_suffix.is_empty():
        detail += " // " + data.hud_suffix
    weapon_changed.emit(_get_weapon_name(), detail)

func _request_hit_stop(milliseconds: int) -> void:
    var scene: Node = get_tree().current_scene
    if scene != null and scene.has_method("request_hit_stop"):
        scene.call("request_hit_stop", milliseconds)

func take_damage(amount: float) -> void:
    if health <= 0.0 or _invulnerability_timer > 0.0:
        return
    var armor_stack: int = get_item_stack("armor_plating")
    var reduction: float = minf(0.65, 0.06 * float(armor_stack))
    var final_damage: float = maxf(0.0, amount * (1.0 - reduction))
    if final_damage <= 0.0:
        return
    health = maxf(0.0, health - final_damage)
    AudioManager.play_damage()
    damaged.emit(final_damage)
    if animator.has_method("trigger_hit"):
        animator.call("trigger_hit")
    health_changed.emit(health, max_health)
    if health <= 0.0:
        died.emit()
        if animator.has_method("trigger_death"):
            animator.call("trigger_death")
        control_enabled = false
        set_physics_process(false)
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func heal(amount: float) -> void:
    if amount <= 0.0 or health <= 0.0:
        return
    health = minf(max_health, health + amount)
    health_changed.emit(health, max_health)

func add_xp(amount: int) -> void:
    xp += amount
    while xp >= xp_needed:
        xp -= xp_needed
        level += 1
        xp_needed = int(round(float(xp_needed) * 1.28 + 8.0))
        _apply_level_surge()
    xp_changed.emit(xp, xp_needed, level)

func add_credits(amount: int) -> void:
    credits += maxi(0, amount)
    credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
    if amount <= 0:
        return true
    if credits < amount:
        return false
    credits -= amount
    credits_changed.emit(credits)
    return true

func get_credits() -> int:
    return credits

func grant_random_item() -> String:
    var item: ItemData = inventory_component.grant_random()
    if item == null:
        return ""
    _apply_granted_item(item)
    return String(item.id)

func grant_item(item_id: String) -> void:
    var item: ItemData = inventory_component.grant(StringName(item_id))
    if item == null:
        return
    _apply_granted_item(item)

func _apply_granted_item(item: ItemData) -> void:
    var item_id: String = String(item.id)
    _apply_item_effect(item_id)
    var stack_count: int = inventory_component.stack(item.id)
    upgrade_announced.emit("%s   ×%d" % [item.display_name, stack_count])
    GameEvents.emit_item_collected(item.id, stack_count)
    _emit_inventory()

func get_item_stack(item_id: String) -> int:
    return inventory_component.stack(StringName(item_id))

func announce(text: String) -> void:
    upgrade_announced.emit(text)

func _apply_item_effect(item_id: String) -> void:
    match item_id:
        "overcharge":
            damage *= 1.12
            _emit_weapon()
        "rapid_array":
            fire_rate *= 1.10
            _emit_weapon()
        "phase_legs":
            move_speed *= 1.06
        "reinforced_frame":
            max_health += 18.0
            health = minf(max_health, health + 30.0)
            health_changed.emit(health, max_health)
        "chrono_cell":
            dash_cooldown = maxf(0.28, dash_cooldown * 0.92)
        _:
            pass

func _apply_level_surge() -> void:
    var choice: int = _rng.randi_range(0, 3)
    match choice:
        0:
            damage *= 1.055
            _emit_weapon()
            upgrade_announced.emit("LEVEL SURGE   +5.5% DAMAGE")
        1:
            fire_rate *= 1.045
            _emit_weapon()
            upgrade_announced.emit("LEVEL SURGE   +4.5% FIRE RATE")
        2:
            move_speed *= 1.025
            upgrade_announced.emit("LEVEL SURGE   +2.5% SPEED")
        3:
            heal(max_health * 0.18)
            upgrade_announced.emit("LEVEL SURGE   REPAIR +18%")

func _emit_inventory() -> void:
    inventory_changed.emit(inventory_component.summary())

func is_aim_blocked() -> bool:
    return bool(_aim_solution.get("blocked", false))

func get_aim_block_screen_position() -> Vector2:
    if not is_aim_blocked():
        return Vector2(-1000.0, -1000.0)
    var point: Vector3 = _aim_solution.get("point", global_position)
    if camera.is_position_behind(point):
        return Vector2(-1000.0, -1000.0)
    return camera.unproject_position(point)

func suppress_actions_after_ui() -> void:
    _ui_lock_until_msec = Time.get_ticks_msec() + 180
    _ui_fire_release_required = true
    _shot_timer = maxf(_shot_timer, 0.20)
    _jump_buffer_timer = 0.0

func can_interact_now() -> bool:
    return control_enabled and health > 0.0 and Time.get_ticks_msec() >= _ui_lock_until_msec
