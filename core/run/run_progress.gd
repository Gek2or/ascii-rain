class_name RunProgress
extends RefCounted

# Run-local state only. The persistent Reality Archive belongs to StoryDirector.
# Rewards, visits, boss death and charge can arrive in either order.
enum Stage { LOADOUT, EXPLORE, LOCATE, BATTLE, RECOVER, EXIT, COMPLETE, FAILED }
const REQUIRED_DISTRICTS: int = 2
var stage: int = Stage.LOADOUT
var loadout_claimed: bool = false
var visited: Dictionary = {}
var fragments_this_run: Dictionary = {}
var caches_opened: int = 0
var started_event: bool = false
var boss_defeated: bool = false
var charge_finished: bool = false
var recovery_needed: bool = false
var toy_known: bool = false

func reset(already_knows_toy: bool = false) -> void:
    stage = Stage.LOADOUT
    loadout_claimed = false
    visited.clear()
    fragments_this_run.clear()
    caches_opened = 0
    started_event = false
    boss_defeated = false
    charge_finished = false
    recovery_needed = false
    toy_known = already_knows_toy

func is_finished() -> bool:
    return stage == Stage.COMPLETE or stage == Stage.FAILED

func register_cache(is_starter: bool) -> void:
    if is_finished():
        return
    caches_opened += 1
    if is_starter:
        loadout_claimed = true
    _resolve()

func visit(district_id: StringName) -> bool:
    if is_finished() or district_id == &"arrival" or district_id == &"":
        return false
    if visited.has(district_id):
        return false
    visited[district_id] = true
    _resolve()
    return true

func can_start_event() -> bool:
    return not is_finished() and loadout_claimed and visited.size() >= REQUIRED_DISTRICTS

func start_event() -> bool:
    if started_event or not can_start_event():
        return false
    started_event = true
    _resolve()
    return true

func mark_boss_defeated() -> void:
    if is_finished() or not started_event:
        return
    boss_defeated = true
    _resolve()

func mark_charge_finished() -> void:
    if is_finished() or not started_event:
        return
    charge_finished = true
    _resolve()

func record_fragment(fragment_id: StringName) -> void:
    if is_finished():
        return
    fragments_this_run[fragment_id] = true
    if fragment_id == &"memory_02":
        toy_known = true
    _resolve()

func finish(success: bool) -> bool:
    if is_finished():
        return false
    if success and (not started_event or not boss_defeated or not charge_finished):
        return false
    stage = Stage.COMPLETE if success else Stage.FAILED
    return true

func _resolve() -> void:
    if is_finished():
        return
    if not loadout_claimed:
        stage = Stage.LOADOUT
    elif visited.size() < REQUIRED_DISTRICTS:
        stage = Stage.EXPLORE
    elif not started_event:
        stage = Stage.LOCATE
    elif not boss_defeated or not charge_finished:
        stage = Stage.BATTLE
    else:
        recovery_needed = not toy_known
        stage = Stage.RECOVER if recovery_needed else Stage.EXIT
