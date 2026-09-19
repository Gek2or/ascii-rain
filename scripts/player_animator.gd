extends Node3D

const LIMB_POSE = preload("res://components/motion/two_bone_pose.gd")

# Lightweight procedural third-person animation layer.
# It intentionally uses the same primitive geometry on desktop and Android,
# so the ASCII renderer can keep the character readable without skeletal assets.

@export var run_frequency: float = 10.0
@export var run_arm_swing: float = 0.72
@export var run_leg_swing: float = 0.82
@export var camera_bob_amount: float = 0.035
var _time: float = 0.0
var _cycle: float = 0.0
var _shot_kick: float = 0.0
var _hit_kick: float = 0.0
var _dash_kick: float = 0.0
var _flash_timer: float = 0.0
var _flash_duration: float = 0.072
var _flash_energy: float = 6.8
var _death_mix: float = 0.0
var _dead: bool = false
var _last_on_floor: bool = true
var _last_vertical_velocity: float = 0.0
var _landing_kick: float = 0.0
var _impact_kick: float = 0.0
var _weapon_swap: float = 0.0
var _smoothed_local_velocity: Vector3 = Vector3.ZERO
var _motion_spring: Vector3 = Vector3.ZERO
var _world_yaw: float = 0.0
var _last_world_position: Vector3 = Vector3.ZERO
var _travel: float = 0.0
var _motion_activity: float = 0.0
var _aim_mix: float = 0.0
var _aim_timer: float = 0.0
var _foot_anchors: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _foot_targets: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _foot_queries: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _foot_floor: Array[float] = [0.0, 0.0]
var _foot_planted: Array[bool] = [false, false]

@onready var boot_l: Node3D = $BodyRoot/LegLPivot/ShinPivot/Boot
@onready var boot_r: Node3D = $BodyRoot/LegRPivot/ShinPivot/Boot
@onready var right_grip: Marker3D = $WeaponPivot/RightGrip
@onready var left_grip: Marker3D = $WeaponPivot/LeftGrip

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var body_root: Node3D = $BodyRoot
@onready var head_root: Node3D = $BodyRoot/HeadRoot
@onready var arm_l: Node3D = $BodyRoot/ArmLPivot
@onready var arm_r: Node3D = $BodyRoot/ArmRPivot
@onready var forearm_l: Node3D = $BodyRoot/ArmLPivot/ForearmPivot
@onready var forearm_r: Node3D = $BodyRoot/ArmRPivot/ForearmPivot
@onready var leg_l: Node3D = $BodyRoot/LegLPivot
@onready var leg_r: Node3D = $BodyRoot/LegRPivot
@onready var shin_l: Node3D = $BodyRoot/LegLPivot/ShinPivot
@onready var shin_r: Node3D = $BodyRoot/LegRPivot/ShinPivot
@onready var weapon_pivot: Node3D = $WeaponPivot
@onready var muzzle_flash: MeshInstance3D = $WeaponPivot/MuzzleFlash
@onready var muzzle_light: OmniLight3D = $WeaponPivot/MuzzleLight
@onready var gun_visual: MeshInstance3D = $WeaponPivot/Gun
@onready var barrel_glow: MeshInstance3D = $WeaponPivot/BarrelGlow
@onready var camera: Camera3D = get_node_or_null("../CameraPivot/SpringArm3D/Camera3D") as Camera3D

var _body_base_position: Vector3 = Vector3.ZERO
var _weapon_base_position: Vector3 = Vector3.ZERO
var _camera_base_position: Vector3 = Vector3.ZERO
var _camera_base_fov: float = 74.0
var _flash_material: StandardMaterial3D = null

func _ready() -> void:
    _body_base_position = body_root.position
    _weapon_base_position = weapon_pivot.position
    _last_on_floor = player != null and player.is_on_floor()
    _last_world_position = player.global_position
    _world_yaw = player.global_rotation.y
    for i in range(2):
        var side: float = -1.0 if i == 0 else 1.0
        _foot_targets[i] = player.to_global(Vector3(side * 0.20, 0.08, 0.02))
        _foot_anchors[i] = _foot_targets[i]
        _foot_queries[i] = _foot_targets[i]
    muzzle_flash.visible = false
    muzzle_light.light_energy = 0.0
    var source_mat: StandardMaterial3D = muzzle_flash.material_override as StandardMaterial3D
    if camera != null:
        _camera_base_position = camera.position
        _camera_base_fov = camera.fov
    if source_mat != null:
        _flash_material = source_mat.duplicate() as StandardMaterial3D
        muzzle_flash.material_override = _flash_material

