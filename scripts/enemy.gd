extends CharacterBody3D

const SIGHT = preload("res://components/combat/combat_sight.gd")
const NAVIGATION = preload("res://world/navigation/enemy_navigation.gd")
const DELAYED_BLAST = preload("res://components/combat/delayed_blast.gd")
const ACTOR_STYLE = preload("res://rendering/actor_readability.gd")
const ASCII_FX = preload("res://scripts/ascii_fx.gd")
const TELEGRAPH = preload("res://components/combat_telegraph.gd")
signal died(enemy: Node, xp_reward: int, credit_reward: int)

const PROJECTILE_SCENE = preload("res://scenes/EnemyProjectile.tscn")
const ENEMY_DATA: Array = [
    preload("res://data/enemies/grunt.tres"),
    preload("res://data/enemies/skitter.tres"),
    preload("res://data/enemies/gunner.tres"),
    preload("res://data/enemies/bomber.tres"),
    preload("res://data/enemies/tank.tres"),
]

enum EnemyType { GRUNT, SKITTER, GUNNER, BOMBER, TANK }
enum EliteType { NONE, OVERCHARGED, VOLATILE }
enum PendingAttack { NONE, MELEE, RANGED, TANK_BURST, BOMBER_DETONATE }
enum VisualProfile { BIPED, LOW, RANGED, CARRIER, HEAVY }

@export var move_speed: float = 3.4
@export var max_health: float = 55.0
@export var touch_damage: float = 11.0
@export var attack_interval: float = 0.8
@export var xp_reward: int = 12
@export var credit_reward: int = 4

var health: float = 55.0
var target: Node3D = null
var enemy_type: int = EnemyType.GRUNT
var elite_type: int = EliteType.NONE
var visual_profile: int = VisualProfile.BIPED
var accent_color: Color = Color(0.15, 0.18, 0.24)
var stride_scale: float = 0.64
var bob_amount: float = 0.055
var attack_pose_scale: float = 1.0
var projectile_damage: float = 9.0
var projectile_speed: float = 13.0
var preferred_range: float = 10.0
var _attack_timer: float = 0.0
var _gravity: float = 18.0
var _death_started: bool = false
var _visual_base_scale: Vector3 = Vector3.ONE
var _visual_base_position: Vector3 = Vector3.ZERO
var _anim_time: float = 0.0
var _attack_pulse: float = 0.0
var _hit_pulse: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _stagger_timer: float = 0.0
var _stagger_velocity: Vector3 = Vector3.ZERO
var _windup_timer: float = 0.0
var _pending_attack: int = PendingAttack.NONE
var _pending_direction: Vector3 = Vector3.ZERO
var _spawn_grace_timer: float = 0.95
var _home_position: Vector3 = Vector3.ZERO
var _navigation: RefCounted = NAVIGATION.new()
var _attack_cue: Node3D = null
var _pending_aim_point: Vector3 = Vector3.ZERO
var _sight_timer: float = 0.0
var _target_visible: bool = false
var _tactic_goal: Vector3 = Vector3.ZERO
var _tactic_timer: float = 0.0
var _move_delta: float = 0.016
var _fired_shots: int = 0
var _core_base_energy: float = 1.45

@onready var visual: Node3D = $Visual
@onready var core: MeshInstance3D = $Visual/Core
@onready var arm_l: MeshInstance3D = $Visual/ArmL
@onready var arm_r: MeshInstance3D = $Visual/ArmR
@onready var leg_l: Node3D = $Visual/LegLPivot
@onready var leg_r: Node3D = $Visual/LegRPivot
@onready var head: MeshInstance3D = $Visual/Head
@onready var chest_plate: MeshInstance3D = $Visual/ChestPlate
@onready var shoulder_l: MeshInstance3D = $Visual/ShoulderL
@onready var shoulder_r: MeshInstance3D = $Visual/ShoulderR
@onready var weapon_mesh: MeshInstance3D = $Visual/Weapon
@onready var back_unit: MeshInstance3D = $Visual/BackUnit
@onready var eye_l: MeshInstance3D = $Visual/EyeL
@onready var eye_r: MeshInstance3D = $Visual/EyeR
@onready var core_light: OmniLight3D = $Visual/CoreLight

