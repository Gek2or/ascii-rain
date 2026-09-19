extends SceneTree
# Actual GDScript execution. Run via tools/run_engine_checks.py (isolated saves).
const PROGRESS = preload("res://core/run/run_progress.gd")
const OFFERS = preload("res://components/inventory/relic_offers.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for known in [false, true]:
        for boss_first in [false, true]:
            var p: RunProgress = PROGRESS.new()
            p.reset(known)
            _expect(p.stage == RunProgress.Stage.LOADOUT, "start is loadout")
            _expect(not p.start_event() and not p.finish(true), "early boss/finish rejected")
            _expect(not p.visit(&"arrival") and not p.visit(&""), "arrival not a district")
            p.register_cache(true)
            _expect(p.stage == RunProgress.Stage.EXPLORE, "starter advances")
            _expect(p.visit(&"market") and not p.visit(&"market"), "visits deduplicated")
            _expect(not p.can_start_event(), "one district is insufficient")
            p.visit(&"gardens")
            _expect(p.stage == RunProgress.Stage.LOCATE and p.can_start_event(), "two districts unlock")
            _expect(p.start_event() and not p.start_event(), "single event activation")
            if boss_first:
                p.mark_boss_defeated()
                _expect(p.stage == RunProgress.Stage.BATTLE, "boss alone insufficient")
                p.mark_charge_finished()
            else:
                p.mark_charge_finished()
                _expect(p.stage == RunProgress.Stage.BATTLE, "charge alone insufficient")
                p.mark_boss_defeated()
            var wanted: int = RunProgress.Stage.EXIT if known else RunProgress.Stage.RECOVER
            _expect(p.stage == wanted, "boss/charge order independent and archive aware")
            if not known:
                p.record_fragment(&"memory_02")
                p.record_fragment(&"memory_02")
                _expect(p.stage == RunProgress.Stage.EXIT and p.fragments_this_run.size() == 1, "artifact deduplicated")
            _expect(p.finish(true), "earned completion")
            p.mark_boss_defeated()
            p.register_cache(true)
            _expect(not p.finish(false) and p.stage == RunProgress.Stage.COMPLETE, "terminal state immutable")
            p.reset(true)
            _expect(p.visited.is_empty() and p.caches_opened == 0 and p.toy_known, "restart resets run only")
    var early: RunProgress = PROGRESS.new()
    early.visit(&"a")
    early.visit(&"b")
    _expect(not early.can_start_event(), "exploring before claiming cannot skip starter")
    early.register_cache(true)
    _expect(early.can_start_event(), "early visits count once starter claimed")
    _expect(early.finish(false), "death always allowed")
    early.mark_charge_finished()
    _expect(early.stage == RunProgress.Stage.FAILED, "death cannot become success")
    var inv: InventoryComponent = InventoryComponent.new()
    root.add_child(inv)
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 99
    var starter: Array[StringName] = OFFERS.make_offer(inv, rng, true)
    _expect(starter == [&"chain_arc", &"split_core", &"leech_wire"], "meaningful free starter offer")
    var offers_valid: bool = true
    for seed_value in range(128):
        rng.seed = seed_value
        var ids: Array[StringName] = OFFERS.make_offer(inv, rng)
        var seen: Dictionary = {}
        for id in ids:
            if seen.has(id) or not inv.can_grant(id):
                offers_valid = false
            seen[id] = true
        offers_valid = offers_valid and ids.size() == 3
    _expect(offers_valid, "128 seeded offers: three distinct eligible choices")
    for id in inv.item_ids():
        var item: ItemData = inv.get_item(id)
        for stack_index in range(item.max_stack):
            inv.grant(id)
        _expect(inv.grant(id) == null and inv.stack(id) == item.max_stack, "cap rejects duplicate effects: " + String(id))
    _expect(OFFERS.make_offer(inv, rng).is_empty() and inv.grant_random() == null, "fully capped inventory terminates")
    inv.queue_free()
    root.get_node("AudioManager").call("stop_all")
    for frame in range(12):
        await physics_frame
    print("RUN_STATE_NATIVE: ", checks, " checks / ", failures, " failures")
    quit(0 if failures == 0 else 1)

func _expect(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("RUN_STATE: " + message)
