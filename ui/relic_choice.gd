extends CanvasLayer

signal committed(cache: Node3D, item_id: StringName, starter: bool)
var _root: Control = null
var _panel: PanelContainer = null
var _cards: GridContainer = null
var _title: Label = null
var _hint: Label = null
var _cancel: Button = null
var _cache: Node3D = null
var _actor: Node3D = null
var _inventory: InventoryComponent = null
var _offered: Array[StringName] = []
var _buttons: Array[Button] = []
var _cost: int = 0
var _starter: bool = false
var _open: bool = false
var _opening_tick: int = 0

func _ready() -> void:
    layer = 240
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    get_viewport().size_changed.connect(_resize)
    _resize()

func offer(cache: Node3D, actor: Node3D, ids: Array[StringName], price: int, starter: bool) -> bool:
    if _open or get_tree().paused or not get_tree().get_nodes_in_group("exclusive_ui").is_empty():
        return false
    if not is_instance_valid(cache) or not is_instance_valid(actor) or ids.is_empty():
        return false
    _inventory = actor.get_node_or_null("InventoryComponent") as InventoryComponent
    if _inventory == null or float(actor.get("health")) <= 0.0:
        return false
    _cache = cache
    _actor = actor
    _cost = maxi(0, price)
    _starter = starter
    _offered = ids.duplicate()
    _title.text = "CHOOSE YOUR FIRST RELIC" if starter else "CACHE // CHOOSE ONE"
    _hint.text = "FREE STARTER CACHE // choose one, the others stay behind" if starter else "Only the chosen relic costs %d credits. Cancel keeps the same offer." % _cost
    _fill_cards()
    _opening_tick = Time.get_ticks_msec()
    _open = true
    add_to_group("exclusive_ui")
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _root.visible = true
    if not _buttons.is_empty():
        _buttons[0].grab_focus()
    return true

func _input(event: InputEvent) -> void:
    if not _open or not (event is InputEventKey):
        return
    var key: InputEventKey = event as InputEventKey
    if not key.pressed or key.echo:
        return
    if key.keycode == KEY_ESCAPE:
        _close()
    elif key.keycode >= KEY_1 and key.keycode <= KEY_3:
        _choose(int(key.keycode - KEY_1))
    else:
        return
    get_viewport().set_input_as_handled()

func _choose(index: int) -> void:
    # Ignore the click/touch that opened the popup and all repeat activations.
    if not _open or Time.get_ticks_msec() - _opening_tick < 160:
        return
    if index < 0 or index >= _offered.size():
        return
    if not is_instance_valid(_cache) or not is_instance_valid(_actor):
        _close()
        return
    if bool(_cache.get("opened")) or float(_actor.get("health")) <= 0.0:
        _close()
        return
    if _actor.global_position.distance_to(_cache.global_position) > 3.8:
        _hint.text = "Cache is out of reach. Cancel and move closer."
        return
    var item_id: StringName = _offered[index]
    if not _inventory.can_grant(item_id):
        _hint.text = "This relic is already at its stack limit. Choose another."
        return
    if not bool(_actor.call("spend_credits", _cost)):
        _hint.text = "NOT ENOUGH CREDITS // cancel to continue exploring"
        return
    # No await between debit and grant: double clicks cannot claim twice.
    _open = false
    _actor.call("grant_item", String(item_id))
    var claimed_cache: Node3D = _cache
    var was_starter: bool = _starter
    claimed_cache.call("complete_open")
    committed.emit(claimed_cache, item_id, was_starter)
    _close()

func _close() -> void:
    if not _root.visible:
        return
    _open = false
    _root.visible = false
    remove_from_group("exclusive_ui")
    for button in _buttons:
        button.release_focus()
    # Clear touch state immediately; do not let a menu finger become a shot.
    var controls: Node = get_parent().get_node_or_null("MobileControls")
    if controls != null and controls.has_method("_reset_controls"):
        controls.call("_reset_controls")
    if is_instance_valid(_actor) and _actor.has_method("suppress_actions_after_ui"):
        _actor.call("suppress_actions_after_ui")
    get_tree().paused = false
    if not RuntimeProfile.is_mobile and is_instance_valid(_actor) and bool(_actor.get("control_enabled")):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _cache = null
    _actor = null
    _offered.clear()

func _build() -> void:
    _root = Control.new()
    add_child(_root)
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.visible = false
    var shade: ColorRect = ColorRect.new()
    _root.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.008, 0.012, 0.018, 0.35)
    _panel = PanelContainer.new()
    _root.add_child(_panel)
    var skin: StyleBoxFlat = StyleBoxFlat.new()
    skin.bg_color = Color(0.027, 0.032, 0.041, 0.99)
    skin.border_color = Color(0.65, 0.58, 0.40)
    skin.set_border_width_all(1)
    skin.set_content_margin_all(20.0)
    _panel.add_theme_stylebox_override("panel", skin)
    var frame: VBoxContainer = VBoxContainer.new()
    frame.add_theme_constant_override("separation", 14)
    _panel.add_child(frame)
    _title = Label.new()
    _title.add_theme_font_size_override("font_size", 24)
    frame.add_child(_title)
    _hint = Label.new()
    _hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _hint.add_theme_font_size_override("font_size", 16)
    frame.add_child(_hint)
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_child(scroll)
    _cards = GridContainer.new()
    _cards.columns = 3
    _cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _cards.add_theme_constant_override("h_separation", 12)
    _cards.add_theme_constant_override("v_separation", 12)
    scroll.add_child(_cards)
    _cancel = Button.new()
    _cancel.text = "CANCEL / ESC // NO CREDITS SPENT"
    _cancel.custom_minimum_size.y = 48
    _cancel.pressed.connect(_close)
    frame.add_child(_cancel)

func _fill_cards() -> void:
    for child in _cards.get_children():
        _cards.remove_child(child)
        child.queue_free()
    _buttons.clear()
    for index in range(_offered.size()):
        var item: ItemData = _inventory.get_item(_offered[index])
        var button: Button = Button.new()
        var stack: int = _inventory.stack(item.id)
        # Label autowrap also works on older Godot 4 releases where Button
        # autowrap was not available. Children must never consume the tap.
        button.tooltip_text = item.display_name
        var label: Label = Label.new()
        button.add_child(label)
        label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        label.offset_left = 14.0
        label.offset_right = -14.0
        label.offset_top = 12.0
        label.offset_bottom = -12.0
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.add_theme_font_size_override("font_size", 18)
        label.text = "[%d]  %s\n\n%s\n\nSTACK %d  ->  %d" % [index + 1, item.display_name, item.description, stack, stack + 1]
        button.custom_minimum_size = Vector2(0.0, 228.0)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 18)
        button.pressed.connect(_choose.bind(index))
        _cards.add_child(button)
        _buttons.append(button)

func _resize() -> void:
    var view: Vector2 = get_viewport().get_visible_rect().size
    var width: float = minf(1040.0, view.x - 32.0)
    var height: float = minf(470.0, view.y - 32.0)
    _panel.position = (view - Vector2(width, height)) * 0.5
    _panel.size = Vector2(width, height)
    _cards.columns = 3 if view.x >= 760.0 else 1