func _ready() -> void:
    visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    add_to_group("enemies")
    floor_snap_length = 0.60
    floor_constant_speed = true
    health = max_health
    target = get_tree().get_first_node_in_group("player") as Node3D
    _rng.randomize()
    _visual_base_scale = visual.scale
    _visual_base_position = visual.position
    _apply_archetype_visuals()

func setup(archetype: int, elite_kind: int, difficulty_scale: float = 1.0) -> void:
    enemy_type = archetype
    elite_type = elite_kind
    _configure_archetype()
    _apply_archetype_visuals()

    var diff: float = clampf(difficulty_scale, 1.0, 5.0)
    max_health *= 1.0 + (diff - 1.0) * 0.62
    move_speed *= minf(1.75, 1.0 + (diff - 1.0) * 0.10)
    touch_damage *= 1.0 + (diff - 1.0) * 0.42
    projectile_damage *= 1.0 + (diff - 1.0) * 0.40
    xp_reward = int(round(float(xp_reward) * (1.0 + (diff - 1.0) * 0.30)))
    credit_reward = int(round(float(credit_reward) * (1.0 + (diff - 1.0) * 0.18)))

    if elite_type == EliteType.OVERCHARGED:
        max_health *= 2.2
        move_speed *= 1.22
        touch_damage *= 1.55
        projectile_damage *= 1.55
        attack_interval *= 0.72
        xp_reward *= 3
        credit_reward *= 3
        scale *= 1.24
        _set_core_color(Color(0.72, 0.18, 1.0))
    elif elite_type == EliteType.VOLATILE:
        max_health *= 2.7
        touch_damage *= 1.35
        projectile_damage *= 1.30
        xp_reward *= 3
        credit_reward *= 4
        scale *= 1.30
        _set_core_color(Color(1.0, 0.38, 0.03))

    ACTOR_STYLE.apply(visual, false)
    _home_position = global_position
    health = max_health
    _visual_base_scale = visual.scale
    _visual_base_position = visual.position
    core_light.visible = elite_type != EliteType.NONE or enemy_type == EnemyType.BOMBER or enemy_type == EnemyType.TANK
    if _is_mobile_runtime() and core_light.visible:
        core_light.omni_range = 2.7
        core_light.light_energy = minf(core_light.light_energy, 1.35)

func _configure_archetype() -> void:
    var data: EnemyData = _get_archetype_data()
    if data == null:
        return

    move_speed = data.move_speed
    max_health = data.max_health
    touch_damage = data.touch_damage
    attack_interval = data.attack_interval
    projectile_damage = data.projectile_damage
    projectile_speed = data.projectile_speed
    preferred_range = data.preferred_range
    xp_reward = data.xp_reward
    credit_reward = data.credit_reward
    scale = Vector3.ONE * data.scale_multiplier
    visual_profile = clampi(data.visual_profile, VisualProfile.BIPED, VisualProfile.HEAVY)
    accent_color = data.accent_color
    stride_scale = data.stride_scale
    bob_amount = data.bob_amount
    attack_pose_scale = data.attack_pose_scale
    _set_core_color(data.core_color)
    _set_accent_color(accent_color)

func _get_archetype_data() -> EnemyData:
    if ENEMY_DATA.is_empty():
        return null
    var safe_index: int = clampi(enemy_type, 0, ENEMY_DATA.size() - 1)
    return ENEMY_DATA[safe_index] as EnemyData

