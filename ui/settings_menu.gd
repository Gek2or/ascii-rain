extends CanvasLayer

var _overlay: Control = null
var _panel: PanelContainer = null
var _style_option: OptionButton = null
var _preset_option: OptionButton = null
var _sliders: Dictionary = {}
var _values: Dictionary = {}
var _shadows_check: CheckButton = null
var _depth_check: CheckButton = null
var _performance_check: CheckButton = null
var _inventory_text: Label = null
var _lab_button: Button = null
var _preview_button: Button = null
var _preview_only: bool = false
var _is_open: bool = false
var _was_paused: bool = false

func _ready() -> void:
    layer = 220
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_menu()
    _build_mobile_button()
    _resize_panel()
    get_viewport().size_changed.connect(_resize_panel)
    _sync_controls()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key: InputEventKey = event as InputEventKey
        if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
            toggle_menu()
            get_viewport().set_input_as_handled()

func toggle_menu() -> void:
    set_open(not _is_open)

func set_open(value: bool) -> void:
    if value == _is_open:
        return
    if value and not get_tree().get_nodes_in_group("exclusive_ui").is_empty():
        return
    if value:
        _was_paused = get_tree().paused
    _is_open = value
    _overlay.visible = value
    _preview_only = false
    _panel.visible = true
    _preview_button.visible = false
    get_tree().paused = true if value else _was_paused
    if value:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        _sync_controls()
    elif not RuntimeProfile.is_mobile and not get_tree().paused:
        var actor: Node = get_tree().get_first_node_in_group("player")
        var alive: bool = actor != null and bool(actor.get("control_enabled"))
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if alive else Input.MOUSE_MODE_VISIBLE

func _build_mobile_button() -> void:
    if not RuntimeProfile.is_mobile:
        return
    var button: Button = Button.new()
    button.text = "SET"
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.offset_left = -78.0
    button.offset_right = -18.0
    button.offset_top = 76.0
    button.offset_bottom = 122.0
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(toggle_menu)
    add_child(button)

