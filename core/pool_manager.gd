extends Node

var _pools: Dictionary = {}

func spawn(scene: PackedScene, parent: Node) -> Node:
    if scene == null or parent == null:
        return null

    var key: String = scene.resource_path
    var bucket: Array = _pools.get(key, [])
    var instance: Node = null

    while not bucket.is_empty() and instance == null:
        var candidate: Variant = bucket.pop_back()
        if candidate is Node and is_instance_valid(candidate):
            instance = candidate as Node

    _pools[key] = bucket

    if instance == null:
        instance = scene.instantiate()
        instance.set_meta("pool_key", key)

    if instance.get_parent() != null:
        instance.get_parent().remove_child(instance)
    parent.add_child(instance)
    instance.process_mode = Node.PROCESS_MODE_INHERIT

    if instance is Node3D:
        (instance as Node3D).visible = true
    elif instance is CanvasItem:
        (instance as CanvasItem).visible = true

    if instance.has_method("on_pool_spawned"):
        instance.call("on_pool_spawned")
    return instance

func recycle(instance: Node) -> void:
    if instance == null or not is_instance_valid(instance):
        return
    if not instance.has_meta("pool_key"):
        instance.queue_free()
        return

    var key: String = String(instance.get_meta("pool_key"))
    if instance.has_method("on_pool_recycled"):
        instance.call("on_pool_recycled")

    instance.process_mode = Node.PROCESS_MODE_DISABLED
    if instance is Node3D:
        (instance as Node3D).visible = false
    elif instance is CanvasItem:
        (instance as CanvasItem).visible = false

    if instance.get_parent() != null:
        instance.get_parent().remove_child(instance)
    add_child(instance)

    var bucket: Array = _pools.get(key, [])
    bucket.append(instance)
    _pools[key] = bucket

func clear_all() -> void:
    for key_variant in _pools.keys():
        var bucket: Array = _pools[key_variant]
        for item_variant in bucket:
            if item_variant is Node and is_instance_valid(item_variant):
                (item_variant as Node).queue_free()
    _pools.clear()

func debug_counts() -> Dictionary:
    var result: Dictionary = {}
    for key_variant in _pools.keys():
        var key: String = String(key_variant)
        var bucket: Array = _pools[key_variant]
        result[key] = bucket.size()
    return result