func _physics_process(delta: float) -> void:
    if _death_started:
        return
    _move_delta = delta
    _attack_timer = maxf(0.0, _attack_timer - delta)
    _sight_timer -= delta
    _tactic_timer -= delta
    _stagger_timer = maxf(0.0, _stagger_timer - delta)
    _spawn_grace_timer = maxf(0.0, _spawn_grace_timer - delta)
    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player") as Node3D
        if target == null:
            return

    var to_player: Vector3 = target.global_position - global_position
    to_player.y = 0.0
    var distance: float = to_player.length()
    var dir: Vector3 = to_player.normalized() if distance > 0.001 else Vector3.ZERO

    if _sight_timer <= 0.0:
        _sight_timer = 0.16 + float(get_instance_id() % 5) * 0.015
        _target_visible = SIGHT.clear(get_world_3d(), _muzzle_origin(), target.global_position + Vector3.UP)

    # Ordinary enemies guard their area instead of following across the whole map.
    if target.global_position.distance_to(_home_position) > 52.0 and distance > 14.0:
        _cancel_windup()
        var return_vector: Vector3 = _home_position - global_position
        return_vector.y = 0.0
        var home_direction: Vector3 = _navigation.direction(self, _home_position, delta) if return_vector.length() > 1.4 else Vector3.ZERO
        velocity.x = move_toward(velocity.x, home_direction.x * move_speed, delta * 12.0)
        velocity.z = move_toward(velocity.z, home_direction.z * move_speed, delta * 12.0)
        velocity.y = velocity.y - _gravity * delta if not is_on_floor() else -0.2
        move_and_slide()
        _animate_motion(delta, distance)
        return

    if _spawn_grace_timer > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
        if not is_on_floor():
            velocity.y -= _gravity * delta
        else:
            velocity.y = -0.2
        move_and_slide()
        _attack_pulse = maxf(_attack_pulse, 0.18 + absf(sin(Time.get_ticks_msec() * 0.012)) * 0.22)
        _animate_motion(delta, distance)
        return

    if _pending_attack != PendingAttack.NONE:
        _process_attack_windup(delta, dir)
        if dir.length_squared() > 0.001:
            _face(_pending_direction, delta)
        if not is_on_floor():
            velocity.y -= _gravity * delta
        else:
            velocity.y = -0.2
        move_and_slide()
        _animate_motion(delta, distance)
        return

    if _stagger_timer > 0.0:
        velocity.x = _stagger_velocity.x
        velocity.z = _stagger_velocity.z
        _stagger_velocity = _stagger_velocity.move_toward(Vector3.ZERO, 18.0 * delta)
        if not is_on_floor():
            velocity.y -= _gravity * delta
        else:
            velocity.y = -0.2
        move_and_slide()
        _animate_motion(delta, distance)
        return

    match enemy_type:
        EnemyType.GUNNER, EnemyType.TANK:
            _ranged_behavior(dir, distance)
        EnemyType.BOMBER:
            _bomber_behavior(dir, distance)
        _:
            _melee_behavior(dir, distance)

    if dir.length_squared() > 0.001:
        _face(dir, delta)

    if not is_on_floor():
        velocity.y -= _gravity * delta
    else:
        velocity.y = -0.2
    move_and_slide()
    _animate_motion(delta, distance)