func _process(delta: float) -> void:
    if player == null:
        return

    _time += delta
    _aim_timer = maxf(0.0, _aim_timer - delta)
    var wants_aim: bool = _aim_timer > 0.0 or Input.is_action_pressed("aim")
    _aim_mix = lerpf(_aim_mix, 1.0 if wants_aim else 0.0, 1.0 - exp(-delta * 15.0))
    var displacement: Vector3 = player.global_position - _last_world_position
    displacement.y = 0.0
    _travel = minf(displacement.length(), 0.7)
    _last_world_position = player.global_position
    _shot_kick = move_toward(_shot_kick, 0.0, delta * 9.5)
    _hit_kick = move_toward(_hit_kick, 0.0, delta * 7.0)
    _dash_kick = move_toward(_dash_kick, 0.0, delta * 6.5)
    _landing_kick = move_toward(_landing_kick, 0.0, delta * 7.5)
    _impact_kick = move_toward(_impact_kick, 0.0, delta * 12.0)
    _weapon_swap = move_toward(_weapon_swap, 0.0, delta * 4.8)

    if _flash_timer > 0.0:
        _flash_timer -= delta
        var flash_alpha: float = clampf(_flash_timer / maxf(_flash_duration, 0.001), 0.0, 1.0)
        muzzle_flash.visible = true
        muzzle_flash.scale = Vector3.ONE * lerpf(0.22, 1.0, flash_alpha)
        muzzle_light.light_energy = _flash_energy * flash_alpha
    else:
        muzzle_flash.visible = false
        muzzle_light.light_energy = 0.0

    if _dead:
        _animate_death(delta)
        return

    var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
    var move_speed_value: float = maxf(0.1, float(player.get("move_speed")))
    var speed_ratio: float = clampf(horizontal_speed / move_speed_value, 0.0, 1.8)
    var on_floor: bool = player.is_on_floor()

    if not _last_on_floor and on_floor and _last_vertical_velocity < -2.5:
        _landing_kick = clampf(absf(_last_vertical_velocity) / 13.0, 0.2, 1.0)
    _last_on_floor = on_floor
    _last_vertical_velocity = player.velocity.y

    var view_local: Vector3 = player.global_transform.basis.inverse() * player.velocity
    var desired_yaw: float = player.global_rotation.y - clampf(view_local.x * 0.026, -0.25, 0.25) * (1.0 - _aim_mix)
    _world_yaw = lerp_angle(_world_yaw, desired_yaw, 1.0 - exp(-delta * 15.0))
    rotation.y = wrapf(_world_yaw - player.global_rotation.y, -PI, PI)
    var local_velocity: Vector3 = global_transform.basis.inverse() * player.velocity
    var stride_amount: float = clampf(speed_ratio, 0.0, 1.0)
    # Gait advances with actual travel, so pushing into a wall does not run in place.
    if on_floor and _dash_kick < 0.3:
        _cycle = fmod(_cycle + _travel / 2.55 * TAU, TAU)
    var travel_ratio: float = minf(1.4, _travel / maxf(delta, 0.0001) / move_speed_value)
    _motion_activity = lerpf(_motion_activity, travel_ratio, 1.0 - exp(-delta * 14.0))
    stride_amount = clampf(_motion_activity, 0.0, 1.0)
    var stride: float = sin(_cycle)
    var stride_cos: float = cos(_cycle)

    if on_floor:
        _animate_ground(delta, local_velocity, stride_amount, stride, stride_cos)
    else:
        _animate_air(delta, local_velocity)

    _animate_weapon(delta, stride_amount, stride, local_velocity)
    if on_floor:
        _pose_feet(delta, stride_amount)
    else:
        _foot_planted[0] = false
        _foot_planted[1] = false
    _pose_hands()
    _animate_camera(delta, stride_amount, stride, stride_cos)

func trigger_shot(color: Color = Color(1.0, 0.18, 0.04), recoil: float = 1.0, flash_duration: float = 0.072, light_energy: float = 6.8) -> void:
    _shot_kick = maxf(_shot_kick, clampf(recoil, 0.25, 2.5))
    _aim_timer = 0.38
    _flash_duration = clampf(flash_duration, 0.02, 0.2)
    _flash_timer = maxf(_flash_timer, _flash_duration)
    _flash_energy = clampf(light_energy, 1.0, 16.0)
    muzzle_light.light_color = color
    if _flash_material != null:
        _flash_material.albedo_color = color
        _flash_material.emission = color

