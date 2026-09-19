extends Node3D
## Binds Entity 01's visual clips to the existing player without changing gameplay.

@onready var _player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var _entity_visual: RainEntityVisual = $Entity01Visual as RainEntityVisual

var _previous_dash_timer: float = 0.0
var _previous_shot_timer: float = 0.0
var _was_on_floor: bool = true

func _ready() -> void:
    var legacy_body: Node3D = _player.get_node_or_null("Visual/BodyRoot") as Node3D
    if legacy_body != null:
        legacy_body.visible = false
    _entity_visual.set_lite_profile(RuntimeProfile.is_mobile)
    if _player.has_signal("damaged"):
        _player.connect("damaged", _on_player_damaged)
    if _player.has_signal("died"):
        _player.connect("died", _on_player_died)
    GameEvents.reality_fragment_found.connect(_on_reality_fragment_found)
    _entity_visual.clip_finished.connect(_on_entity_clip_finished)

func _process(_delta: float) -> void:
    if not is_instance_valid(_player) or not is_instance_valid(_entity_visual):
        return
    var horizontal_velocity: Vector3 = Vector3(_player.velocity.x, 0.0, _player.velocity.z)
    var on_floor: bool = _player.is_on_floor()
    _entity_visual.set_moving(horizontal_velocity.length() > 0.15 or not on_floor)
    if _was_on_floor and not on_floor and _player.velocity.y > 0.0:
        _on_jump_started()
    _was_on_floor = on_floor

    var dash_timer: float = float(_player.get("_dash_timer"))
    if dash_timer > 0.0 and _previous_dash_timer <= 0.0:
        _entity_visual.play_clip(&"Dash", 0.04)
    _previous_dash_timer = dash_timer

    var shot_timer: float = float(_player.get("_shot_timer"))
    if shot_timer > 0.0 and _previous_shot_timer <= 0.0:
        _entity_visual.play_clip(&"Cast_Pulse", 0.08)
    _previous_shot_timer = shot_timer

func _on_jump_started() -> void:
    # The supplied model has no Jump clip; its flight loop is the airborne pose.
    _entity_visual.play_clip(&"Glide_Loop", 0.06)

func _on_reality_fragment_found(_fragment_id: StringName) -> void:
    _entity_visual.play_clip(&"Human_Echo", 0.08)

func _on_entity_clip_finished(clip_name: StringName) -> void:
    if clip_name == &"Human_Echo":
        _entity_visual.call_deferred("play_clip", &"Reconstruct", 0.08)

func _on_player_damaged(_amount: float) -> void:
    _entity_visual.play_clip(&"Hit_Recoil", 0.05)

func _on_player_died() -> void:
    _entity_visual.play_clip(&"Dissolve", 0.08)