func _animate_motion(delta: float, distance_to_target: float) -> void:
    _anim_time += delta
    _attack_pulse = move_toward(_attack_pulse, 0.0, delta * 5.5)
    _hit_pulse = move_toward(_hit_pulse, 0.0, delta * 8.0)

    var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
    var speed_ratio: float = clampf(horizontal_speed / maxf(0.1, move_speed), 0.0, 1.4)
    var cycle_speed: float = 6.0 + move_speed * 0.95
    var stride: float = sin(_anim_time * cycle_speed) * speed_ratio
    var response: float = clampf(delta * 12.0, 0.0, 1.0)

    var bob: float = absf(cos(_anim_time * cycle_speed)) * bob_amount * speed_ratio
    visual.position.y = lerpf(visual.position.y, _visual_base_position.y + bob, response)

    var limb_scale: float = stride_scale
    leg_l.rotation.x = lerp_angle(leg_l.rotation.x, stride * limb_scale, response)
    leg_r.rotation.x = lerp_angle(leg_r.rotation.x, -stride * limb_scale, response)
    var attack_l: float = -_attack_pulse * 0.42 * attack_pose_scale
    var attack_r: float = -_attack_pulse * 0.58 * attack_pose_scale
    if enemy_type == EnemyType.GUNNER:
        attack_l = -0.34 - _attack_pulse * 0.25 * attack_pose_scale
        attack_r = -0.82 - _attack_pulse * 0.52 * attack_pose_scale
    elif enemy_type == EnemyType.TANK:
        attack_l = -0.48 - _attack_pulse * 0.44 * attack_pose_scale
        attack_r = -0.72 - _attack_pulse * 0.62 * attack_pose_scale
    elif enemy_type == EnemyType.SKITTER:
        attack_l = -_attack_pulse * 0.95 * attack_pose_scale
        attack_r = -_attack_pulse * 0.88 * attack_pose_scale
    arm_l.rotation.x = lerp_angle(arm_l.rotation.x, -stride * limb_scale * 0.82 + attack_l, response)
    arm_r.rotation.x = lerp_angle(arm_r.rotation.x, stride * limb_scale * 0.82 + attack_r, response)
    if weapon_mesh.visible:
        weapon_mesh.position.z = lerpf(weapon_mesh.position.z, -0.42 + _attack_pulse * 0.16, response)

    var target_lean: float = -0.10 * speed_ratio - _attack_pulse * 0.10
    visual.rotation.x = lerp_angle(visual.rotation.x, target_lean, response)
    visual.rotation.z = lerp_angle(visual.rotation.z, sin(_anim_time * 28.0) * 0.025 * _hit_pulse, response)
    head.rotation.y = lerp_angle(head.rotation.y, sin(_anim_time * 1.7) * 0.06, response)

    if enemy_type == EnemyType.BOMBER and distance_to_target < 7.0:
        var danger: float = clampf(1.0 - distance_to_target / 7.0, 0.0, 1.0)
        var pulse: float = 1.0 + absf(sin(_anim_time * (8.0 + danger * 11.0))) * 0.42 * danger
        core.scale = Vector3.ONE * pulse
    else:
        var hit_scale: float = 1.0 + _hit_pulse * 0.12
        core.scale = core.scale.lerp(Vector3.ONE * hit_scale, response)

func _move_toward_goal(goal: Vector3, speed_scale: float = 1.0) -> void:
    var heading: Vector3 = _navigation.direction(self, goal, _move_delta)
    velocity.x = move_toward(velocity.x, heading.x * move_speed * speed_scale, 16.0 * _move_delta)
    velocity.z = move_toward(velocity.z, heading.z * move_speed * speed_scale, 16.0 * _move_delta)

func _melee_behavior(dir: Vector3, distance: float) -> void:
    if distance > 1.65 or not _target_visible:
        _move_toward_goal(target.global_position)
    else:
        velocity.x = 0.0
        velocity.z = 0.0
        if _attack_timer <= 0.0 and target.has_method("take_damage"):
            _begin_melee_windup(dir)

func _ranged_behavior(dir: Vector3, distance: float) -> void:
    if not _target_visible or distance > preferred_range + 2.0:
        _move_toward_goal(target.global_position)
    else:
        if _tactic_timer <= 0.0:
            _tactic_timer = 1.2 + float(get_instance_id() % 5) * 0.12
            var side: float = -1.0 if get_instance_id() % 2 == 0 else 1.0
            var tangent: Vector3 = Vector3(-dir.z, 0.0, dir.x) * side
            if distance < preferred_range - 3.0:
                _tactic_goal = global_position - dir * 4.0 + tangent
            elif enemy_type == EnemyType.GUNNER:
                _tactic_goal = global_position + tangent * 2.8
            else:
                _tactic_goal = global_position
        _move_toward_goal(_tactic_goal, 0.60)
    if _target_visible and distance <= preferred_range + 5.0 and _attack_timer <= 0.0:
        _begin_ranged_windup(dir)

func _bomber_behavior(_dir: Vector3, distance: float) -> void:
    _move_toward_goal(target.global_position)
    if _target_visible and distance < 2.8 and _attack_timer <= 0.0:
        _begin_bomber_windup()

func _face(dir: Vector3, delta: float) -> void:
    if Vector2(dir.x, dir.z).length_squared() > 0.0001:
        var yaw: float = atan2(-dir.x, -dir.z)
        rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-10.0 * delta))

func _muzzle_origin() -> Vector3:
    return global_position + Vector3.UP * (1.15 * scale.y)

