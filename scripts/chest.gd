extends Node3D

@export var cost = 25
@export var starter_cache: bool = false
var cached_offer: Array[StringName] = []
var opened = false

@onready var lid: Node3D = $Lid
@onready var core: MeshInstance3D = $Core
@onready var core_light: OmniLight3D = $CoreLight

func _ready() -> void:
    add_to_group("interactables")

func get_interaction_text(player: Node) -> String:
    if opened:
        return ""
    var credits = 0
    if player != null and player.has_method("get_credits"):
        credits = int(player.call("get_credits"))
    if starter_cache:
        return "[E / USE] STARTER CACHE // FREE // CHOOSE ONE RELIC"
    return "[E / USE] OPEN CACHE   %d¢   /   %d¢" % [cost, credits]

func interact(player: Node) -> void:
    if opened or player == null:
        return
    var scene: Node = get_tree().current_scene
    if scene != null and scene.has_method("open_relic_choice"):
        scene.call("open_relic_choice", self, player, cost, starter_cache)
        return
    # Training/other scenes without a run UI retain a safe fallback.
    if not player.has_method("spend_credits") or not bool(player.call("spend_credits", cost)):
        if player.has_method("announce"):
            player.call("announce", "INSUFFICIENT CREDITS")
        return
    var received: String = String(player.call("grant_random_item"))
    if received.is_empty():
        player.call("add_credits", cost)
        return
    complete_open()

func complete_open() -> void:
    if opened:
        return
    opened = true
    remove_from_group("interactables")
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(lid, "rotation:x", -1.25, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(core, "scale", Vector3.ONE * 2.2, 0.18)
    tween.tween_property(core_light, "light_energy", 0.0, 0.25)
    tween.set_parallel(false)
    tween.tween_property(core, "scale", Vector3.ZERO, 0.20)