func _build_menu() -> void:
    _overlay = Control.new()
    add_child(_overlay)
    _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _overlay.visible = false
    var shade: ColorRect = ColorRect.new()
    _overlay.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.0, 0.0, 0.0, 0.0)
    # Keep the world visible at its actual exposure while editing graphics.
    _panel = PanelContainer.new()
    _overlay.add_child(_panel)
    _panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    var panel_style: StyleBoxFlat = StyleBoxFlat.new()
    panel_style.bg_color = Color(0.025, 0.030, 0.038, 0.98)
    panel_style.border_color = Color(0.32, 0.40, 0.47, 1.0)
    panel_style.set_border_width_all(1)
    _panel.add_theme_stylebox_override("panel", panel_style)
    _preview_button = Button.new()
    _preview_button.text = "BACK TO SETTINGS // GAME PAUSED"
    _preview_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    _preview_button.offset_left = -350.0
    _preview_button.offset_right = -16.0
    _preview_button.offset_top = 16.0
    _preview_button.offset_bottom = 60.0
    _preview_button.pressed.connect(_toggle_preview)
    _preview_button.visible = false
    _overlay.add_child(_preview_button)
    var margin: MarginContainer = MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 18)
    _panel.add_child(margin)
    var frame: VBoxContainer = VBoxContainer.new()
    frame.add_theme_constant_override("separation", 12)
    margin.add_child(frame)
    _heading(frame, "ASCII//RAIN  —  SYSTEM 0.13", 21)
    var quick: HBoxContainer = HBoxContainer.new()
    frame.add_child(quick)
    var reset_quick: Button = Button.new()
    reset_quick.text = "RESTORE REFERENCE MOOD"
    reset_quick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    reset_quick.pressed.connect(_reset_readability)
    quick.add_child(reset_quick)
    var preview: Button = Button.new()
    preview.text = "PREVIEW"
    preview.pressed.connect(_toggle_preview)
    quick.add_child(preview)
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    frame.add_child(scroll)
    var column: VBoxContainer = VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation", 10)
    scroll.add_child(column)
    _heading(column, "VISUAL STYLE", 17)
    _style_option = OptionButton.new()
    for title in ["REFERENCE MOOD / crisp glyphs", "READABLE COMBAT", "MOBILE SAFE"]:
        _style_option.add_item(title)
    _style_option.item_selected.connect(_on_style_selected)
    column.add_child(_style_option)
    _heading(column, "GRAPHICS", 17)
    _preset_option = OptionButton.new()
    for title in ["LOW", "MEDIUM", "HIGH", "ULTRA"]:
        _preset_option.add_item(title)
    _preset_option.add_item("CUSTOM")
    _preset_option.set_item_disabled(4, true)
    column.add_child(_preset_option)
    _preset_option.item_selected.connect(_on_preset_selected)
    _slider(column, "3D render scale", "render_scale", 0.5, 1.0, 0.02, "update_render_scale")
    _slider(column, "ASCII cell width (1 = micro-code)", "ascii_cell_px", 1.0, 10.0, 1.0, "update_ascii_cell")
    _slider(column, "Soft light halo", "bloom_strength", 0.0, 0.70, 0.01, "update_bloom")
    _slider(column, "World lighting", "lighting_boost", 0.70, 1.50, 0.02, "update_lighting")
    _shadows_check = CheckButton.new()
    _shadows_check.text = "Dynamic shadows"
    column.add_child(_shadows_check)
    _shadows_check.toggled.connect(_on_shadows_changed)
    _heading(column, "GAMEPLAY READABILITY", 17)
    _slider(column, "Dark gap fill", "surface_fill", 0.0, 0.70, 0.01, "update_surface_fill")
    _slider(column, "Background calmness", "background_calm", 0.0, 1.0, 0.02, "update_background_calm")
    _slider(column, "World color saturation", "color_saturation", 0.35, 1.0, 0.02, "update_color_saturation")
    _slider(column, "Midtone visibility", "readability_strength", 0.0, 1.0, 0.02, "update_readability")
    _slider(column, "Actor edge lighting", "actor_edge_strength", 0.0, 1.0, 0.02, "update_actor_edges")
    _depth_check = CheckButton.new()
    _depth_check.text = "Depth contours (extra GPU pass)"
    column.add_child(_depth_check)
    _depth_check.toggled.connect(SettingsManager.update_depth_contours)
    var note: Label = Label.new()
    note.text = "Reference Mood: one sharp glyph per cell, dark gaps and warm local light. Readable Combat lifts the gap tone without changing the world. Quality is separate from style. PREVIEW keeps combat paused."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_font_size_override("font_size", 13)
    column.add_child(note)
    var reset: Button = Button.new()
    reset.text = "Restore Reference Mood"
    reset.pressed.connect(_reset_readability)
    column.add_child(reset)
    _heading(column, "CITY AMBIENCE", 17)
    _slider(column, "Ambient motion (0 = off)", "ambient_motion", 0.0, 1.0, 0.1, "update_ambient_motion")
    _slider(column, "District ambience", "ambient_volume", 0.0, 1.0, 0.05, "update_ambient_volume")
    _heading(column, "CONTROLS / SOUND", 17)
    _slider(column, "Look sensitivity", "mouse_sensitivity_scale", 0.35, 2.20, 0.05, "update_mouse_sensitivity")
    _slider(column, "Touch look sensitivity", "touch_look_sensitivity", 0.35, 2.2, 0.05, "update_touch_look_sensitivity")
    _slider(column, "Touch button size", "touch_controls_scale", 0.8, 1.25, 0.05, "update_touch_controls_scale")
    _slider(column, "Camera motion", "camera_motion", 0.0, 1.0, 0.02, "update_camera_motion")
    _slider(column, "Music", "music_volume", 0.0, 1.0, 0.02, "update_music_volume")
    _slider(column, "Sound effects", "sfx_volume", 0.0, 1.0, 0.02, "update_sfx_volume")
    _heading(column, "PLAYTEST / CURRENT RUN", 17)
    _performance_check = CheckButton.new()
    _performance_check.text = "Show FPS and frame-time overlay"
    _performance_check.toggled.connect(SettingsManager.update_performance_hud)
    column.add_child(_performance_check)
    _lab_button = Button.new()
    _lab_button.text = "TEST COURTYARD (ends current run)"
    _lab_button.custom_minimum_size.y = 44.0
    _lab_button.pressed.connect(_on_lab_pressed)
    column.add_child(_lab_button)
    var lab_note: Label = Label.new()
    lab_note.text = "Fixed targets, dark and bright backgrounds, ramp and cover.\nNo archive progress or combat relics are saved in the courtyard."
    lab_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lab_note.add_theme_font_size_override("font_size", 13)
    column.add_child(lab_note)
    _inventory_text = Label.new()
    _inventory_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _inventory_text.add_theme_font_size_override("font_size", 15)
    column.add_child(_inventory_text)
    var resume: Button = Button.new()
    resume.text = "RESUME   /   ESC"
    resume.custom_minimum_size.y = 46.0
    resume.pressed.connect(_resume)
    frame.add_child(resume)

func _heading(parent: VBoxContainer, text: String, font_size: int) -> void:
    var label: Label = Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", font_size)
    parent.add_child(label)

