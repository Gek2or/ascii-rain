extends CharacterBody3D

const SIGHT = preload("res://components/combat/combat_sight.gd")
const ASCII_FX = preload("res://scripts/ascii_fx.gd")
const TELEGRAPH = preload("res://components/combat_telegraph.gd")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/EnemyProjectile.tscn")

signal health_changed(current: float, maximum: float)
signal phase_changed(phase: int, label: String)
signal died(boss: Node, xp_reward: int, credit_reward: int)

enum PendingAttack { NONE, FAN, RING, SLAM }

@export var max_health: float = 1800.0
@export var move_speed: float = 2.6
@export var projectile_damage: float = 18.0
@export var xp_reward: int = 180
@export var credit_reward: int = 90

var health: float = 1800.0
var phase: int = 1
var target: Node3D = null
var _fan_timer: float = 0.9
var _ring_timer: float = 4.2
var _slam_timer: float = 6.0
var _gravity: float = 18.0
var _anim_time: float = 0.0
var _attack_pulse: float = 0.0
var _hit_pulse: float = 0.0
var _visual_base_position: Vector3 = Vector3.ZERO
var _stagger_timer: float = 0.0
var _stagger_velocity: Vector3 = Vector3.ZERO
var _pending_attack: int = PendingAttack.NONE
var _windup_timer: float = 0.0
var _pending_direction: Vector3 = Vector3.FORWARD
var _death_started: bool = false
var _locked_aim: Vector3 = Vector3.ZERO
var _attack_cue: Node3D = null

@onready var visual: Node3D = $Visual
@onready var core: MeshInstance3D = $Visual/Core
@onready var arm_l: MeshInstance3D = $Visual/ArmL
@onready var arm_r: MeshInstance3D = $Visual/ArmR
@onready var leg_l: MeshInstance3D = $Visual/LegL
@onready var leg_r: MeshInstance3D = $Visual/LegR
@onready var head: MeshInstance3D = $Visual/Head
@onready var core_light: OmniLight3D = $Visual/CoreLight
@onready var back_fin_l: MeshInstance3D = $Visual/BackFinL
@onready var back_fin_r: MeshInstance3D = $Visual/BackFinR

func _ready() -> void:
    visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    add_to_group("enemies")
    add_to_group("boss")
    health = max_health
    _visual_base_position = visual.position
    target = get_tree().get_first_node_in_group("player") as Node3D
    health_changed.emit(health, max_health)

func setup(difficulty_scale: float) -> void:
    var health_scale: float = clampf(difficulty_scale, 1.0, 3.0)
    var damage_scale: float = clampf(difficulty_scale, 1.0, 2.5)
    max_health *= health_scale
    health = max_health
    projectile_damage *= damage_scale
    health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
    if _death_started:
        return
    _fan_timer = maxf(0.0, _fan_timer - delta)
    _ring_timer = maxf(0.0, _ring_timer - delta)
    _slam_timer = maxf(0.0, _slam_timer - delta)
    _stagger_timer = maxf(0.0, _stagger_timer - delta)
    _check_phase_transition()

    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player") as Node3D
        if target == null:
            return

    var to_player: Vector3 = target.global_position - global_position
    var flat: Vector3 = to_player
    flat.y = 0.0
    var distance: float = flat.length()
    var dir: Vector3 = flat.normalized() if distance > 0.001 else Vector3.FORWARD

    if _pending_attack != PendingAttack.NONE:
        _process_windup(delta, dir)
    elif _stagger_timer > 0.0:
        velocity.x = _stagger_velocity.x
        velocity.z = _stagger_velocity.z
        _stagger_velocity = _stagger_velocity.move_toward(Vector3.ZERO, 11.0 * delta)
    else:
        _update_movement(dir, distance, delta)
        _try_begin_attack(dir)

    if flat.length_squared() > 0.01:
        look_at(global_position + dir, Vector3.UP)

    if not is_on_floor():
        velocity.y -= _gravity * delta
    else:
        velocity.y = -0.2
    move_and_slide()
    _animate_motion(delta)

