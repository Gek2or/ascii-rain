extends Node

signal enemy_killed(enemy: Node, xp_reward: int, credit_reward: int)
signal boss_killed(boss: Node, xp_reward: int, credit_reward: int)
signal boss_phase_changed(phase: int, label: String)
signal weapon_selected(weapon_id: StringName, display_name: String)
signal item_collected(item_id: StringName, stacks: int)
signal reality_fragment_found(fragment_id: StringName)
signal run_started
signal run_ended(success: bool)
signal shot_feedback(hit: bool, critical: bool)
signal district_entered(district_id: StringName, display_name: String)

func emit_enemy_killed(enemy: Node, xp_reward: int, credit_reward: int) -> void:
    enemy_killed.emit(enemy, xp_reward, credit_reward)

func emit_boss_killed(boss: Node, xp_reward: int, credit_reward: int) -> void:
    boss_killed.emit(boss, xp_reward, credit_reward)

func emit_boss_phase_changed(phase: int, label: String) -> void:
    boss_phase_changed.emit(phase, label)

func emit_weapon_selected(weapon_id: StringName, display_name: String) -> void:
    weapon_selected.emit(weapon_id, display_name)

func emit_item_collected(item_id: StringName, stacks: int) -> void:
    item_collected.emit(item_id, stacks)

func emit_reality_fragment_found(fragment_id: StringName) -> void:
    reality_fragment_found.emit(fragment_id)

func emit_shot_feedback(hit: bool, critical: bool) -> void:
    shot_feedback.emit(hit, critical)

func emit_district_entered(district_id: StringName, display_name: String) -> void:
    district_entered.emit(district_id, display_name)