func trigger_impact(intensity: float = 0.65) -> void:
    _impact_kick = maxf(_impact_kick, clampf(intensity, 0.0, 1.4))

func trigger_weapon_swap() -> void:
    _weapon_swap = 1.0

func trigger_hit() -> void:
    _hit_kick = 1.0

func trigger_dash() -> void:
    _dash_kick = 1.0

func trigger_death() -> void:
    _dead = true
    _death_mix = 0.0
    _shot_kick = 0.0
    muzzle_flash.visible = false
    muzzle_light.light_energy = 0.0

func _animate_ground(delta: float, local_velocity: Vector3, stride_amount: float, stride: float, stride_cos: float) -> void:
    var response: float = clampf(delta * 13.0, 0.0, 1.0)
    var idle_breath: float = sin(_time * 2.25) * 0.018
    var run_bob: float = absf(stride_cos) * 0.024 * stride_amount
    var target_body_y: float = _body_base_position.y + idle_breath + run_bob - stride_amount * 0.16 - _landing_kick * 0.08
    body_root.position.y = lerpf(body_root.position.y, target_body_y, response)

    var strafe_ratio: float = clampf(local_velocity.x / maxf(1.0, float(player.get("move_speed"))), -1.0, 1.0)
    var forward_ratio: float = clampf(-local_velocity.z / maxf(1.0, float(player.get("move_speed"))), -1.0, 1.0)
    _smoothed_local_velocity = _smoothed_local_velocity.lerp(local_velocity, clampf(delta * 7.0, 0.0, 1.0))
    var velocity_error: Vector3 = local_velocity - _smoothed_local_velocity
    _motion_spring = _motion_spring.lerp(velocity_error, clampf(delta * 10.0, 0.0, 1.0))
    var elastic_pitch: float = clampf(_motion_spring.z * 0.020, -0.12, 0.12)
    var elastic_roll: float = clampf(-_motion_spring.x * 0.024, -0.14, 0.14)
    var lean_x: float = deg_to_rad(-5.0) * maxf(0.0, forward_ratio) + elastic_pitch - deg_to_rad(17.0) * _dash_kick
    var lean_z: float = deg_to_rad(-7.0) * strafe_ratio + elastic_roll + sin(_time * 17.0) * deg_to_rad(1.2) * _hit_kick
    body_root.rotation.x = lerp_angle(body_root.rotation.x, lean_x, response)
    body_root.rotation.z = lerp_angle(body_root.rotation.z, lean_z, response)

    var arm_swing: float = stride * run_arm_swing * stride_amount
    var leg_swing: float = stride * run_leg_swing * stride_amount
    arm_l.rotation.x = lerp_angle(arm_l.rotation.x, arm_swing + 0.10, response)
    arm_r.rotation.x = lerp_angle(arm_r.rotation.x, -arm_swing - 0.16 - _shot_kick * 0.12, response)
    arm_l.rotation.z = lerp_angle(arm_l.rotation.z, -0.10, response)
    arm_r.rotation.z = lerp_angle(arm_r.rotation.z, 0.12, response)
    forearm_l.rotation.x = lerp_angle(forearm_l.rotation.x, maxf(0.0, -arm_swing) * 0.45 - 0.16, response)
    forearm_r.rotation.x = lerp_angle(forearm_r.rotation.x, -0.58 - _shot_kick * 0.34, response)

    leg_l.rotation.x = lerp_angle(leg_l.rotation.x, -leg_swing, response)
    leg_r.rotation.x = lerp_angle(leg_r.rotation.x, leg_swing, response)
    shin_l.rotation.x = lerp_angle(shin_l.rotation.x, maxf(0.0, leg_swing) * 0.72, response)
    shin_r.rotation.x = lerp_angle(shin_r.rotation.x, maxf(0.0, -leg_swing) * 0.72, response)

    head_root.rotation.y = lerp_angle(head_root.rotation.y, strafe_ratio * 0.08, response)
    head_root.rotation.z = lerp_angle(head_root.rotation.z, -strafe_ratio * 0.045, response)