func _update_movement(dir: Vector3, distance: float, delta: float) -> void:
    var desired_min: float = 6.0 if phase == 1 else 5.0
    var desired_max: float = 10.5 if phase == 1 else 9.0
    if distance > desired_max:
        velocity.x = dir.x * move_speed
        velocity.z = dir.z * move_speed
    elif distance < desired_min:
        velocity.x = -dir.x * move_speed * 0.70
        velocity.z = -dir.z * move_speed * 0.70
    else:
        velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)

func _try_begin_attack(dir: Vector3) -> void:
    if phase >= 2 and _slam_timer <= 0.0:
        _queue_slam()
        return
    if _ring_timer <= 0.0:
        _queue_ring()
        return
    if _fan_timer <= 0.0 and is_instance_valid(target) and SIGHT.clear(get_world_3d(), global_position + Vector3.UP * 2.5, target.global_position + Vector3.UP):
        _queue_fan(dir)

func _queue_fan(dir: Vector3) -> void:
    _fan_timer = 1.10 if phase == 1 else 0.72
    _pending_attack = PendingAttack.FAN
    _windup_timer = 0.42 if phase == 1 else 0.30
    _pending_direction = dir
    _locked_aim = target.global_position + Vector3.UP
    _attack_pulse = 0.75
    var host: Node = get_tree().current_scene
    var start: Vector3 = global_position + Vector3.UP * 0.10
    var end: Vector3 = global_position + dir * 18.0
    _attack_cue = TELEGRAPH.line(host, start, end, _windup_timer, _phase_color(), 0.20 if phase == 1 else 0.28)

func _queue_ring() -> void:
    _ring_timer = 5.6 if phase == 1 else 3.9
    _pending_attack = PendingAttack.RING
    AudioManager.play_boss_warning()
    _windup_timer = 0.68 if phase == 1 else 0.48
    _attack_pulse = 0.88
    _attack_cue = TELEGRAPH.ring(get_tree().current_scene, global_position, 4.8 if phase == 1 else 5.8, _windup_timer, _phase_color(), 28)
    TELEGRAPH.marker(_attack_cue, global_position, "RADIAL // RELEASE", _windup_timer, _phase_color())

func _queue_slam() -> void:
    _slam_timer = 6.3
    _pending_attack = PendingAttack.SLAM
    AudioManager.play_boss_warning()
    _windup_timer = 0.82
    _attack_pulse = 1.0
    var warning_color: Color = Color(0.96, 0.10, 1.0)
    _attack_cue = TELEGRAPH.ring(get_tree().current_scene, global_position, 8.5, _windup_timer, warning_color, 34)
    TELEGRAPH.marker(_attack_cue, global_position, "!! FIELD COLLAPSE !!", _windup_timer, warning_color)

func _process_windup(delta: float, _dir: Vector3) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
    # The fan direction remains fixed for the duration of the warning.
    _windup_timer = maxf(0.0, _windup_timer - delta)
    _attack_pulse = maxf(_attack_pulse, 0.72 + absf(sin(Time.get_ticks_msec() * 0.020)) * 0.52)
    if _windup_timer <= 0.0:
        _execute_pending_attack()

func _execute_pending_attack() -> void:
    var attack: int = _pending_attack
    _pending_attack = PendingAttack.NONE
    _windup_timer = 0.0
    _clear_cue()
    match attack:
        PendingAttack.FAN:
            _fire_fan(5 if phase == 1 else 9)
        PendingAttack.RING:
            _fire_ring(12 if phase == 1 else 20, 0.0)
            if phase >= 2:
                _fire_ring(12, PI / 12.0)
        PendingAttack.SLAM:
            _execute_slam()
        _:
            pass

