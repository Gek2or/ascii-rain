extends SceneTree

const NAV = preload("res://world/navigation/street_navigation.gd")
const ENEMY: PackedScene = preload("res://scenes/Enemy.tscn")
const BULLET: PackedScene = preload("res://scenes/EnemyProjectile.tscn")
const BLAST = preload("res://components/combat/delayed_blast.gd")
const SIGHT = preload("res://components/combat/combat_sight.gd")
var checks: int = 0
var failures: Array[String] = []
var host: Node3D = null
var nav: StreetNavigation = null
var victim: TestVictim = null
var blocker: StaticBody3D = null

class TestVictim extends CharacterBody3D:
    var health: float = 10000.0
    func take_damage(amount: float) -> void:
        health -= amount

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        print("TACTICS_FAIL: ", label)

func _box(point: Vector3, size: Vector3, angle: float = 0.0) -> StaticBody3D:
    var body: StaticBody3D = StaticBody3D.new()
    body.position = point
    body.rotation.x = angle
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    host.add_child(body)
    return body

func _robot(kind: int, point: Vector3, elite: int = 0) -> CharacterBody3D:
    var enemy: CharacterBody3D = ENEMY.instantiate() as CharacterBody3D
    host.add_child(enemy)
    enemy.global_position = point
    enemy.call("setup", kind, elite, 1.0)
    enemy.set("_spawn_grace_timer", 0.0)
    return enemy

func _clear_shots() -> void:
    for shot in get_nodes_in_group("hostile_projectiles"):
        shot.call("_request_recycle")