func _begin_melee_windup(dir: Vector3) -> void:
    _attack_timer = attack_interval
    _pending_attack = PendingAttack.MELEE
    _pending_direction = dir
    _windup_timer = 0.24 if enemy_type == EnemyType.SKITTER else 0.38
    _attack_pulse = 0.58
    velocity.x = 0.0
    velocity.z = 0.0
    _attack_cue = TELEGRAPH.sector(get_tree().current_scene, global_position, dir, 2.25, _windup_timer, Color(1.0, 0.40, 0.10))

func _begin_ranged_windup(dir: Vector3) -> void:
    _attack_timer = attack_interval
    _pending_attack = PendingAttack.TANK_BURST if enemy_type == EnemyType.TANK else PendingAttack.RANGED
    _pending_direction = dir
    _windup_timer = 0.70 if enemy_type == EnemyType.TANK else 0.48
    _attack_pulse = 0.62
    if is_instance_valid(target):
        _pending_aim_point = target.global_position + Vector3.UP
        _pending_direction = (_pending_aim_point - _muzzle_origin()).normalized()
        velocity.x = 0.0
        velocity.z = 0.0
        _attack_cue = TELEGRAPH.beam(get_tree().current_scene, _muzzle_origin(), _pending_aim_point, _windup_timer, Color(1.0, 0.36, 0.08))

func _begin_bomber_windup() -> void:
    _attack_timer = 2.0
    _pending_attack = PendingAttack.BOMBER_DETONATE
    _windup_timer = 0.80
    _attack_pulse = 1.0
    velocity.x = 0.0
    velocity.z = 0.0
    _attack_cue = TELEGRAPH.ring(get_tree().current_scene, global_position, 4.4, _windup_timer, Color(1.0, 0.36, 0.03), 22)
    TELEGRAPH.marker(_attack_cue, global_position, "!! OVERLOAD !!", _windup_timer, Color(1.0, 0.46, 0.08))

func _process_attack_windup(delta: float, _dir: Vector3) -> void:
    velocity.x = move_toward(velocity.x, 0.0, 22.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, 22.0 * delta)
    # The warning is a commitment, not a homing reticle. Do not re-aim here.
    _windup_timer = maxf(0.0, _windup_timer - delta)
    _attack_pulse = maxf(_attack_pulse, 0.55 + absf(sin(Time.get_ticks_msec() * 0.018)) * 0.42)
    if _windup_timer > 0.0:
        return
    _execute_pending_attack()

func _execute_pending_attack() -> void:
    var attack: int = _pending_attack
    _pending_attack = PendingAttack.NONE
    _windup_timer = 0.0
    _clear_cue()
    _attack_timer = maxf(_attack_timer, attack_interval)
    if not is_instance_valid(target):
        return

    match attack:
        PendingAttack.MELEE:
            if target.has_method("take_damage") and SIGHT.melee(get_world_3d(), global_position, target.global_position, _pending_direction):
                _attack_pulse = 1.35
                ASCII_FX.melee_slash(get_tree().current_scene, global_position, _get_core_color(), _pending_direction)
                target.call("take_damage", touch_damage)
        PendingAttack.RANGED:
            _attack_pulse = 1.0
            _fire_projectile()
        PendingAttack.TANK_BURST:
            _attack_pulse = 1.2
            _fire_projectile()
            var tangent: Vector3 = _pending_direction.rotated(Vector3.UP, deg_to_rad(9.0))
            _spawn_projectile(tangent, projectile_damage * 0.8)
            tangent = _pending_direction.rotated(Vector3.UP, deg_to_rad(-9.0))
            _spawn_projectile(tangent, projectile_damage * 0.8)
        PendingAttack.BOMBER_DETONATE:
            _explode_bomber()
        _:
            pass

func _cancel_windup() -> void:
    _pending_attack = PendingAttack.NONE
    _windup_timer = 0.0
    _clear_cue()

func _clear_cue() -> void:
    if is_instance_valid(_attack_cue):
        _attack_cue.queue_free()
    _attack_cue = null

func _exit_tree() -> void:
    _clear_cue()

func _fire_projectile() -> void:
    if not SIGHT.clear(get_world_3d(), _muzzle_origin(), _pending_aim_point):
        return
    var dir: Vector3 = (_pending_aim_point - _muzzle_origin()).normalized()
    _spawn_projectile(dir, projectile_damage)

