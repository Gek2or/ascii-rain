class_name EnemyData
extends Resource

@export var id: StringName = &"enemy"
@export var display_name: String = "ENEMY"
@export var move_speed: float = 3.0
@export var max_health: float = 50.0
@export var touch_damage: float = 10.0
@export var attack_interval: float = 1.0
@export var projectile_damage: float = 0.0
@export var projectile_speed: float = 12.0
@export var preferred_range: float = 10.0
@export var xp_reward: int = 10
@export var credit_reward: int = 3
@export var scale_multiplier: float = 1.0
@export var core_color: Color = Color(1.0, 0.04, 0.02)
@export_enum("BIPED", "LOW", "RANGED", "CARRIER", "HEAVY") var visual_profile: int = 0
@export var accent_color: Color = Color(0.15, 0.18, 0.24)
@export_range(0.2, 1.4, 0.05) var stride_scale: float = 0.64
@export_range(0.0, 0.12, 0.005) var bob_amount: float = 0.055
@export_range(0.2, 1.5, 0.05) var attack_pose_scale: float = 1.0