func _run() -> void:
    host = Node3D.new()
    root.add_child(host)
    current_scene = host
    _box(Vector3(0, -0.25, 0), Vector3(60, 0.5, 60))
    blocker = _box(Vector3(0, 2, 0), Vector3(8, 4, 1.0))
    _box(Vector3(15, 2, 0), Vector3(4, 0.25, 10))
    _box(Vector3(15, 1, 8), Vector3(4, 0.25, sqrt(40.0)), atan2(2.0, 6.0))
    _box(Vector3(15, 1, -8), Vector3(4, 0.25, sqrt(40.0)), -atan2(2.0, 6.0))
    victim = TestVictim.new()
    victim.collision_layer = 2
    victim.collision_mask = 1
    var shape: CapsuleShape3D = CapsuleShape3D.new()
    shape.radius = 0.40
    shape.height = 1.8
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    collision.position = Vector3.UP
    victim.add_child(collision)
    host.add_child(victim)
    victim.add_to_group("player")
    victim.global_position = Vector3(0, 0, -9)
    nav = NAV.new() as StreetNavigation
    nav.half_extent = 25.0
    host.add_child(nav)
    for frame in range(200):
        await physics_frame
        if nav.built:
            break
    _expect(nav.built, "bounded graph finishes building")
    _expect(nav.graph.get_point_count() > 200, "physics sampling finds street nodes")
    _expect(not nav.can_travel(Vector3(0, 0, 9), victim.global_position), "wall prevents straight shortcut")
    var route: Dictionary = nav.request_route(Vector3(0, 0, 9), victim.global_position)
    _expect(route["status"] == "ok", "AStar route exists around wall")
    var path: PackedVector3Array = route.get("path", PackedVector3Array())
    var side_extent: float = 0.0
    var all_clear: bool = true
    for index in range(path.size()):
        side_extent = maxf(side_extent, absf(path[index].x))
        if index > 0:
            all_clear = all_clear and nav.can_travel(path[index - 1], path[index])
    _expect(side_extent > 5.0, "route goes outside wall plus clearance")
    _expect(all_clear, "every returned edge has clearance/support")
    _expect(not nav.spawn_anchor(Vector3(0, 0, 15), victim.global_position).is_empty(), "spawn has connected reachable floor")
    _expect(nav.spawn_anchor(Vector3(0, 0, -8), victim.global_position).is_empty(), "spawn cannot snap onto player")
    await physics_frame
    var busy: int = 0
    for index in range(8):
        if nav.request_route(Vector3(0, 0, 9), victim.global_position)["status"] == "busy":
            busy += 1
    _expect(busy >= 4, "shared per-frame AStar request cap")

    var chaser: CharacterBody3D = _robot(0, Vector3(0, 0.08, 9))
    var observed_detour: float = 0.0
    for frame in range(780):
        await physics_frame
        observed_detour = maxf(observed_detour, absf(chaser.global_position.x))
        if chaser.global_position.distance_to(victim.global_position) < 2.2:
            break
    print("NAV_WALL: final=", chaser.global_position, " detour=", observed_detour)
    _expect(observed_detour > 5.0, "real CharacterBody detours instead of sliding into wall")
    _expect(chaser.global_position.distance_to(victim.global_position) < 2.8, "real CharacterBody arrives on far side")
    chaser.queue_free()
    await physics_frame

    victim.global_position = Vector3(15, 2.13, 0)
    var climber: CharacterBody3D = _robot(0, Vector3(15, 0.08, 14))
    for frame in range(620):
        await physics_frame
        if climber.global_position.y > 2.0 and climber.global_position.distance_to(victim.global_position) < 2.5:
            break
    print("NAV_RAMP: final=", climber.global_position)
    _expect(climber.global_position.y > 2.0, "real CharacterBody reaches raised deck via ramp")
    _expect(climber.global_position.distance_to(victim.global_position) < 3.0, "climber does not attack beneath deck")
    climber.queue_free()
    await physics_frame

    victim.global_position = Vector3(0, 0, -5)
    var gunner: CharacterBody3D = _robot(2, Vector3(0, 0.08, 5))
    for frame in range(30):
        await physics_frame
    _expect(int(gunner.get("_fired_shots")) == 0, "occluded gunner does not start firing")
    gunner.set_physics_process(false)
    gunner.call("_cancel_windup")
    gunner.global_position = Vector3(-12, 0.05, 8)
    victim.global_position = Vector3(-12, 0.05, 0)
    await physics_frame
    gunner.call("_begin_ranged_windup", Vector3.FORWARD)
    var locked: Vector3 = gunner.get("_pending_aim_point")
    var cue: Node3D = gunner.get("_attack_cue") as Node3D
    _expect(is_instance_valid(cue), "windup owns visible cue handle")
    victim.global_position.x += 4.0
    gunner.call("_process_attack_windup", 0.10, Vector3.RIGHT)
    _expect(locked.is_equal_approx(gunner.get("_pending_aim_point")), "warning locks shot point, not homing")
    gunner.call("_process_attack_windup", 0.8, Vector3.RIGHT)
    var shots: Array[Node] = get_nodes_in_group("hostile_projectiles")
    _expect(shots.size() == 1, "single committed shot emitted")
    if shots.size() == 1:
        var expected: Vector3 = (locked - (gunner.call("_muzzle_origin") as Vector3)).normalized()
        _expect(expected.is_equal_approx(shots[0].get("direction")), "shot uses exact advertised direction")
    _expect(is_instance_valid(cue) and cue.is_queued_for_deletion(), "release removes cue")
    _expect(float(gunner.get("_attack_timer")) >= float(gunner.get("attack_interval")), "post-release recovery window")
    _clear_shots()
    gunner.call("_begin_ranged_windup", Vector3.FORWARD)
    cue = gunner.get("_attack_cue") as Node3D
    gunner.call("apply_stagger", 1.0, gunner.global_position + Vector3.FORWARD)
    _expect(int(gunner.get("_pending_attack")) == 0, "stagger cancels pending attack")
    _expect(cue.is_queued_for_deletion(), "stagger removes warning, no ghost cue")
    gunner.queue_free()
    await physics_frame

    var melee_enemy: CharacterBody3D = _robot(0, Vector3(-12, 0, 4))
    melee_enemy.set_physics_process(false)
    victim.global_position = melee_enemy.global_position + Vector3(1.9, 0, 0)
    var hp: float = victim.health
    melee_enemy.call("_begin_melee_windup", Vector3.FORWARD)
    melee_enemy.call("_execute_pending_attack")
    _expect(is_equal_approx(hp, victim.health), "sidestep out of advertised melee sector dodges")
    victim.global_position = melee_enemy.global_position + Vector3.FORWARD * 1.3
    melee_enemy.call("_begin_melee_windup", Vector3.FORWARD)
    melee_enemy.call("_execute_pending_attack")
    _expect(victim.health < hp, "inside-sector melee still hits")
    hp = victim.health
    melee_enemy.global_position = Vector3(0, 0, 0.9)
    victim.global_position = Vector3(0, 0, -0.9)
    await physics_frame
    melee_enemy.call("_begin_melee_windup", Vector3.FORWARD)
    melee_enemy.call("_execute_pending_attack")
    _expect(is_equal_approx(hp, victim.health), "melee cannot damage through wall")
    _expect(not SIGHT.melee(host.get_world_3d(), Vector3.ZERO, Vector3(0, 2.5, -1), Vector3.FORWARD), "melee height separation respected")
    melee_enemy.queue_free()
    await physics_frame

    var bomber: CharacterBody3D = _robot(3, Vector3(0, 0, 1.1))
    bomber.set_physics_process(false)
    victim.global_position = Vector3(0, 0, -1.1)
    hp = victim.health
    bomber.call("_explode_bomber")
    _expect(is_equal_approx(hp, victim.health), "bomber blast blocked by cover")
    await physics_frame
    var volatile_enemy: CharacterBody3D = _robot(0, Vector3(-14, 0, 0), 2)
    volatile_enemy.set_physics_process(false)
    victim.global_position = Vector3(-14, 0, 2)
    hp = victim.health
    volatile_enemy.call("take_damage", 999999.0)
    _expect(is_equal_approx(hp, victim.health), "volatile death no longer deals instant damage")
    _expect(get_nodes_in_group("hostile_hazards").size() == 1, "volatile creates one delayed hazard")
    var hazard: Node = get_nodes_in_group("hostile_hazards")[0]
    hazard.call("_physics_process", 0.20)
    _expect(is_equal_approx(hp, victim.health), "warning interval is harmless")
    paused = true
    var remaining: float = float(hazard.get("remaining"))
    for frame in range(4):
        await process_frame
    _expect(is_equal_approx(remaining, float(hazard.get("remaining"))), "hazard freezes with pause")
    paused = false
    hazard.call("_physics_process", 1.0)
    _expect(victim.health < hp, "delayed blast deals damage after warning")
    await physics_frame
    _expect(get_nodes_in_group("hostile_hazards").is_empty(), "spent hazard freed")

    hp = victim.health
    victim.global_position = Vector3(-20, 0, -5)
    var thin_wall: StaticBody3D = _box(Vector3(-20, 1, 0), Vector3(3, 2, 0.04))
    for frame in range(3):
        await physics_frame
    var projectile: Node3D = root.get_node("PoolManager").call("spawn", BULLET, host) as Node3D
    projectile.global_position = Vector3(-20, 1, 4)
    projectile.call("setup", Vector3.FORWARD, 1000.0, 19.0)
    projectile.call("_physics_process", 0.016)
    _expect(bool(projectile.get("_recycle_requested")), "1000m/s projectile stops on 4cm wall")
    _expect(projectile.global_position.z > -0.05, "projectile does not teleport beyond cover")
    _expect(is_equal_approx(hp, victim.health), "thin cover protects victim")
    await physics_frame
    thin_wall.queue_free()
    for frame in range(3):
        await physics_frame
    projectile = root.get_node("PoolManager").call("spawn", BULLET, host) as Node3D
    projectile.global_position = Vector3(-20, 1, 4)
    projectile.call("setup", Vector3.FORWARD, 1000.0, 19.0)
    projectile.call("_physics_process", 0.016)
    projectile.call("_on_body_entered", victim)
    _expect(is_equal_approx(hp - victim.health, 19.0), "swept hit plus overlap deals damage exactly once")
    _expect(bool(projectile.get("_recycle_requested")), "pooled projectile can hit on reuse")
    await physics_frame
    print("ENCOUNTER_TACTICS_NATIVE: ", checks, " checks / ", failures.size(), " failures")
    root.get_node("AudioManager").call("stop_all")
    root.get_node("AudioManager/DistrictMusic").stream = null
    root.get_node("PoolManager").call("clear_all")
    host.queue_free()
    for frame in range(8):
        await physics_frame
    await create_timer(0.35, true, false, true).timeout
    quit(0 if failures.is_empty() else 1)
