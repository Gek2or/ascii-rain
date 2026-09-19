extends RefCounted

const STARTER_IDS: Array[StringName] = [&"chain_arc", &"split_core", &"leech_wire"]

static func make_offer(inventory: InventoryComponent, rng: RandomNumberGenerator, starter: bool = false) -> Array[StringName]:
    var candidates: Array[StringName] = []
    var result: Array[StringName] = []
    if inventory == null:
        return result
    for item_id in inventory.item_ids():
        if inventory.can_grant(item_id):
            candidates.append(item_id)
    if starter:
        for item_id in STARTER_IDS:
            if candidates.has(item_id):
                result.append(item_id)
                candidates.erase(item_id)
    while result.size() < 3 and not candidates.is_empty():
        var index: int = rng.randi_range(0, candidates.size() - 1)
        result.append(candidates[index])
        candidates.remove_at(index)
    return result
