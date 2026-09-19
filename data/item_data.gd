class_name ItemData
extends Resource

@export var id: StringName = &"item"
@export var display_name: String = "ITEM"
@export_multiline var description: String = ""
@export_enum("Common", "Uncommon", "Rare", "Reality") var rarity: int = 0
@export_range(1, 999, 1) var max_stack: int = 99
@export var effect_tag: StringName = &""
