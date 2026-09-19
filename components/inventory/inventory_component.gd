class_name InventoryComponent
extends Node

const ITEM_RESOURCES: Array = [
    preload("res://data/items/overcharge.tres"),
    preload("res://data/items/rapid_array.tres"),
    preload("res://data/items/phase_legs.tres"),
    preload("res://data/items/reinforced_frame.tres"),
    preload("res://data/items/lens_fragment.tres"),
    preload("res://data/items/split_core.tres"),
    preload("res://data/items/chain_arc.tres"),
    preload("res://data/items/leech_wire.tres"),
    preload("res://data/items/blast_glyph.tres"),
    preload("res://data/items/armor_plating.tres"),
    preload("res://data/items/chrono_cell.tres"),
    preload("res://data/items/execution_rune.tres"),
]

var _catalog: Dictionary = {}
var _order: Array[StringName] = []
var _stacks: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    _rng.randomize()
    _catalog.clear()
    _order.clear()
    _stacks.clear()

    for resource_variant in ITEM_RESOURCES:
        var item: ItemData = resource_variant as ItemData
        if item == null or item.id == &"":
            continue
        _catalog[item.id] = item
        _order.append(item.id)
        _stacks[item.id] = 0

func grant_random() -> ItemData:
    var eligible: Array[StringName] = []
    for item_id in _order:
        if can_grant(item_id):
            eligible.append(item_id)
    if eligible.is_empty():
        return null
    var index: int = _rng.randi_range(0, eligible.size() - 1)
    return grant(eligible[index])

func grant(item_id: StringName) -> ItemData:
    var item: ItemData = get_item(item_id)
    if item == null or not can_grant(item_id):
        return null
    var current_stack: int = stack(item_id)
    _stacks[item_id] = mini(item.max_stack, current_stack + 1)
    return item

func get_item(item_id: StringName) -> ItemData:
    var value: Variant = _catalog.get(item_id, null)
    return value as ItemData

func stack(item_id: StringName) -> int:
    return int(_stacks.get(item_id, 0))

func summary() -> String:
    var lines: Array[String] = []
    for item_id in _order:
        var count: int = stack(item_id)
        if count <= 0:
            continue
        var item: ItemData = get_item(item_id)
        var label: String = item.display_name if item != null else String(item_id)
        lines.append("%s  ×%d" % [label, count])

    if lines.is_empty():
        return "NO RELICS"

    var result: String = ""
    for i in range(lines.size()):
        if i > 0:
            result += "\n"
        result += lines[i]
    return result

func item_ids() -> Array[StringName]:
    return _order.duplicate()

func can_grant(item_id: StringName) -> bool:
    var item: ItemData = get_item(item_id)
    return item != null and stack(item_id) < item.max_stack