func _spawn_projectile(dir: Vector3, dmg: float) -> void:
    var origin: Vector3 = _muzzle_origin()
    if not SIGHT.clear(get_world_3d(), origin, origin + dir.normalized() * 0.45):
        return
    _fired_shots += 1
    var projectile_node: Node = PoolManager.spawn(PROJECTILE_SCENE, get_tree().current_scene)
    var projectile: Node3D = projectile_node as Node3D
    if projectile == null:
        return
    projectile.global_position = origin
    var color: Color = Color(0.78, 0.18, 1.0) if elite_type == EliteType.OVERCHARGED else Color(1.0, 0.08, 0.025)
    projectile.call("setup", dir, projectile_speed, dmg, color)

func _explode_bomber() -> void:
    if _death_started:
        return
    _death_started = true
    _cancel_windup()
    if is_instance_valid(target) and target.has_method("take_damage"):
        var d: float = target.global_position.distance_to(global_position)
        if d <= 4.4 and SIGHT.clear(get_world_3d(), global_position + Vector3.UP, target.global_position + Vector3.UP):
            var falloff: float = clampf(1.0 - d / 5.2, 0.25, 1.0)
            target.call("take_damage", touch_damage * falloff)
    ASCII_FX.burst(get_tree().current_scene, global_position + Vector3.UP, Color(1.0, 0.40, 0.03), 18, 4.4)
    GameEvents.emit_enemy_killed(self, xp_reward, credit_reward)
    died.emit(self, xp_reward, credit_reward)
    queue_free()

func apply_stagger(power: float, source_position: Vector3) -> void:
    if _death_started or health <= 0.0:
        return
    var resistance: float = 1.0
    if enemy_type == EnemyType.TANK:
        resistance = 0.42
    elif elite_type != EliteType.NONE:
        resistance = 0.62
    var effective: float = maxf(0.0, power * resistance)
    if effective <= 0.02:
        return
    _stagger_timer = maxf(_stagger_timer, 0.055 + effective * 0.13)
    if effective >= 0.18:
        _cancel_windup()
    var knock_dir: Vector3 = global_position - source_position
    knock_dir.y = 0.0
    if knock_dir.length_squared() < 0.001:
        knock_dir = Vector3.BACK
    knock_dir = knock_dir.normalized()
    _stagger_velocity = knock_dir * (2.8 + effective * 5.2)
    _hit_pulse = maxf(_hit_pulse, 0.75)

func _apply_archetype_visuals() -> void:
    if not is_instance_valid(chest_plate):
        return
    shoulder_l.visible = true
    shoulder_r.visible = true
    weapon_mesh.visible = false
    back_unit.visible = true
    chest_plate.visible = true
    head.scale = Vector3.ONE
    shoulder_l.scale = Vector3.ONE
    shoulder_r.scale = Vector3.ONE
    weapon_mesh.scale = Vector3.ONE
    back_unit.scale = Vector3.ONE

    match visual_profile:
        VisualProfile.LOW:
            shoulder_l.visible = false
            shoulder_r.visible = false
            back_unit.visible = false
            head.scale = Vector3(0.82, 0.72, 0.88)
            chest_plate.scale = Vector3(0.72, 0.72, 0.75)
        VisualProfile.RANGED:
            weapon_mesh.visible = true
            shoulder_l.scale = Vector3(0.85, 0.85, 1.15)
            shoulder_r.scale = Vector3(1.15, 0.95, 1.28)
            back_unit.scale = Vector3(0.82, 1.15, 0.92)
        VisualProfile.CARRIER:
            shoulder_l.visible = false
            shoulder_r.visible = false
            back_unit.scale = Vector3(1.35, 1.25, 1.45)
            chest_plate.scale = Vector3(1.05, 1.18, 1.0)
        VisualProfile.HEAVY:
            weapon_mesh.visible = true
            weapon_mesh.scale = Vector3(1.5, 1.3, 1.45)
            shoulder_l.scale = Vector3(1.35, 1.25, 1.42)
            shoulder_r.scale = Vector3(1.35, 1.25, 1.42)
            chest_plate.scale = Vector3(1.28, 1.25, 1.18)
            back_unit.scale = Vector3(1.25, 1.30, 1.35)
        _:
            pass

