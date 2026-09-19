extends Node3D

const CUES = preload("res://components/combat_telegraph.gd")
const SIGHT = preload("res://components/combat/combat_sight.gd")
const FX = preload("res://scripts/ascii_fx.gd")
var label_text: String = "VOLATILE // EVADE"
var remaining: float = 0.85
var radius: float = 5.5
var damage: float = 22.0
var tint: Color = Color(1.0, 0.42, 0.03)
var cue: Node3D = null

func arm(host: Node, feet: Vector3) -> void:
    host.add_child(self)
    global_position = feet
    add_to_group("hostile_hazards")
    cue = CUES.ring(host, feet, radius, remaining, tint, 24)
    CUES.marker(self, feet, label_text, remaining, tint)

func _physics_process(delta: float) -> void:
    remaining = maxf(0.0, remaining - delta)
    if remaining > 0.0:
        return
    set_physics_process(false)
    var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
    if player != null and player.has_method("take_damage"):
        var distance: float = player.global_position.distance_to(global_position)
        if distance < radius and SIGHT.clear(get_world_3d(), global_position + Vector3.UP, player.global_position + Vector3.UP):
            player.call("take_damage", damage * clampf(1.0 - distance / 7.0, 0.25, 1.0))
    FX.burst(get_tree().current_scene, global_position + Vector3.UP, tint, 14, radius)
    cancel()

func cancel() -> void:
    set_physics_process(false)
    if is_instance_valid(cue):
        cue.queue_free()
    queue_free()

func _exit_tree() -> void:
    if is_instance_valid(cue) and not cue.is_queued_for_deletion():
        cue.queue_free()
