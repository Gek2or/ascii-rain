class_name WeaponData
extends Resource

@export var id: StringName = &"weapon"
@export var display_name: String = "WEAPON"
@export var damage_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0
@export_range(1, 16, 1) var pellets: int = 1
@export var spread_degrees: float = 0.0
@export var tracer_color: Color = Color.WHITE
@export var stagger_power: float = 0.5
@export_range(0.25, 2.5, 0.05) var shot_recoil: float = 1.0
@export_range(0.02, 0.2, 0.005) var muzzle_flash_duration: float = 0.072
@export_range(1.0, 16.0, 0.1) var muzzle_light_energy: float = 6.8
@export_range(0, 8, 1) var intrinsic_chain_jumps: int = 0
@export_range(0.0, 2.0, 0.01) var intrinsic_chain_damage_ratio: float = 0.0
@export var hud_suffix: String = ""
