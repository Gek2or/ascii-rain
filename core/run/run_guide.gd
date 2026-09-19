extends Node

const PROGRESS = preload("res://core/run/run_progress.gd")
const MARKER = preload("res://ui/objective_marker.gd")
var progress: RunProgress = PROGRESS.new() as RunProgress
var _game: Node = null
var _actor: Node3D = null
var _portal: Node3D = null
var _starter: Node3D = null
var _objective: Label = null
var _marker: Control = null
var _timer: float = 0.0

func configure(game: Node, actor: Node3D, portal: Node3D, starter: Node3D) -> void:
    _game = game
    _actor = actor
    _portal = portal
    _starter = starter
    _objective = game.get_node("HUD/Objective") as Label
    var story: Node = get_tree().get_first_node_in_group("story_director")
    var known: bool = story != null and bool(story.call("has_fragment", "memory_02"))
    progress.reset(known)
    _marker = MARKER.new() as Control
    _marker.name = "ObjectiveBearing"
    game.get_node("HUD").add_child(_marker)
    _marker.set("actor", actor)
    _marker.set("camera", actor.get_node("CameraPivot/SpringArm3D/Camera3D"))
    _objective.add_theme_color_override("font_outline_color", Color(0.005, 0.009, 0.014, 1.0))
    _objective.add_theme_constant_override("outline_size", 2)
    _objective.add_theme_color_override("font_color", Color(0.96, 0.93, 0.84))
    var objective_skin: StyleBoxFlat = StyleBoxFlat.new()
    objective_skin.bg_color = Color(0.008, 0.012, 0.019, 0.90)
    objective_skin.set_content_margin_all(5.0)
    _objective.add_theme_stylebox_override("normal", objective_skin)
    GameEvents.reality_fragment_found.connect(_on_fragment)
    refresh()

func _process(delta: float) -> void:
    if _game == null:
        return
    _timer -= delta
    if _timer <= 0.0:
        _timer = 0.15
        refresh()

func on_cache_claimed(_cache: Node3D, _item_id: StringName, starter: bool) -> void:
    progress.register_cache(starter)
    refresh()

func on_district_visit(district_id: StringName) -> void:
    progress.visit(district_id)
    refresh()

func on_event_started() -> void:
    progress.start_event()
    refresh()

func on_boss_defeated() -> void:
    progress.mark_boss_defeated()
    refresh()

func on_charge_finished() -> void:
    progress.mark_charge_finished()
    refresh()

func _on_fragment(fragment_id: StringName) -> void:
    progress.record_fragment(fragment_id)
    refresh()

func refresh() -> void:
    if _objective == null or not is_instance_valid(_portal):
        return
    var allowed: bool = progress.can_start_event()
    var lock_text: String = "CLAIM YOUR STARTER RELIC FIRST"
    if progress.loadout_claimed:
        lock_text = "EXPLORE TWO DISTRICTS  %d / %d" % [mini(progress.visited.size(), 2), RunProgress.REQUIRED_DISTRICTS]
    _portal.call("set_route_lock", not allowed, lock_text)
    _marker.set("enabled", not progress.is_finished())
    match progress.stage:
        RunProgress.Stage.LOADOUT:
            _objective.text = "01 // CLAIM A FREE STARTER RELIC // FOLLOW THE DIAMOND"
            _goal(_starter.global_position, "STARTER CACHE")
        RunProgress.Stage.EXPLORE:
            _objective.text = "02 // EXPLORE TWO DISTRICTS  %d / 2 // ANY ORDER" % mini(progress.visited.size(), 2)
            _nearest_district_goal()
        RunProgress.Stage.LOCATE:
            _objective.text = "03 // SIGNAL RESTORED // ACTIVATE THE TELEPORTER"
            _goal(_portal.global_position, "TELEPORTER")
        RunProgress.Stage.BATTLE:
            var inside: bool = bool(_portal.call("is_player_in_field"))
            if not progress.charge_finished:
                _objective.text = "04 // HOLD THE FIELD / DEFEAT WATCHER" if inside else "04 // RETURN TO THE FIELD // CHARGE PAUSED"
            else:
                _objective.text = "04 // FIELD CHARGED // DEFEAT WATCHER"
            _goal(_portal.global_position, "CHARGE FIELD" if not progress.charge_finished else "BOSS ARENA")
        RunProgress.Stage.RECOVER:
            _objective.text = "05 // SECTOR SECURED // EXAMINE THE REAL OBJECT (OPTIONAL)"
            _goal(Vector3(7.0, 0.02, -52.0), "UNINDEXED OBJECT")
        RunProgress.Stage.EXIT:
            _objective.text = "06 // RETURN TO THE TELEPORTER // LEAVE DISTRICT"
            _goal(_portal.global_position, "EXIT")
        RunProgress.Stage.COMPLETE:
            _objective.text = "RUN COMPLETE // REALITY ARCHIVE PRESERVED"
        RunProgress.Stage.FAILED:
            _objective.text = "RUN TERMINATED // REALITY ARCHIVE PRESERVED"

func _nearest_district_goal() -> void:
    var director: Node = _game.get_node_or_null("EncounterDirector")
    if director == null:
        return
    var districts: Array = director.call("get_district_catalog")
    var best: float = INF
    for entry in districts:
        var id: StringName = StringName(entry["id"])
        if id == &"arrival" or progress.visited.has(id):
            continue
        var center: Vector3 = entry["center"]
        var living: Node = get_tree().get_first_node_in_group("living_city")
        if living != null and id in [&"market_ruins", &"signal_concourse", &"archive_row", &"memory_gardens", &"utility_spine", &"null_terminal"]:
            center = living.call("entrance_for",id)
        var distance: float = _actor.global_position.distance_squared_to(center)
        if distance < best:
            best = distance
            _goal(center, String(entry["name"]))

func _goal(at: Vector3, title: String) -> void:
    var living: Node = get_tree().get_first_node_in_group("living_city")
    if living != null and at.y > -0.5 and (_actor.global_position.y > 2.3 or _actor.global_position.y < -0.7):
        var hint: Dictionary = living.call("exit_hint",_actor.global_position)
        if not hint.is_empty():
            _marker.set("target",hint["position"])
            _marker.set("caption",hint["caption"])
            return
    _marker.set("target", at)
    _marker.set("caption", title)

func finish(success: bool) -> void:
    progress.finish(success)
    refresh()

func summary(success: bool) -> String:
    var elapsed: float = float(_game.get("elapsed"))
    var inventory: InventoryComponent = _actor.get_node("InventoryComponent") as InventoryComponent
    var relic_count: int = 0
    for item_id in inventory.item_ids():
        relic_count += inventory.stack(item_id)
    var heading: String = "DISTRICT CLEARED" if success else "RUN TERMINATED"
    return "%s\nTIME %02d:%02d   KILLS %d   LV.%d\nDISTRICTS %d / 6   CACHES %d   RELICS %d\nNEW REALITY FRAGMENTS %d / 2\nCREDITS %d // COMBAT RELICS RESET NEXT RUN" % [heading, int(elapsed) / 60, int(elapsed) % 60, int(_game.get("kills")), int(_actor.get("level")), progress.visited.size(), progress.caches_opened, relic_count, progress.fragments_this_run.size(), int(_actor.get("credits"))]