func _animate_air(delta: float, local_velocity: Vector3) -> void:
    var response: float = clampf(delta * 8.0, 0.0, 1.0)
    var rising: bool = player.velocity.y > 0.0
    var air_tilt: float = deg_to_rad(-7.0 if rising else 5.0)
    body_root.rotation.x = lerp_angle(body_root.rotation.x, air_tilt - deg_to_rad(14.0) * _dash_kick, response)
    body_root.rotation.z = lerp_angle(body_root.rotation.z, clampf(local_velocity.x * -0.015, -0.12, 0.12), response)
    body_root.position.y = lerpf(body_root.position.y, _body_base_position.y + 0.04, response)

    arm_l.rotation.x = lerp_angle(arm_l.rotation.x, -0.48 if rising else 0.22, response)
    arm_r.rotation.x = lerp_angle(arm_r.rotation.x, -0.62 - _shot_kick * 0.18 if rising else 0.12, response)
    forearm_l.rotation.x = lerp_angle(forearm_l.rotation.x, -0.22, response)
    forearm_r.rotation.x = lerp_angle(forearm_r.rotation.x, -0.52, response)
    leg_l.rotation.x = lerp_angle(leg_l.rotation.x, 0.42, response)
    leg_r.rotation.x = lerp_angle(leg_r.rotation.x, -0.34, response)
    shin_l.rotation.x = lerp_angle(shin_l.rotation.x, 0.52, response)
    shin_r.rotation.x = lerp_angle(shin_r.rotation.x, 0.70, response)

func _animate_weapon(delta: float, stride_amount: float, stride: float, local_velocity: Vector3) -> void:
    var response: float = clampf(delta * 18.0, 0.0, 1.0)
    var target_position: Vector3 = _weapon_base_position
    target_position.y += absf(stride) * 0.022 * stride_amount
    target_position.z += _shot_kick * 0.28
    target_position.y -= sin(_weapon_swap * PI) * 0.22
    target_position.x += sin(_time * 10.0) * 0.012 * stride_amount
    target_position.x += clampf(-local_velocity.x * 0.012, -0.09, 0.09)
    target_position.y += clampf(player.velocity.y * 0.008, -0.06, 0.06)
    weapon_pivot.position = weapon_pivot.position.lerp(target_position, response)

    var target_rotation: Vector3 = Vector3(float(player.get("_pitch")) * 0.85 - _shot_kick * 0.12 + sin(_weapon_swap * PI) * 0.10, wrapf(player.global_rotation.y - global_rotation.y, -PI, PI), -0.05 + stride * 0.025 * stride_amount + sin(_weapon_swap * PI) * 0.28)
    weapon_pivot.rotation.x = lerp_angle(weapon_pivot.rotation.x, target_rotation.x, response)
    weapon_pivot.rotation.y = lerp_angle(weapon_pivot.rotation.y, target_rotation.y, response)
    weapon_pivot.rotation.z = lerp_angle(weapon_pivot.rotation.z, target_rotation.z, response)

    var weapon_index: int = int(player.get("current_weapon"))
    var target_gun_scale: Vector3 = Vector3.ONE
    var target_glow_scale: Vector3 = Vector3(0.34, 0.28, 0.74)
    if weapon_index == 1:
        target_gun_scale = Vector3(1.52, 1.42, 0.84)
        target_glow_scale = Vector3(0.52, 0.42, 0.56)
    elif weapon_index == 2:
        target_gun_scale = Vector3(0.82, 0.88, 1.20)
        target_glow_scale = Vector3(0.24, 0.24, 1.05)
    gun_visual.scale = gun_visual.scale.lerp(target_gun_scale, response)
    barrel_glow.scale = barrel_glow.scale.lerp(target_glow_scale, response)

func _animate_camera(delta: float, stride_amount: float, stride: float, stride_cos: float) -> void:
    if camera == null:
        return
    var response: float = clampf(delta * 12.0, 0.0, 1.0)
    var motion_amount: float = SettingsManager.camera_motion * (1.0 - 0.72 * _aim_mix)
    var grounded: float = 1.0 if player.is_on_floor() else 0.0
    var bob_scale: float = camera_bob_amount * stride_amount * motion_amount * grounded
    var shake_x: float = sin(_time * 71.0) * 0.042 * _impact_kick + sin(_time * 34.0) * 0.025 * _hit_kick
    var shake_y: float = cos(_time * 83.0) * 0.032 * _impact_kick + sin(_time * 29.0) * 0.018 * _hit_kick
    var target_position: Vector3 = _camera_base_position + Vector3(
        stride * bob_scale * 0.55 + shake_x * motion_amount,
        absf(stride_cos) * bob_scale - _landing_kick * 0.035 * motion_amount + shake_y * motion_amount,
        _shot_kick * 0.025 * motion_amount
    )
    camera.position = camera.position.lerp(target_position, response)
    camera.rotation.z = lerp_angle(camera.rotation.z, sin(_time * 57.0) * 0.006 * _impact_kick * motion_amount, response)
    camera.rotation.x = lerp_angle(camera.rotation.x, -_shot_kick * 0.008 * motion_amount, response)
    var target_fov: float = _camera_base_fov - _aim_mix * 5.0 + (stride_amount * 0.8 + _dash_kick * 4.0) * motion_amount
    camera.fov = lerpf(camera.fov, target_fov, response)