func _slider(parent: VBoxContainer, text: String, key: String, minimum: float,
        maximum: float, step: float, setter: String) -> void:
    var row: VBoxContainer = VBoxContainer.new()
    parent.add_child(row)
    var header: HBoxContainer = HBoxContainer.new()
    row.add_child(header)
    var label: Label = Label.new()
    label.text = text
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(label)
    var value: Label = Label.new()
    value.custom_minimum_size.x = 52.0
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(value)
    var slider: HSlider = HSlider.new()
    slider.min_value = minimum
    slider.max_value = maximum
    slider.step = step
    slider.custom_minimum_size.y = 28.0
    row.add_child(slider)
    _sliders[key] = slider
    _values[key] = value
    slider.value_changed.connect(_on_slider_changed.bind(key, setter))

func _on_slider_changed(value: float, key: String, setter: String) -> void:
    SettingsManager.call(setter, value)
    var label: Label = _values[key] as Label
    label.text = "%.2f" % value
    _sync_quality_label()

func _sync_controls() -> void:
    if _style_option != null:
        _style_option.select(SettingsManager.visual_style)
    _sync_quality_label()
    for key in _sliders:
        var slider: HSlider = _sliders[key] as HSlider
        var label: Label = _values[key] as Label
        var value: float = float(SettingsManager.get(key))
        slider.set_value_no_signal(value)
        label.text = "%.2f" % value
    _shadows_check.set_pressed_no_signal(SettingsManager.shadows_enabled)
    _depth_check.set_pressed_no_signal(SettingsManager.depth_contours_enabled)
    _performance_check.set_pressed_no_signal(SettingsManager.performance_hud_enabled)
    _lab_button.text = "RETURN TO CITY (new run)" if _in_lab() else "TEST COURTYARD (ends current run)"
    var actor: Node = get_tree().get_first_node_in_group("player")
    var inventory: InventoryComponent = null
    if actor != null:
        inventory = actor.get_node_or_null("InventoryComponent") as InventoryComponent
    _inventory_text.text = "CURRENT RELICS\n" + (inventory.summary() if inventory != null else "NO RELICS")

func _resize_panel() -> void:
    var screen: Vector2 = get_viewport().get_visible_rect().size
    var width: float = maxf(280.0, minf(480.0, screen.x - 24.0))
    var height: float = maxf(230.0, minf(780.0, screen.y - 24.0))
    var center_x: float = screen.x * 0.5 - width * 0.5 - 16.0 if screen.x >= 1000.0 and not RuntimeProfile.is_mobile else 0.0
    _panel.offset_left = center_x - width * 0.5
    _panel.offset_right = center_x + width * 0.5
    _panel.offset_top = -height * 0.5
    _panel.offset_bottom = height * 0.5

func _on_preset_selected(index: int) -> void:
    SettingsManager.apply_preset(index)
    _sync_controls()

func _reset_readability() -> void:
    SettingsManager.reset_readability()
    _sync_controls()

func _resume() -> void:
    set_open(false)

func _in_lab() -> bool:
    var scene: Node = get_tree().current_scene
    return scene != null and scene.scene_file_path.ends_with("ReadabilityLab.tscn")

func _on_lab_pressed() -> void:
    var destination: String = "res://scenes/Main.tscn" if _in_lab() else "res://scenes/ReadabilityLab.tscn"
    get_tree().paused = false
    Engine.time_scale = 1.0
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var result: Error = get_tree().change_scene_to_file(destination)
    if result != OK:
        push_error("Could not load test scene: %s" % error_string(result))

func _toggle_preview() -> void:
    _preview_only = not _preview_only
    _panel.visible = not _preview_only
    _preview_button.visible = _preview_only

func _sync_quality_label() -> void:
    var tier: int = SettingsManager.quality_preset
    var scales: Array[float] = [0.62, 0.78, 1.0, 1.0]
    var widths: Array[float] = [8.0, 8.0, 6.0, 6.0]
    var custom: bool = absf(SettingsManager.render_scale - scales[tier]) > 0.005
    custom = custom or absf(SettingsManager.ascii_cell_px - widths[tier]) > 0.005
    custom = custom or SettingsManager.shadows_enabled != (tier >= 2)
    _preset_option.set_item_text(4, "CUSTOM // " + ["LOW", "MEDIUM", "HIGH", "ULTRA"][tier] + " base")
    _preset_option.select(4 if custom else tier)

func _on_shadows_changed(enabled: bool) -> void:
    SettingsManager.update_shadows(enabled)
    _sync_quality_label()

func _on_style_selected(index: int) -> void:
    SettingsManager.apply_visual_style(index)
    _sync_controls()