func _execute_slam() -> void:
    _attack_pulse = 1.65
    var host: Node = get_tree().current_scene
    ASCII_FX.burst(host, global_position + Vector3.UP * 1.2, Color(0.92, 0.08, 1.0), 42, 7.2)
    if is_instance_valid(target) and target.has_method("take_damage"):
        var flat_delta: Vector3 = target.global_position - global_position
        flat_delta.y = 0.0
        var distance: float = flat_delta.length()
        if distance <= 8.5 and absf(target.global_position.y - global_position.y) < 2.0 and SIGHT.clear(get_world_3d(), global_position + Vector3.UP, target.global_position + Vector3.UP):
            var falloff: float = clampf(1.0 - distance / 11.0, 0.35, 1.0)
            target.call("take_damage", projectile_damage * 1.65 * falloff)
    _fire_ring(24, PI / 24.0)

func _check_phase_transition() -> void:
    if phase != 1 or max_health <= 0.0:
        return
    if health / max_health > 0.55:
        return
    phase = 2
    move_speed *= 1.22
    projectile_damage *= 1.14
    _fan_timer = 0.35
    _ring_timer = minf(_ring_timer, 1.4)
    _slam_timer = 2.2
    _attack_pulse = 1.8
    _set_phase_visuals()
    ASCII_FX.burst(get_tree().current_scene, global_position + Vector3.UP * 2.0, Color(0.88, 0.08, 1.0), 52, 8.0)
    _attack_cue = TELEGRAPH.ring(get_tree().current_scene, global_position, 10.0, 0.95, Color(0.92, 0.16, 1.0), 36)
    TELEGRAPH.marker(_attack_cue, global_position, "PHASE 02 // OVERWRITE", 1.1, Color(1.0, 0.34, 1.0))
    phase_changed.emit(phase, "OVERWRITE")
    GameEvents.emit_boss_phase_changed(phase, "OVERWRITE")

func _set_phase_visuals() -> void:
    var source: StandardMaterial3D = core.material_override as StandardMaterial3D
    if source != null:
        var material: StandardMaterial3D = source.duplicate() as StandardMaterial3D
        var color: Color = Color(0.95, 0.08, 1.0)
        material.albedo_color = color
        material.emission = color
        material.emission_energy_multiplier = 10.0
        core.material_override = material
    core_light.light_color = Color(0.92, 0.12, 1.0)
    core_light.light_energy = 5.2
    core_light.omni_range = 9.5
    back_fin_l.rotation_degrees.z = -34.0
    back_fin_r.rotation_degrees.z = 34.0
    back_fin_l.scale *= 1.18
    back_fin_r.scale *= 1.18

func _animate_motion(delta: float) -> void:
    _anim_time += delta
    _attack_pulse = move_toward(_attack_pulse, 0.0, delta * 3.8)
    _hit_pulse = move_toward(_hit_pulse, 0.0, delta * 6.5)
    var speed_ratio: float = clampf(Vector2(velocity.x, velocity.z).length() / maxf(0.1, move_speed), 0.0, 1.0)
    var stride_speed: float = 4.3 if phase == 1 else 5.4
    var stride: float = sin(_anim_time * stride_speed) * speed_ratio
    var response: float = clampf(delta * 8.0, 0.0, 1.0)
    visual.position.y = lerpf(visual.position.y, _visual_base_position.y + absf(cos(_anim_time * stride_speed)) * 0.08 * speed_ratio, response)
    visual.rotation.x = lerp_angle(visual.rotation.x, -0.055 * speed_ratio - _attack_pulse * 0.06, response)
    visual.rotation.z = lerp_angle(visual.rotation.z, sin(_anim_time * 31.0) * 0.018 * _hit_pulse, response)
    arm_l.rotation.x = lerp_angle(arm_l.rotation.x, stride * 0.38 - _attack_pulse * 0.72, response)
    arm_r.rotation.x = lerp_angle(arm_r.rotation.x, -stride * 0.38 - _attack_pulse * 0.72, response)
    leg_l.rotation.x = lerp_angle(leg_l.rotation.x, -stride * 0.34, response)
    leg_r.rotation.x = lerp_angle(leg_r.rotation.x, stride * 0.34, response)
    head.rotation.y = lerp_angle(head.rotation.y, sin(_anim_time * 1.25) * 0.08, response)
    var core_pulse: float = 1.0 + absf(sin(_anim_time * (5.2 if phase == 1 else 8.0))) * (0.10 if phase == 1 else 0.18) + _attack_pulse * 0.22
    core.scale = Vector3.ONE * core_pulse
    var base_energy: float = 2.8 if phase == 1 else 4.0
    core_light.light_energy = base_energy + core_pulse * 0.85 + _attack_pulse * 1.6