func _get_core_color() -> Color:
    if elite_type == EliteType.OVERCHARGED:
        return Color(0.72, 0.18, 1.0)
    if elite_type == EliteType.VOLATILE:
        return Color(1.0, 0.38, 0.03)
    var data: EnemyData = _get_archetype_data()
    return data.core_color if data != null else Color(1.0, 0.04, 0.02)

func take_damage(amount: float) -> void:
    if health <= 0.0 or _death_started:
        return
    health -= amount
    _hit_pulse = 1.0
    _hit_flash()
    if health <= 0.0:
        _die()

func _die() -> void:
    if _death_started:
        return
    _death_started = true
    _cancel_windup()

    if elite_type == EliteType.VOLATILE:
        var blast: Node3D = DELAYED_BLAST.new() as Node3D
        blast.call("arm", get_tree().current_scene, global_position)


    var color: Color = Color(1.0, 0.16, 0.03)
    if elite_type == EliteType.OVERCHARGED:
        color = Color(0.75, 0.20, 1.0)
    elif elite_type == EliteType.VOLATILE:
        color = Color(1.0, 0.42, 0.03)
    ASCII_FX.burst(get_tree().current_scene, global_position + Vector3.UP, color, 22 if elite_type != EliteType.NONE else 11, 4.3 if elite_type != EliteType.NONE else 2.8)
    GameEvents.emit_enemy_killed(self, xp_reward, credit_reward)
    died.emit(self, xp_reward, credit_reward)
    queue_free()

func get_health_ratio() -> float:
    if max_health <= 0.0:
        return 0.0
    return health / max_health

func _set_core_color(color: Color) -> void:
    if core == null:
        return
    var mat: StandardMaterial3D = core.material_override as StandardMaterial3D
    if mat != null:
        mat = mat.duplicate()
        mat.albedo_color = color
        mat.emission = color
        mat.emission_energy_multiplier = 6.8
        core.material_override = mat
        if is_instance_valid(eye_l):
            eye_l.material_override = mat
        if is_instance_valid(eye_r):
            eye_r.material_override = mat
        if is_instance_valid(core_light):
            core_light.light_color = color
            core_light.light_energy = 1.45 if elite_type == EliteType.NONE else 2.25
            _core_base_energy = core_light.light_energy

func _set_accent_color(color: Color) -> void:
    _tint_accent_mesh(chest_plate, color)
    _tint_accent_mesh(shoulder_l, color)
    _tint_accent_mesh(shoulder_r, color)
    _tint_accent_mesh(weapon_mesh, color)
    _tint_accent_mesh(back_unit, color)

func _tint_accent_mesh(mesh: MeshInstance3D, color: Color) -> void:
    if not is_instance_valid(mesh):
        return
    var source: StandardMaterial3D = mesh.material_override as StandardMaterial3D
    if source == null:
        return
    var material: StandardMaterial3D = source.duplicate() as StandardMaterial3D
    material.albedo_color = color
    mesh.material_override = material

func _is_mobile_runtime() -> bool:
    return RuntimeProfile.is_mobile

func _hit_flash() -> void:
    if not is_instance_valid(visual):
        return
    var tween: Tween = create_tween()
    tween.tween_property(visual, "scale", _visual_base_scale * 1.08, 0.035)
    tween.tween_property(visual, "scale", _visual_base_scale, 0.07)
    var core_material: StandardMaterial3D = core.material_override as StandardMaterial3D
    if core_material != null:
        var core_tween: Tween = create_tween()
        core_tween.set_parallel(true)
        core_tween.tween_property(core_material, "emission", Color(1.0, 0.72, 0.32), 0.02)
        core_tween.tween_property(core_light, "light_energy", _core_base_energy * 1.8, 0.02)
        core_tween.chain()
        core_tween.tween_property(core_material, "emission", _get_core_color(), 0.10)
        core_tween.tween_property(core_light, "light_energy", _core_base_energy, 0.10)