func _animate_death(delta: float) -> void:
    _death_mix = minf(1.0, _death_mix + delta * 1.8)
    var response: float = clampf(delta * 5.0, 0.0, 1.0)
    body_root.rotation.z = lerp_angle(body_root.rotation.z, deg_to_rad(78.0), response)
    body_root.rotation.x = lerp_angle(body_root.rotation.x, deg_to_rad(-18.0), response)
    body_root.position.y = lerpf(body_root.position.y, _body_base_position.y - 0.45, response)
    arm_l.rotation.x = lerp_angle(arm_l.rotation.x, 1.1, response)
    arm_r.rotation.x = lerp_angle(arm_r.rotation.x, -1.2, response)
    leg_l.rotation.x = lerp_angle(leg_l.rotation.x, -0.55, response)
    leg_r.rotation.x = lerp_angle(leg_r.rotation.x, 0.62, response)
    weapon_pivot.rotation.z = lerp_angle(weapon_pivot.rotation.z, 0.85, response)
    if camera != null:
        camera.position.y = lerpf(camera.position.y, -0.10, response)
        camera.fov = lerpf(camera.fov, 68.0, response)


func _physics_process(_delta: float) -> void:
    if _dead or player == null:
        return
    # Physics-space queries stay on physics ticks, not asynchronous render ticks.
    for i in range(2):
        var origin: Vector3 = _foot_queries[i] + Vector3.UP * 0.8
        var target_point: Vector3 = _foot_queries[i] - Vector3.UP * 1.4
        var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, target_point, 1)
        query.exclude = [player.get_rid()]
        var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty():
            var position_value: Vector3 = hit["position"]
            _foot_floor[i] = position_value.y
        else:
            _foot_floor[i] = player.global_position.y

func _pose_feet(delta: float, movement: float) -> void:
    var direction: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z).normalized()
    var right: Vector3 = global_transform.basis.x
    var response: float = 1.0 - exp(-delta * 25.0)
    for i in range(2):
        var side: float = -1.0 if i == 0 else 1.0
        var center: Vector3 = player.global_position + right * side * 0.20
        center.y = _foot_floor[i] + 0.08
        var phase: float = fmod(_cycle / TAU + float(i) * 0.5, 1.0)
        var stance_now: bool = phase < 0.45 and movement > 0.08
        var desired: Vector3 = center
        if movement > 0.08:
            if stance_now:
                if not _foot_planted[i]:
                    _foot_anchors[i] = center + direction * 0.36
                desired = _foot_anchors[i]
                desired.y = center.y
                var offset: Vector3 = desired - center
                offset.y = 0.0
                if offset.length() > 0.48:
                    desired = center + offset.normalized() * 0.48
            else:
                var swing: float = clampf((phase - 0.45) / 0.55, 0.0, 1.0)
                var eased: float = swing * swing * (3.0 - 2.0 * swing)
                desired = center + direction * lerpf(-0.38, 0.36, eased)
                desired.y += sin(swing * PI) * 0.18
        _foot_planted[i] = stance_now
        _foot_targets[i] = _foot_targets[i].lerp(desired, response)
        _foot_queries[i] = desired
        var upper: Node3D = leg_l if i == 0 else leg_r
        var lower: Node3D = shin_l if i == 0 else shin_r
        var boot: Node3D = boot_l if i == 0 else boot_r
        var pole: Vector3 = upper.global_position - global_transform.basis.z * 1.5
        LIMB_POSE.solve(upper, lower, _foot_targets[i], pole, 0.46, 0.46)
        boot.global_position = lower.global_transform * Vector3(0.0, -0.46, 0.0) - global_transform.basis.z * 0.08
        boot.global_rotation = Vector3(0.0, global_rotation.y, 0.0)

func _pose_hands() -> void:
    # Hands follow the actual rifle grips instead of swinging through a floating gun.
    var left_pole: Vector3 = arm_l.global_position - global_transform.basis.x + global_transform.basis.z * 0.2
    var right_pole: Vector3 = arm_r.global_position + global_transform.basis.x + global_transform.basis.z * 0.2
    LIMB_POSE.solve(arm_l, forearm_l, left_grip.global_position, left_pole, 0.35, 0.34)
    LIMB_POSE.solve(arm_r, forearm_r, right_grip.global_position, right_pole, 0.35, 0.34)