func _fire_fan(count: int) -> void:
    _attack_pulse = 1.0
    if target == null:
        return
    var origin: Vector3 = global_position + Vector3(0.0, 2.5, 0.0)
    var base_dir: Vector3 = (_locked_aim - origin).normalized()
    var half: float = float(count - 1) * 0.5
    var spacing: float = 7.0 if phase == 1 else 5.2
    for i in range(count):
        var yaw: float = deg_to_rad((float(i) - half) * spacing)
        _spawn_projectile(origin, base_dir.rotated(Vector3.UP, yaw), 15.5 if phase == 1 else 18.0, projectile_damage, _phase_color())

func _fire_ring(count: int, angle_offset: float) -> void:
    _attack_pulse = 1.0
    var origin: Vector3 = global_position + Vector3(0.0, 1.6, 0.0)
    for i in range(count):
        var angle: float = angle_offset + TAU * float(i) / float(count)
        var dir: Vector3 = Vector3(cos(angle), 0.08, sin(angle)).normalized()
        _spawn_projectile(origin, dir, 10.5 if phase == 1 else 13.0, projectile_damage * 0.72, _phase_color())

func _spawn_projectile(origin: Vector3, dir: Vector3, speed: float, dmg: float, color: Color) -> void:
    var projectile_node: Node = PoolManager.spawn(PROJECTILE_SCENE, get_tree().current_scene)
    var projectile: Node3D = projectile_node as Node3D
    if projectile == null:
        return
    projectile.global_position = origin
    projectile.call("setup", dir, speed, dmg, color)

func apply_stagger(power: float, source_position: Vector3) -> void:
    if health <= 0.0 or _death_started:
        return
    var effective: float = clampf(power * (0.22 if phase == 1 else 0.16), 0.0, 0.35)
    if effective <= 0.02:
        return
    _stagger_timer = maxf(_stagger_timer, 0.04 + effective * 0.10)
    var knock_dir: Vector3 = global_position - source_position
    knock_dir.y = 0.0
    if knock_dir.length_squared() < 0.001:
        knock_dir = Vector3.BACK
    _stagger_velocity = knock_dir.normalized() * (1.0 + effective * 2.2)
    _hit_pulse = 1.0

func take_damage(amount: float) -> void:
    if health <= 0.0 or _death_started:
        return
    health = maxf(0.0, health - amount)
    _hit_pulse = 1.0
    health_changed.emit(health, max_health)
    _hit_flash()
    _check_phase_transition()
    if health <= 0.0:
        _die()

func _die() -> void:
    if _death_started:
        return
    _death_started = true
    _clear_cue()
    _pending_attack = PendingAttack.NONE
    ASCII_FX.burst(get_tree().current_scene, global_position + Vector3.UP * 1.5, _phase_color(), 46 if phase == 2 else 38, 7.2 if phase == 2 else 6.0)
    GameEvents.emit_boss_killed(self, xp_reward, credit_reward)
    died.emit(self, xp_reward, credit_reward)
    queue_free()

func get_health_ratio() -> float:
    if max_health <= 0.0:
        return 0.0
    return health / max_health

func _phase_color() -> Color:
    return Color(0.95, 0.08, 1.0) if phase >= 2 else Color(1.0, 0.10, 0.025)

func _hit_flash() -> void:
    var tween: Tween = create_tween()
    tween.tween_property(visual, "scale", Vector3.ONE * 1.06, 0.04)
    tween.tween_property(visual, "scale", Vector3.ONE, 0.08)


func _clear_cue() -> void:
    if is_instance_valid(_attack_cue):
        _attack_cue.queue_free()
    _attack_cue = null

func _exit_tree() -> void:
    _clear_cue()
