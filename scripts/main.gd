extends Node2D

const SAVE_PATH: String = "user://loot_rat_save.json"
const ARENA_BOUNDS: Rect2 = Rect2(40.0, 80.0, 1200.0, 590.0)
const HIDEOUT_BOUNDS: Rect2 = Rect2(70.0, 105.0, 1140.0, 535.0)
const HideoutScript = preload("res://scripts/hideout.gd")

var rng := RandomNumberGenerator.new()

var arena: LootArena = null
var hideout: LootHideout = null
var actor_layer: Node2D = null
var projectile_layer: Node2D = null
var loot_layer: Node2D = null
var player: LootPlayer = null

var hud: CanvasLayer = null
var top_label: Label = null
var coins_label: Label = null
var seals_label: Label = null
var networth_label: Label = null
var run_label: Label = null
var feed_label: Label = null
var hp_bar: ProgressBar = null
var hub_panel: PanelContainer = null
var character_panel: PanelContainer = null
var gear_panel: PanelContainer = null
var crafting_panel: PanelContainer = null
var decision_panel: PanelContainer = null
var decision_title: Label = null
var decision_body: Label = null
var inventory_list: GridContainer = null
var equipped_label: RichTextLabel = null
var equipped_slot_buttons: Dictionary = {}
var claim_label: RichTextLabel = null
var stats_label: RichTextLabel = null
var stash_count_label: Label = null
var selected_item_label: RichTextLabel = null
var selected_equip_button: Button = null
var selected_sell_button: Button = null
var selected_craft_button: Button = null
var crafting_item_label: RichTextLabel = null
var crafting_currency_label: RichTextLabel = null
var crafting_feedback_label: Label = null
var crafting_buttons: Dictionary = {}
var core_buttons: Dictionary = {}
var crafting_stash_grid: GridContainer = null
var crafting_equipped_buttons: Dictionary = {}
var crafting_target_source: String = "none"
var crafting_target_slot: String = ""
var sort_button: Button = null
var claim_unlock_button: Button = null
var interaction_prompt: Label = null
var hub_modal_open: bool = false
var active_hub_station: String = ""
var filter_buttons: Dictionary = {}

var state: String = "hub"
var depth: int = 1
var alive_enemies: int = 0
var floor_kills: int = 0
var total_run_kills: int = 0
var decision_open: bool = false
var room_index: int = 1
var rooms_total: int = 5
var current_room_type: String = "PACK"
var room_ready_to_advance: bool = false
var room_clear_delay: float = 0.0

var stash_coins: int = 0
var stash_seals: int = 5
var stash_gear: Array[Dictionary] = []
var stash_crafting: Dictionary = {"scrap": 0, "mutation": 0, "splice": 0, "crown": 0, "hoarder": 0, "chaos": 0, "polish": 0, "mechanist": 0}
var stash_cores: Dictionary = {"repeater": 0, "scatter": 1, "piercer": 1, "sprayer": 1, "cleaver": 1, "duelist": 1, "whirlwind": 1, "throwing": 1}
var equipped: Dictionary = {"weapon": {}, "armor": {}, "charm": {}}
var next_item_id: int = 1
var blade_intro_granted: bool = false

var run_coins: int = 0
var run_seals: int = 0
var run_gear: Array[Dictionary] = []
var run_crafting: Dictionary = {"scrap": 0, "mutation": 0, "splice": 0, "crown": 0, "hoarder": 0, "chaos": 0, "polish": 0, "mechanist": 0}
var run_cores: Dictionary = {"repeater": 0, "scatter": 0, "piercer": 0, "sprayer": 0, "cleaver": 0, "duelist": 0, "whirlwind": 0, "throwing": 0}

var juice_density: int = 0
var juice_quantity: int = 0
var juice_currency: int = 0
var juice_elite: int = 0

var feed_lines: Array[String] = []

var selected_stash_item_id: int = -1
var stash_filter: String = "all"
var stash_sort_mode: String = "value"

var claim_tier: int = 1
var tier_best_depths: Dictionary = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}

func _ready() -> void:
	_configure_input_map()
	rng.randomize()
	_load_save()
	_ensure_starter_gear()
	_build_world()
	_build_ui()
	_enter_hub()


func _configure_input_map() -> void:
	_ensure_key_action(&"move_left", KEY_A)
	_ensure_key_action(&"move_right", KEY_D)
	_ensure_key_action(&"move_up", KEY_W)
	_ensure_key_action(&"move_down", KEY_S)
	_ensure_key_action(&"dash", KEY_SPACE)
	_ensure_key_action(&"interact", KEY_E)
	_ensure_mouse_action(&"attack", MOUSE_BUTTON_LEFT)

func _ensure_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _ensure_mouse_action(action: StringName, button_index: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _build_world() -> void:
	hideout = HideoutScript.new()
	add_child(hideout)
	hideout.visible = true

	arena = LootArena.new()
	add_child(arena)
	arena.visible = false

	actor_layer = Node2D.new()
	actor_layer.name = "Actors"
	add_child(actor_layer)

	projectile_layer = Node2D.new()
	projectile_layer.name = "Projectiles"
	add_child(projectile_layer)

	loot_layer = Node2D.new()
	loot_layer.name = "Loot"
	add_child(loot_layer)

func _build_ui() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)

	var top_bg := ColorRect.new()
	top_bg.color = Color(0.018, 0.022, 0.032, 0.98)
	top_bg.position = Vector2.ZERO
	top_bg.size = Vector2(1280.0, 76.0)
	hud.add_child(top_bg)

	top_label = Label.new()
	top_label.position = Vector2(18.0, 12.0)
	top_label.size = Vector2(160.0, 50.0)
	top_label.text = "LOOT RAT"
	top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_label.add_theme_font_size_override("font_size", 24)
	top_label.add_theme_color_override("font_color", Color(0.90, 0.93, 0.98))
	hud.add_child(top_label)

	coins_label = _make_wealth_label(Vector2(190.0, 10.0), Vector2(170.0, 54.0))
	seals_label = _make_wealth_label(Vector2(370.0, 10.0), Vector2(160.0, 54.0))
	networth_label = _make_wealth_label(Vector2(540.0, 10.0), Vector2(220.0, 54.0))
	hud.add_child(coins_label)
	hud.add_child(seals_label)
	hud.add_child(networth_label)

	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(790.0, 14.0)
	hp_bar.size = Vector2(210.0, 24.0)
	hp_bar.min_value = 0.0
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.show_percentage = true
	hud.add_child(hp_bar)

	run_label = Label.new()
	run_label.position = Vector2(790.0, 42.0)
	run_label.size = Vector2(470.0, 26.0)
	run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	run_label.add_theme_font_size_override("font_size", 15)
	run_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	hud.add_child(run_label)

	feed_label = Label.new()
	feed_label.position = Vector2(945.0, 94.0)
	feed_label.size = Vector2(305.0, 190.0)
	feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	feed_label.add_theme_font_size_override("font_size", 15)
	hud.add_child(feed_label)

	_build_hub_panel()
	_build_character_panel()
	_build_gear_panel()
	_build_crafting_panel()
	_build_decision_panel()

	interaction_prompt = Label.new()
	interaction_prompt.position = Vector2(390.0, 645.0)
	interaction_prompt.size = Vector2(500.0, 42.0)
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_prompt.add_theme_font_size_override("font_size", 18)
	interaction_prompt.add_theme_color_override("font_color", Color(0.92, 0.85, 0.62))
	interaction_prompt.visible = false
	hud.add_child(interaction_prompt)

	var controls := Label.new()
	controls.text = "WASD move   •   SPACE dash   •   E interact   •   ESC close"
	controls.position = Vector2(20.0, 688.0)
	controls.add_theme_color_override("font_color", Color(0.50, 0.55, 0.64))
	hud.add_child(controls)

func _make_wealth_label(position_value: Vector2, size_value: Vector2) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98))
	return label

func _panel_style(background: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 10.0
	style.content_margin_top = 9.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 9.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 5
	return style

func _arpg_frame_style(bright: bool = false) -> StyleBoxFlat:
	var border: Color = Color(0.46, 0.35, 0.20) if bright else Color(0.25, 0.20, 0.13)
	return _panel_style(Color(0.018, 0.017, 0.015, 0.985), border, 2 if bright else 1)

func _arpg_slot_style(border: Color, selected: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.026, 0.024, 0.021, 0.99)
	style.border_color = Color(0.78, 0.61, 0.29) if selected else border
	var border_width: int = 3 if selected else 1
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 1
	return style

func _arpg_button_style(active: bool = false, hover: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.105, 0.085, 0.055) if active else (Color(0.075, 0.066, 0.052) if hover else Color(0.040, 0.038, 0.034))
	style.border_color = Color(0.72, 0.54, 0.25) if active else Color(0.29, 0.235, 0.15)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style

func _section_title(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.86, 0.72, 0.43))
	return label

func _muted_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.54, 0.59, 0.68))
	return label

func _build_hub_panel() -> void:
	hub_panel = PanelContainer.new()
	hub_panel.position = Vector2(365.0, 105.0)
	hub_panel.size = Vector2(550.0, 535.0)
	hub_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.020, 0.022, 0.028, 0.99), Color(0.36, 0.22, 0.34), 2))
	hud.add_child(hub_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 11)
	hub_panel.add_child(root)

	var title := _section_title("CLAIM TABLE")
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	claim_label = RichTextLabel.new()
	claim_label.bbcode_enabled = true
	claim_label.fit_content = false
	claim_label.custom_minimum_size = Vector2(515.0, 122.0)
	claim_label.add_theme_font_size_override("normal_font_size", 14)
	root.add_child(claim_label)

	var modifier_title := Label.new()
	modifier_title.text = "SEAL MODIFIERS"
	modifier_title.add_theme_font_size_override("font_size", 13)
	modifier_title.add_theme_color_override("font_color", Color(0.64,0.61,0.68))
	root.add_child(modifier_title)

	var modifier_grid := GridContainer.new()
	modifier_grid.columns = 2
	modifier_grid.add_theme_constant_override("h_separation", 8)
	modifier_grid.add_theme_constant_override("v_separation", 8)
	root.add_child(modifier_grid)
	modifier_grid.add_child(_make_button("DENSITY\n+20%", _juice_density, Vector2(250.0, 58.0)))
	modifier_grid.add_child(_make_button("ITEMS\n+25%", _juice_quantity, Vector2(250.0, 58.0)))
	modifier_grid.add_child(_make_button("CURRENCY\n+25%", _juice_currency, Vector2(250.0, 58.0)))
	modifier_grid.add_child(_make_button("ELITES\n+3.5%", _juice_elite, Vector2(250.0, 58.0)))

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	root.add_child(action_row)

	var run_button := _make_button("ENTER CLAIM", _start_claim, Vector2(330.0, 46.0))
	run_button.add_theme_font_size_override("font_size", 17)
	action_row.add_child(run_button)

	var reset_button := _make_button("RESET", _reset_juice, Vector2(178.0, 46.0))
	reset_button.add_theme_font_size_override("font_size", 12)
	action_row.add_child(reset_button)

	claim_unlock_button = _make_button("NEXT TIER LOCKED", _unlock_next_claim_tier, Vector2(515.0, 38.0))
	claim_unlock_button.add_theme_font_size_override("font_size", 12)
	root.add_child(claim_unlock_button)

func _build_character_panel() -> void:
	character_panel = PanelContainer.new()
	character_panel.position = Vector2(45.0, 88.0)
	character_panel.size = Vector2(270.0, 570.0)
	character_panel.add_theme_stylebox_override("panel", _arpg_frame_style(true))
	hud.add_child(character_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	character_panel.add_child(root)

	var title := _section_title("CHARACTER")
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "EQUIPMENT"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(0.47, 0.43, 0.35))
	root.add_child(subtitle)

	var slot_grid := VBoxContainer.new()
	slot_grid.add_theme_constant_override("separation", 7)
	root.add_child(slot_grid)

	var slot_specs: Array[Dictionary] = [
		{"key":"weapon", "label":"WEAPON", "glyph":"⚔"},
		{"key":"armor", "label":"ARMOR", "glyph":"▣"},
		{"key":"charm", "label":"CHARM", "glyph":"◆"}
	]
	for spec: Dictionary in slot_specs:
		var slot_key: String = String(spec["key"])
		var button := Button.new()
		button.custom_minimum_size = Vector2(246.0, 88.0)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_stylebox_override("normal", _arpg_slot_style(Color(0.22, 0.19, 0.14)))
		button.add_theme_stylebox_override("hover", _arpg_slot_style(Color(0.45, 0.34, 0.20)))
		button.pressed.connect(_select_equipped_slot.bind(slot_key))
		equipped_slot_buttons[slot_key] = button
		slot_grid.add_child(button)

	var divider := HSeparator.new()
	divider.add_theme_constant_override("separation", 2)
	root.add_child(divider)

	stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.fit_content = false
	stats_label.custom_minimum_size = Vector2(246.0, 178.0)
	stats_label.add_theme_font_size_override("normal_font_size", 12)
	stats_label.add_theme_constant_override("line_separation", 3)
	root.add_child(stats_label)

	equipped_label = RichTextLabel.new()
	equipped_label.visible = false
	root.add_child(equipped_label)

func _build_gear_panel() -> void:
	gear_panel = PanelContainer.new()
	gear_panel.position = Vector2(323.0, 88.0)
	gear_panel.size = Vector2(912.0, 570.0)
	gear_panel.add_theme_stylebox_override("panel", _arpg_frame_style(true))
	hud.add_child(gear_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	gear_panel.add_child(root)

	var header_row := HBoxContainer.new()
	root.add_child(header_row)
	var header_spacer_left := Control.new()
	header_spacer_left.custom_minimum_size = Vector2(130.0, 1.0)
	header_row.add_child(header_spacer_left)
	var title := _section_title("STASH")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	stash_count_label = _muted_label("")
	stash_count_label.custom_minimum_size = Vector2(130.0, 1.0)
	stash_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stash_count_label.add_theme_font_size_override("font_size", 11)
	header_row.add_child(stash_count_label)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 2)
	root.add_child(tab_row)
	var filter_specs: Array[Dictionary] = [
		{"key":"all", "label":"ALL"},
		{"key":"weapon", "label":"WEAPONS"},
		{"key":"armor", "label":"ARMOR"},
		{"key":"charm", "label":"CHARMS"}
	]
	for spec: Dictionary in filter_specs:
		var key: String = String(spec["key"])
		var filter_button := _make_button(String(spec["label"]), _set_stash_filter.bind(key), Vector2(86.0, 26.0))
		filter_button.add_theme_font_size_override("font_size", 10)
		filter_buttons[key] = filter_button
		tab_row.add_child(filter_button)
	var tab_spacer := Control.new()
	tab_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_row.add_child(tab_spacer)
	var sort_caption := Label.new()
	sort_caption.text = "SORT"
	sort_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sort_caption.add_theme_font_size_override("font_size", 9)
	sort_caption.add_theme_color_override("font_color", Color(0.45, 0.42, 0.36))
	tab_row.add_child(sort_caption)
	sort_button = _make_button("VALUE", _cycle_stash_sort, Vector2(88.0, 26.0))
	sort_button.add_theme_font_size_override("font_size", 10)
	tab_row.add_child(sort_button)

	var content_row := HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 8)
	root.add_child(content_row)

	var grid_panel := PanelContainer.new()
	grid_panel.custom_minimum_size = Vector2(548.0, 442.0)
	grid_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.010, 0.010, 0.009), Color(0.18, 0.15, 0.10), 1))
	content_row.add_child(grid_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.add_child(scroll)

	inventory_list = GridContainer.new()
	inventory_list.columns = 8
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("h_separation", 2)
	inventory_list.add_theme_constant_override("v_separation", 2)
	scroll.add_child(inventory_list)

	var inspector_panel := PanelContainer.new()
	inspector_panel.custom_minimum_size = Vector2(326.0, 442.0)
	inspector_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.017, 0.015), Color(0.26, 0.21, 0.13), 1))
	content_row.add_child(inspector_panel)

	var inspector_root := VBoxContainer.new()
	inspector_root.add_theme_constant_override("separation", 5)
	inspector_panel.add_child(inspector_root)

	var inspect_header := Label.new()
	inspect_header.text = "ITEM"
	inspect_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inspect_header.add_theme_font_size_override("font_size", 10)
	inspect_header.add_theme_color_override("font_color", Color(0.52, 0.46, 0.34))
	inspector_root.add_child(inspect_header)

	var inspect_divider := HSeparator.new()
	inspector_root.add_child(inspect_divider)

	selected_item_label = RichTextLabel.new()
	selected_item_label.bbcode_enabled = true
	selected_item_label.fit_content = false
	selected_item_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selected_item_label.custom_minimum_size = Vector2(300.0, 337.0)
	selected_item_label.add_theme_font_size_override("normal_font_size", 12)
	selected_item_label.add_theme_constant_override("line_separation", 2)
	inspector_root.add_child(selected_item_label)

	selected_equip_button = _make_button("EQUIP", _equip_selected_item, Vector2(300.0, 34.0))
	selected_equip_button.add_theme_font_size_override("font_size", 12)
	selected_equip_button.add_theme_stylebox_override("normal", _arpg_button_style(true))
	inspector_root.add_child(selected_equip_button)

	selected_sell_button = _make_button("SELL", _sell_selected_item, Vector2(300.0, 28.0))
	selected_sell_button.add_theme_font_size_override("font_size", 10)
	selected_sell_button.add_theme_color_override("font_color", Color(0.61, 0.56, 0.47))
	inspector_root.add_child(selected_sell_button)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 5)
	root.add_child(footer)
	var sell_filtered := _make_button("SELL FILTERED", _sell_filtered_gear, Vector2(110.0, 25.0))
	sell_filtered.add_theme_font_size_override("font_size", 9)
	footer.add_child(sell_filtered)
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	var wipe_button := _make_button("WIPE SAVE", _wipe_save, Vector2(82.0, 25.0))
	wipe_button.add_theme_font_size_override("font_size", 9)
	wipe_button.add_theme_color_override("font_color", Color(0.48, 0.39, 0.34))
	footer.add_child(wipe_button)

func _build_crafting_panel() -> void:
	crafting_panel = PanelContainer.new()
	crafting_panel.position = Vector2(50.0, 88.0)
	crafting_panel.size = Vector2(1180.0, 570.0)
	crafting_panel.visible = false
	crafting_panel.add_theme_stylebox_override("panel", _arpg_frame_style(true))
	hud.add_child(crafting_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	crafting_panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var header_pad := Control.new()
	header_pad.custom_minimum_size = Vector2(42.0, 1.0)
	header.add_child(header_pad)
	var title := _section_title("WORKBENCH")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := _make_button("×", _close_crafting_panel, Vector2(42.0, 28.0))
	close_button.add_theme_font_size_override("font_size", 16)
	header.add_child(close_button)

	crafting_currency_label = RichTextLabel.new()
	crafting_currency_label.bbcode_enabled = true
	crafting_currency_label.fit_content = false
	crafting_currency_label.custom_minimum_size = Vector2(1150.0, 30.0)
	crafting_currency_label.add_theme_font_size_override("normal_font_size", 11)
	root.add_child(crafting_currency_label)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var source_panel := PanelContainer.new()
	source_panel.custom_minimum_size = Vector2(390.0, 472.0)
	source_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.010, 0.010, 0.009), Color(0.21, 0.17, 0.11), 1))
	body.add_child(source_panel)

	var source_root := VBoxContainer.new()
	source_root.add_theme_constant_override("separation", 5)
	source_panel.add_child(source_root)

	var equipped_title := Label.new()
	equipped_title.text = "EQUIPPED"
	equipped_title.add_theme_font_size_override("font_size", 10)
	equipped_title.add_theme_color_override("font_color", Color(0.76, 0.63, 0.37))
	source_root.add_child(equipped_title)

	var equipped_row := HBoxContainer.new()
	equipped_row.add_theme_constant_override("separation", 4)
	source_root.add_child(equipped_row)
	var craft_slot_specs: Array[Dictionary] = [
		{"key":"weapon", "label":"WEAPON"},
		{"key":"armor", "label":"ARMOR"},
		{"key":"charm", "label":"CHARM"}
	]
	for spec: Dictionary in craft_slot_specs:
		var slot_key: String = String(spec["key"])
		var button := _make_button(String(spec["label"]), _select_crafting_equipped.bind(slot_key), Vector2(120.0, 54.0))
		button.add_theme_font_size_override("font_size", 9)
		crafting_equipped_buttons[slot_key] = button
		equipped_row.add_child(button)

	var stash_divider := HSeparator.new()
	source_root.add_child(stash_divider)
	var stash_title := Label.new()
	stash_title.text = "STASH"
	stash_title.add_theme_font_size_override("font_size", 10)
	stash_title.add_theme_color_override("font_color", Color(0.76, 0.63, 0.37))
	source_root.add_child(stash_title)

	var stash_scroll := ScrollContainer.new()
	stash_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stash_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	stash_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	source_root.add_child(stash_scroll)

	crafting_stash_grid = GridContainer.new()
	crafting_stash_grid.columns = 5
	crafting_stash_grid.add_theme_constant_override("h_separation", 2)
	crafting_stash_grid.add_theme_constant_override("v_separation", 2)
	stash_scroll.add_child(crafting_stash_grid)

	var item_panel := PanelContainer.new()
	item_panel.custom_minimum_size = Vector2(360.0, 472.0)
	item_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.014, 0.013, 0.011), Color(0.24, 0.19, 0.12), 1))
	body.add_child(item_panel)

	var item_root := VBoxContainer.new()
	item_root.add_theme_constant_override("separation", 5)
	item_panel.add_child(item_root)
	var target_title := Label.new()
	target_title.text = "CRAFTING TARGET"
	target_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_title.add_theme_font_size_override("font_size", 10)
	target_title.add_theme_color_override("font_color", Color(0.76, 0.63, 0.37))
	item_root.add_child(target_title)
	item_root.add_child(HSeparator.new())

	crafting_item_label = RichTextLabel.new()
	crafting_item_label.bbcode_enabled = true
	crafting_item_label.fit_content = false
	crafting_item_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crafting_item_label.custom_minimum_size = Vector2(336.0, 420.0)
	crafting_item_label.add_theme_font_size_override("normal_font_size", 12)
	crafting_item_label.add_theme_constant_override("line_separation", 2)
	item_root.add_child(crafting_item_label)

	var actions_panel := PanelContainer.new()
	actions_panel.custom_minimum_size = Vector2(375.0, 472.0)
	actions_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.016, 0.015, 0.013), Color(0.21, 0.17, 0.11), 1))
	body.add_child(actions_panel)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	actions_panel.add_child(actions)

	var core_title := Label.new()
	core_title.text = "CORE SOCKET"
	core_title.add_theme_font_size_override("font_size", 10)
	core_title.add_theme_color_override("font_color", Color(0.76, 0.63, 0.37))
	actions.add_child(core_title)

	var core_grid := GridContainer.new()
	core_grid.columns = 2
	core_grid.add_theme_constant_override("h_separation", 4)
	core_grid.add_theme_constant_override("v_separation", 4)
	actions.add_child(core_grid)

	var core_specs: Array[Dictionary] = [
		{"id":"repeater", "label":"REPEATER"},
		{"id":"scatter", "label":"SCATTER"},
		{"id":"piercer", "label":"PIERCER"},
		{"id":"sprayer", "label":"SPRAYER"},
		{"id":"cleaver", "label":"CLEAVER"},
		{"id":"duelist", "label":"DUELIST"},
		{"id":"whirlwind", "label":"WHIRL"},
		{"id":"throwing", "label":"RECALL"}
	]
	for spec: Dictionary in core_specs:
		var core_id: String = String(spec["id"])
		var button := _make_button(String(spec["label"]), _slot_core.bind(core_id), Vector2(172.0, 31.0))
		button.add_theme_font_size_override("font_size", 9)
		core_buttons[core_id] = button
		core_grid.add_child(button)

	actions.add_child(HSeparator.new())

	var craft_title := Label.new()
	craft_title.text = "APPLY CURRENCY"
	craft_title.add_theme_font_size_override("font_size", 10)
	craft_title.add_theme_color_override("font_color", Color(0.76, 0.63, 0.37))
	actions.add_child(craft_title)

	var mutation_button := _make_button("MUTATION SHARD", _craft_mutation, Vector2(352.0, 32.0))
	crafting_buttons["mutation"] = mutation_button
	actions.add_child(mutation_button)

	var splice_button := _make_button("SPLICE SHARD", _craft_splice, Vector2(352.0, 32.0))
	crafting_buttons["splice"] = splice_button
	actions.add_child(splice_button)

	var scrap_button := _make_button("SCRAP ORB", _craft_scrap, Vector2(352.0, 32.0))
	crafting_buttons["scrap"] = scrap_button
	actions.add_child(scrap_button)

	var crown_button := _make_button("CROWN TOKEN", _craft_crown, Vector2(352.0, 32.0))
	crafting_buttons["crown"] = crown_button
	actions.add_child(crown_button)

	var hoarder_button := _make_button("HOARDER'S ORB", _craft_hoarder, Vector2(352.0, 32.0))
	crafting_buttons["hoarder"] = hoarder_button
	actions.add_child(hoarder_button)

	var chaos_button := _make_button("CHAOS TOKEN", _craft_chaos, Vector2(352.0, 32.0))
	crafting_buttons["chaos"] = chaos_button
	actions.add_child(chaos_button)

	var polish_button := _make_button("POLISH ORB", _craft_polish, Vector2(352.0, 32.0))
	crafting_buttons["polish"] = polish_button
	actions.add_child(polish_button)

	var mechanist_button := _make_button("MECHANIST'S SEAL", _craft_mechanist, Vector2(352.0, 32.0))
	crafting_buttons["mechanist"] = mechanist_button
	actions.add_child(mechanist_button)

	crafting_feedback_label = _muted_label("Choose equipped gear or an item from the stash.")
	crafting_feedback_label.custom_minimum_size = Vector2(352.0, 38.0)
	crafting_feedback_label.add_theme_font_size_override("font_size", 10)
	crafting_feedback_label.add_theme_color_override("font_color", Color(0.64, 0.55, 0.39))
	actions.add_child(crafting_feedback_label)

func _build_decision_panel() -> void:
	decision_panel = PanelContainer.new()
	decision_panel.position = Vector2(355.0, 205.0)
	decision_panel.size = Vector2(570.0, 300.0)
	decision_panel.visible = false
	hud.add_child(decision_panel)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 14)
	decision_panel.add_child(root)

	decision_title = Label.new()
	decision_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decision_title.add_theme_font_size_override("font_size", 34)
	root.add_child(decision_title)

	decision_body = Label.new()
	decision_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decision_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_body.custom_minimum_size = Vector2(520.0, 90.0)
	decision_body.add_theme_font_size_override("font_size", 18)
	root.add_child(decision_body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)

	var extract_button := _make_button("EXTRACT & BANK", _extract_run, Vector2(220.0, 55.0))
	extract_button.name = "ExtractButton"
	row.add_child(extract_button)
	var descend_button := _make_button("DESCEND", _descend, Vector2(220.0, 55.0))
	descend_button.name = "DescendButton"
	row.add_child(descend_button)

func _make_button(text_value: String, callback: Callable, min_size: Vector2 = Vector2(245.0, 42.0)) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = min_size
	button.pressed.connect(callback)
	button.add_theme_stylebox_override("normal", _arpg_button_style(false, false))
	button.add_theme_stylebox_override("hover", _arpg_button_style(false, true))
	button.add_theme_stylebox_override("pressed", _arpg_button_style(true, false))
	button.add_theme_stylebox_override("disabled", _arpg_button_style(false, false))
	button.add_theme_color_override("font_color", Color(0.79, 0.76, 0.68))
	button.add_theme_color_override("font_hover_color", Color(0.95, 0.86, 0.64))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.91, 0.66))
	button.add_theme_color_override("font_disabled_color", Color(0.39, 0.37, 0.33))
	return button

func _process(delta: float) -> void:
	_update_top_bar()

	if state == "hub":
		_process_hideout_interactions()
		return

	if state != "run" or not is_instance_valid(player) or decision_open:
		return
	if alive_enemies > 0:
		return
	room_clear_delay = maxf(0.0, room_clear_delay - delta)
	if room_clear_delay > 0.0:
		return
	if room_index >= rooms_total:
		_scoop_remaining_loot()
		_open_floor_clear()
		return
	if not room_ready_to_advance:
		room_ready_to_advance = true
		if current_room_type == "TREASURE":
			var cache_value: int = maxi(35, int(round((75.0 + float(depth) * 28.0) * _run_currency_multiplier())))
			_spawn_pickup("jackpot", cache_value, {}, ARENA_BOUNDS.get_center())
			_add_feed("TREASURE CACHE!  + a fat payout")
		_add_feed("ROOM CLEAR — grab loot, then press E")
	if Input.is_action_just_pressed("interact"):
		_advance_room()

func _process_hideout_interactions() -> void:
	if not is_instance_valid(player):
		return

	if hub_modal_open:
		interaction_prompt.visible = false
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("interact"):
			_close_hub_station()
		return

	var nearest: String = ""
	var nearest_distance: float = 99999.0
	var station_names: Array[String] = ["stash", "craft", "claim"]
	for station_name: String in station_names:
		var station_position: Vector2 = hideout.get_station_position(station_name)
		var distance: float = player.global_position.distance_to(station_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = station_name

	if nearest_distance <= 92.0:
		interaction_prompt.visible = true
		interaction_prompt.text = "[E]  %s" % hideout.get_station_prompt(nearest)
		if Input.is_action_just_pressed("interact"):
			_open_hub_station(nearest)
	else:
		interaction_prompt.visible = false

func _open_hub_station(station_name: String) -> void:
	active_hub_station = station_name
	hub_modal_open = true
	if is_instance_valid(player):
		player.set_physics_process(false)
	hub_panel.visible = station_name == "claim"
	character_panel.visible = station_name == "stash"
	gear_panel.visible = station_name == "stash"
	crafting_panel.visible = station_name == "craft"
	if station_name == "craft":
		if crafting_target_source == "none":
			if selected_stash_item_id >= 0 and _find_stash_item_index(selected_stash_item_id) >= 0:
				crafting_target_source = "stash"
			else:
				crafting_target_source = "equipped"
				crafting_target_slot = "weapon"
		_refresh_crafting_panel()
	else:
		_update_hub_ui()

func _close_hub_station() -> void:
	hub_modal_open = false
	active_hub_station = ""
	hub_panel.visible = false
	character_panel.visible = false
	gear_panel.visible = false
	crafting_panel.visible = false
	if is_instance_valid(player):
		player.set_physics_process(true)

func _enter_hub() -> void:
	state = "hub"
	decision_open = false
	hub_modal_open = false
	active_hub_station = ""
	decision_panel.visible = false
	arena.visible = false
	hideout.visible = true
	hub_panel.visible = false
	character_panel.visible = false
	gear_panel.visible = false
	crafting_panel.visible = false
	hp_bar.visible = false
	run_label.visible = false
	feed_label.visible = false
	interaction_prompt.visible = false
	_clear_runtime_nodes()
	_spawn_hideout_player()
	_update_hub_ui()
	_save_game()

func _spawn_hideout_player() -> void:
	player = LootPlayer.new()
	player.world_bounds = HIDEOUT_BOUNDS.grow(-18.0)
	player.projectile_parent = null
	player.configure(_calculate_player_stats())
	actor_layer.add_child(player)
	player.global_position = Vector2(640.0, 545.0)

func _start_claim() -> void:
	state = "run"
	hub_modal_open = false
	active_hub_station = ""
	depth = 1
	run_coins = 0
	run_seals = 0
	run_gear.clear()
	run_crafting = {"scrap": 0, "mutation": 0, "splice": 0, "crown": 0, "hoarder": 0, "chaos": 0, "polish": 0, "mechanist": 0}
	run_cores = {"repeater": 0, "scatter": 0, "piercer": 0, "sprayer": 0, "cleaver": 0, "duelist": 0, "whirlwind": 0, "throwing": 0}
	total_run_kills = 0
	feed_lines.clear()
	hub_panel.visible = false
	character_panel.visible = false
	gear_panel.visible = false
	crafting_panel.visible = false
	interaction_prompt.visible = false
	hp_bar.visible = true
	run_label.visible = true
	feed_label.visible = true
	hideout.visible = false
	arena.visible = true
	decision_panel.visible = false
	decision_open = false
	_begin_floor()

func _begin_floor() -> void:
	_clear_runtime_nodes()
	decision_panel.visible = false
	decision_open = false
	floor_kills = 0
	room_index = 1
	rooms_total = clampi(5 + rng.randi_range(0, 2) + int((depth - 1) / 3), 5, 8)
	room_ready_to_advance = false
	room_clear_delay = 0.0
	_spawn_player()
	_begin_room()
	_add_feed("Entered depth %d — %d rooms" % [depth, rooms_total])

func _spawn_player() -> void:
	player = LootPlayer.new()
	player.world_bounds = ARENA_BOUNDS.grow(-18.0)
	player.projectile_parent = projectile_layer
	player.configure(_calculate_player_stats())
	player.died.connect(_on_player_died)
	player.hp_changed.connect(_on_player_hp_changed)
	actor_layer.add_child(player)
	player.global_position = ARENA_BOUNDS.get_center()
	_on_player_hp_changed(player.hp, player.max_hp)

func _begin_room() -> void:
	room_ready_to_advance = false
	room_clear_delay = 0.0
	current_room_type = _choose_room_type()
	arena.configure_room(depth, room_index, rooms_total, current_room_type)
	if is_instance_valid(player):
		player.global_position = ARENA_BOUNDS.get_center()
	for child: Node in projectile_layer.get_children():
		child.queue_free()
	_spawn_room_enemies()
	_add_feed("Room %d/%d — %s" % [room_index, rooms_total, current_room_type])

func _choose_room_type() -> String:
	if room_index >= rooms_total:
		return "BOSS"
	var treasure_chance: float = 0.16
	if is_instance_valid(player):
		treasure_chance += player.treasure_room_bonus
	var roll: float = rng.randf()
	if roll < treasure_chance:
		return "TREASURE"
	if roll < treasure_chance + 0.18:
		return "ELITE"
	if roll < treasure_chance + 0.37:
		return "SWARM"
	return "PACK"

func _spawn_room_enemies() -> void:
	var density_mult: float = 1.0 + float(juice_density) * 0.20 + float(depth - 1) * 0.10
	var base_count: int = 4 + depth
	var spawn_count: int = maxi(3, int(round(float(base_count) * density_mult)))
	var elite_chance: float = 0.045 + float(juice_elite) * 0.035 + float(depth - 1) * 0.015

	match current_room_type:
		"SWARM":
			spawn_count = maxi(8, int(round(float(spawn_count) * 1.65)))
		"ELITE":
			spawn_count = maxi(4, spawn_count - 1)
			elite_chance += 0.38
		"TREASURE":
			spawn_count = maxi(4, spawn_count - 2)
			elite_chance += 0.10
		"BOSS":
			spawn_count = maxi(4, 4 + int(depth / 2))

	alive_enemies = spawn_count
	for i in range(spawn_count):
		var enemy := LootEnemy.new()
		var kind: int
		var elite: bool = rng.randf() < elite_chance
		match current_room_type:
			"SWARM":
				kind = 1 if rng.randf() < 0.78 else rng.randi_range(0, 3)
			"BOSS":
				if i == 0:
					kind = 2
					elite = true
				else:
					kind = rng.randi_range(0, 3)
			_:
				kind = rng.randi_range(0, 3)
		var effective_enemy_depth: int = depth + (claim_tier - 1) * 3
		enemy.configure(kind, effective_enemy_depth, elite)
		if current_room_type == "BOSS" and i == 0:
			enemy.make_boss(effective_enemy_depth)
		enemy.target = player
		enemy.projectile_parent = projectile_layer
		enemy.global_position = _random_spawn_position()
		enemy.killed.connect(_on_enemy_killed)
		actor_layer.add_child(enemy)

func _random_spawn_position() -> Vector2:
	var pos := Vector2.ZERO
	for _attempt in range(16):
		pos = Vector2(
			rng.randf_range(ARENA_BOUNDS.position.x + 38.0, ARENA_BOUNDS.end.x - 38.0),
			rng.randf_range(ARENA_BOUNDS.position.y + 38.0, ARENA_BOUNDS.end.y - 38.0)
		)
		if pos.distance_to(ARENA_BOUNDS.get_center()) > 205.0:
			break
	return pos

func _advance_room() -> void:
	if state != "run" or not room_ready_to_advance or room_index >= rooms_total:
		return
	_scoop_remaining_loot()
	room_index += 1
	_begin_room()

func _scoop_remaining_loot() -> void:
	for child: Node in loot_layer.get_children():
		if child is LootPickup:
			(child as LootPickup).collect_now()

func _on_enemy_killed(enemy: LootEnemy) -> void:
	alive_enemies = maxi(0, alive_enemies - 1)
	floor_kills += 1
	total_run_kills += 1
	if is_instance_valid(player):
		player.register_kill()
	_spawn_loot_burst(enemy.global_position, enemy.reward_scale, enemy.is_elite)
	if alive_enemies <= 0:
		room_clear_delay = 0.35

func _spawn_loot_burst(position_value: Vector2, reward_scale: float, elite: bool) -> void:
	if not is_instance_valid(player):
		return
	var currency_mult: float = _run_currency_multiplier() * (1.0 + player.currency_find / 100.0)
	if elite:
		currency_mult *= 1.0 + player.elite_currency_bonus
	else:
		currency_mult *= maxf(0.10, 1.0 - player.normal_currency_penalty)
	var quantity_mult: float = _run_quantity_multiplier() * (1.0 + player.item_find / 100.0)
	var coin_piles: int = maxi(2, int(round(rng.randf_range(2.0, 4.0) * quantity_mult * sqrt(reward_scale))))

	for _i in range(coin_piles):
		var amount: int = maxi(1, int(round(rng.randf_range(4.0, 10.0) * currency_mult * reward_scale * (1.0 + float(depth - 1) * 0.22))))
		_spawn_pickup("coin", amount, {}, position_value)

	var seal_chance: float = 0.045 * quantity_mult * (2.5 if elite else 1.0)
	if rng.randf() < seal_chance:
		_spawn_pickup("seal", 1, {}, position_value)

	var jackpot_chance: float = 0.0025 * quantity_mult * (4.0 if elite else 1.0)
	if rng.randf() < jackpot_chance:
		var jackpot_value: int = maxi(125, int(round(rng.randf_range(180.0, 420.0) * reward_scale * _run_currency_multiplier() * (1.0 + float(depth - 1) * 0.35))))
		_spawn_pickup("jackpot", jackpot_value, {}, position_value)

	_spawn_crafting_currency_rolls(position_value, quantity_mult, elite)
	_spawn_core_roll(position_value, quantity_mult, elite)

	var gear_chance: float = 0.10 * quantity_mult * reward_scale
	gear_chance = minf(0.68, gear_chance)
	if rng.randf() < gear_chance:
		var gear_item: Dictionary = _generate_gear(depth, elite)
		_spawn_pickup("gear", 1, gear_item, position_value)
		if player.gear_duplicate_chance > 0.0 and rng.randf() < player.gear_duplicate_chance:
			var bonus_gear: Dictionary = _generate_gear(depth, elite)
			_spawn_pickup("gear", 1, bonus_gear, position_value + Vector2(14.0, 0.0))
			_add_feed("DOUBLE DROP!")

func _spawn_crafting_currency_rolls(position_value: Vector2, quantity_mult: float, elite: bool) -> void:
	var elite_mult: float = 2.5 if elite else 1.0
	if rng.randf() < 0.028 * quantity_mult * elite_mult:
		_spawn_pickup("craft", 1, {"currency":"scrap"}, position_value)
	if rng.randf() < 0.012 * quantity_mult * (2.7 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"mutation"}, position_value)
	if rng.randf() < 0.010 * quantity_mult * (2.8 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"splice"}, position_value)
	if claim_tier >= 2 and rng.randf() < 0.0040 * quantity_mult * (3.2 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"crown"}, position_value)
	if claim_tier >= 2 and rng.randf() < 0.0022 * quantity_mult * (3.8 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"hoarder"}, position_value)
	if claim_tier >= 2 and rng.randf() < 0.0025 * quantity_mult * (4.0 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"chaos"}, position_value)
	if claim_tier >= 3 and rng.randf() < 0.0010 * quantity_mult * (4.5 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"polish"}, position_value)
	if claim_tier >= 3 and rng.randf() < 0.0008 * quantity_mult * (5.0 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"mechanist"}, position_value)

func _spawn_core_roll(position_value: Vector2, quantity_mult: float, elite: bool) -> void:
	var chance: float = 0.035 * quantity_mult * (2.8 if elite else 1.0)
	if rng.randf() >= chance:
		return
	var core_ids: Array[String] = ["repeater", "scatter", "piercer", "sprayer", "cleaver", "duelist", "whirlwind", "throwing"]
	var core_id: String = core_ids[rng.randi_range(0, core_ids.size() - 1)]
	_spawn_pickup("core", 1, {"core": core_id}, position_value)

func _spawn_pickup(type_value: String, amount_value: int, gear_value: Dictionary, position_value: Vector2) -> void:
	var pickup := LootPickup.new()
	pickup.loot_type = type_value
	pickup.amount = amount_value
	pickup.gear = gear_value
	pickup.player = player
	# Enemy deaths can happen inside a physics body_entered callback. Adding an
	# Area2D with a CollisionShape2D immediately during that callback makes the
	# physics server change shape state while it is flushing queries. Store the
	# desired local position and add the pickup after the physics flush instead.
	pickup.position = loot_layer.to_local(position_value)
	pickup.velocity = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(110.0, 260.0)
	pickup.collected.connect(_on_loot_collected)
	call_deferred("_add_pickup_deferred", pickup)

func _add_pickup_deferred(pickup: LootPickup) -> void:
	if not is_instance_valid(pickup):
		return
	if state != "run" or not is_instance_valid(player):
		pickup.queue_free()
		return
	loot_layer.add_child(pickup)

func _on_loot_collected(pickup: LootPickup) -> void:
	match pickup.loot_type:
		"coin":
			run_coins += pickup.amount
		"seal":
			run_seals += pickup.amount
			_add_feed("+1 Seal")
		"jackpot":
			run_coins += pickup.amount
			_add_feed("JACKPOT!  +₵%d" % pickup.amount)
		"craft":
			var currency_key: String = String(pickup.gear.get("currency", "scrap"))
			run_crafting[currency_key] = int(run_crafting.get(currency_key, 0)) + pickup.amount
			_add_feed("+%s" % _craft_currency_name(currency_key))
		"core":
			var core_id: String = String(pickup.gear.get("core", "repeater"))
			run_cores[core_id] = int(run_cores.get(core_id, 0)) + pickup.amount
			_add_feed("%s CORE!" % _core_name(core_id).to_upper())
		"gear":
			run_gear.append(pickup.gear.duplicate(true))
			if is_instance_valid(player):
				player.register_gear_pickup()
			var drop_rarity: String = String(pickup.gear.get("rarity", "Common"))
			if drop_rarity == "Gilded":
				_add_feed("GILDED DROP!  %s  (~₵%d)" % [String(pickup.gear.get("name", "Item")), int(pickup.gear.get("value", 0))])
			else:
				_add_feed("%s: %s  (~₵%d)" % [drop_rarity.to_upper(), String(pickup.gear.get("name", "Item")), int(pickup.gear.get("value", 0))])

func _open_floor_clear() -> void:
	decision_open = true
	decision_panel.visible = true
	decision_title.text = "TIER %d  •  DEPTH %d CLEARED" % [claim_tier, depth]
	decision_body.text = "Unsecured: ₵%d + %d Seals + %d gear + %d mats + %d Cores\nEstimated run value: ₵%d\n\nExtract and bank it, or descend for more." % [run_coins, run_seals, run_gear.size(), _crafting_inventory_count(run_crafting), _core_inventory_count(run_cores), _current_run_value()]
	_set_decision_buttons(true, true)

func _descend() -> void:
	if state != "run":
		return
	depth += 1
	_begin_floor()

func _extract_run() -> void:
	if state != "run":
		return
	_record_successful_extraction()
	stash_coins += run_coins
	stash_seals += run_seals
	for currency_key_variant: Variant in run_crafting.keys():
		var currency_key: String = String(currency_key_variant)
		stash_crafting[currency_key] = int(stash_crafting.get(currency_key, 0)) + int(run_crafting.get(currency_key, 0))
	for core_key_variant: Variant in run_cores.keys():
		var core_key: String = String(core_key_variant)
		stash_cores[core_key] = int(stash_cores.get(core_key, 0)) + int(run_cores.get(core_key, 0))
	for item in run_gear:
		stash_gear.append(item.duplicate(true))
	_add_feed("Banked ₵%d" % _current_run_value())
	run_coins = 0
	run_seals = 0
	run_gear.clear()
	run_crafting = {"scrap": 0, "mutation": 0, "splice": 0, "crown": 0, "hoarder": 0, "chaos": 0, "polish": 0, "mechanist": 0}
	run_cores = {"repeater": 0, "scatter": 0, "piercer": 0, "sprayer": 0, "cleaver": 0, "duelist": 0, "whirlwind": 0, "throwing": 0}
	_clear_juice()
	_enter_hub()

func _on_player_died() -> void:
	if state != "run":
		return
	state = "dead"
	decision_open = true
	alive_enemies = 0
	for child in actor_layer.get_children():
		if child is LootEnemy:
			child.queue_free()
	for child in loot_layer.get_children():
		child.queue_free()
	decision_panel.visible = true
	decision_title.text = "YOU GOT GREEDY"
	decision_body.text = "The unsecured haul was lost.\n\nLost: ₵%d + %d Seals + %d gear + %d mats + %d Cores\nReached depth %d after %d kills." % [run_coins, run_seals, run_gear.size(), _crafting_inventory_count(run_crafting), _core_inventory_count(run_cores), depth, total_run_kills]
	run_coins = 0
	run_seals = 0
	run_gear.clear()
	run_crafting = {"scrap": 0, "mutation": 0, "splice": 0, "crown": 0, "hoarder": 0, "chaos": 0, "polish": 0, "mechanist": 0}
	run_cores = {"repeater": 0, "scatter": 0, "piercer": 0, "sprayer": 0, "cleaver": 0, "duelist": 0, "whirlwind": 0, "throwing": 0}
	_set_decision_buttons(false, false)

	var root := decision_panel.get_child(0) as VBoxContainer
	var row := root.get_child(2) as HBoxContainer
	var return_button: Button = row.get_node_or_null("ReturnButton") as Button
	if return_button == null:
		return_button = _make_button("RETURN TO HIDEOUT", _return_after_death, Vector2(280.0, 55.0))
		return_button.name = "ReturnButton"
		row.add_child(return_button)
	return_button.visible = true

func _return_after_death() -> void:
	var root := decision_panel.get_child(0) as VBoxContainer
	var row := root.get_child(2) as HBoxContainer
	var return_button: Button = row.get_node_or_null("ReturnButton") as Button
	if return_button != null:
		return_button.visible = false
	_clear_juice()
	_enter_hub()

func _set_decision_buttons(show_extract: bool, show_descend: bool) -> void:
	var root := decision_panel.get_child(0) as VBoxContainer
	var row := root.get_child(2) as HBoxContainer
	var extract_button: Button = row.get_node("ExtractButton") as Button
	var descend_button: Button = row.get_node("DescendButton") as Button
	extract_button.visible = show_extract
	descend_button.visible = show_descend
	var return_button: Button = row.get_node_or_null("ReturnButton") as Button
	if return_button != null:
		return_button.visible = false

func _on_player_hp_changed(current_hp: float, maximum_hp: float) -> void:
	hp_bar.max_value = maximum_hp
	hp_bar.value = current_hp

func _run_quantity_multiplier() -> float:
	return 1.0 + float(juice_quantity) * 0.25 + float(depth - 1) * 0.22 + float(claim_tier - 1) * 0.06

func _run_currency_multiplier() -> float:
	return 1.0 + float(juice_currency) * 0.25 + float(depth - 1) * 0.20 + float(claim_tier - 1) * 0.18

func _current_run_value() -> int:
	var value: int = run_coins + run_seals * 100 + _crafting_inventory_value(run_crafting) + _core_inventory_value(run_cores)
	for item in run_gear:
		value += int(item.get("value", 0))
	return value

func _calculate_net_worth() -> int:
	var value: int = stash_coins + stash_seals * 100 + _crafting_inventory_value(stash_crafting) + _core_inventory_value(stash_cores)
	for item in stash_gear:
		value += int(item.get("value", 0))
	var gear_slots: Array[String] = ["weapon", "armor", "charm"]
	for slot_name: String in gear_slots:
		var item_value: Dictionary = equipped.get(slot_name, {}) as Dictionary
		value += int(item_value.get("value", 0))
	return value

func _calculate_player_stats() -> Dictionary:
	var stats: Dictionary = {
		"damage": 18.0,
		"attack_speed": 4.0,
		"max_hp": 100.0,
		"move_speed": 270.0,
		"currency_find": 0.0,
		"item_find": 0.0,
		"weapon_archetype": "gun",
		"weapon_core": "repeater",
		"dash_cooldown_mult": 1.0,
		"pickup_radius": 145.0,
		"gear_pickup_heal": 0.0,
		"kill_heal": 0.0,
		"damage_taken_mult": 1.0,
		"hurt_speed_bonus": 0.0,
		"hurt_speed_duration": 0.0,
		"point_blank_bonus": 0.0,
		"point_blank_range": 125.0,
		"knockback_mult": 1.0,
		"projectile_radius_mult": 1.0,
		"bonus_pierce": 0,
		"bonus_projectiles": 0,
		"projectile_damage_mult": 1.0,
		"ricochet_count": 0,
		"frenzy_on_kill": false,
		"explosion_fraction": 0.0,
		"treasure_room_bonus": 0.0,
		"elite_currency_bonus": 0.0,
		"normal_currency_penalty": 0.0,
		"gear_duplicate_chance": 0.0,
		"cheat_death": false,
		"max_hp_mult": 1.0,
		"move_speed_mult": 1.0,
		"melee_damage_mult": 1.0,
		"melee_range_mult": 1.0
	}
	var gear_slots: Array[String] = ["weapon", "armor", "charm"]
	for slot_name: String in gear_slots:
		var item: Dictionary = equipped.get(slot_name, {}) as Dictionary
		stats["damage"] = float(stats["damage"]) + float(item.get("damage", 0.0))
		stats["attack_speed"] = float(stats["attack_speed"]) + float(item.get("attack_speed", 0.0))
		stats["max_hp"] = float(stats["max_hp"]) + float(item.get("max_hp", 0.0))
		stats["move_speed"] = float(stats["move_speed"]) + float(item.get("move_speed", 0.0))
		stats["currency_find"] = float(stats["currency_find"]) + float(item.get("currency_find", 0.0))
		stats["item_find"] = float(stats["item_find"]) + float(item.get("item_find", 0.0))
		if slot_name == "weapon" and not item.is_empty():
			stats["weapon_archetype"] = String(item.get("weapon_archetype", "gun"))
			stats["weapon_core"] = String(item.get("core_id", item.get("weapon_type", "repeater")))
		_apply_item_mechanics_to_stats(stats, item)

	if String(stats.get("weapon_archetype", "gun")) == "blade":
		stats["damage_taken_mult"] = float(stats["damage_taken_mult"]) * 0.82
		stats["dash_cooldown_mult"] = float(stats["dash_cooldown_mult"]) * 0.90
	stats["max_hp"] = float(stats["max_hp"]) * float(stats["max_hp_mult"])
	stats["move_speed"] = float(stats["move_speed"]) * float(stats["move_speed_mult"])
	return stats

func _calculate_player_stats_with_override(override_slot: String, override_item: Dictionary) -> Dictionary:
	var stats: Dictionary = {
		"damage": 18.0,
		"attack_speed": 4.0,
		"max_hp": 100.0,
		"move_speed": 270.0,
		"currency_find": 0.0,
		"item_find": 0.0,
		"weapon_archetype": "gun",
		"weapon_core": "repeater",
		"dash_cooldown_mult": 1.0,
		"pickup_radius": 145.0,
		"gear_pickup_heal": 0.0,
		"kill_heal": 0.0,
		"damage_taken_mult": 1.0,
		"hurt_speed_bonus": 0.0,
		"hurt_speed_duration": 0.0,
		"point_blank_bonus": 0.0,
		"point_blank_range": 125.0,
		"knockback_mult": 1.0,
		"projectile_radius_mult": 1.0,
		"bonus_pierce": 0,
		"bonus_projectiles": 0,
		"projectile_damage_mult": 1.0,
		"ricochet_count": 0,
		"frenzy_on_kill": false,
		"explosion_fraction": 0.0,
		"treasure_room_bonus": 0.0,
		"elite_currency_bonus": 0.0,
		"normal_currency_penalty": 0.0,
		"gear_duplicate_chance": 0.0,
		"cheat_death": false,
		"max_hp_mult": 1.0,
		"move_speed_mult": 1.0,
		"melee_damage_mult": 1.0,
		"melee_range_mult": 1.0
	}
	var gear_slots: Array[String] = ["weapon", "armor", "charm"]
	for slot_name: String in gear_slots:
		var item: Dictionary = override_item if slot_name == override_slot else (equipped.get(slot_name, {}) as Dictionary)
		stats["damage"] = float(stats["damage"]) + float(item.get("damage", 0.0))
		stats["attack_speed"] = float(stats["attack_speed"]) + float(item.get("attack_speed", 0.0))
		stats["max_hp"] = float(stats["max_hp"]) + float(item.get("max_hp", 0.0))
		stats["move_speed"] = float(stats["move_speed"]) + float(item.get("move_speed", 0.0))
		stats["currency_find"] = float(stats["currency_find"]) + float(item.get("currency_find", 0.0))
		stats["item_find"] = float(stats["item_find"]) + float(item.get("item_find", 0.0))
		if slot_name == "weapon" and not item.is_empty():
			stats["weapon_archetype"] = String(item.get("weapon_archetype", "gun"))
			stats["weapon_core"] = String(item.get("core_id", item.get("weapon_type", "repeater")))
		_apply_item_mechanics_to_stats(stats, item)

	if String(stats.get("weapon_archetype", "gun")) == "blade":
		stats["damage_taken_mult"] = float(stats["damage_taken_mult"]) * 0.82
		stats["dash_cooldown_mult"] = float(stats["dash_cooldown_mult"]) * 0.90
	stats["max_hp"] = float(stats["max_hp"]) * float(stats["max_hp_mult"])
	stats["move_speed"] = float(stats["move_speed"]) * float(stats["move_speed_mult"])
	return stats

func _weapon_output_bbcode(item: Dictionary) -> String:
	var stats: Dictionary = _calculate_player_stats_with_override("weapon", item)
	var archetype: String = String(stats.get("weapon_archetype", "gun"))
	if archetype == "blade":
		return _blade_output_bbcode(item, stats)

	var core_id: String = String(stats.get("weapon_core", "repeater"))
	var base_damage: float = float(stats.get("damage", 18.0))
	var projectile_mult: float = float(stats.get("projectile_damage_mult", 1.0))
	var bonus_projectiles: int = int(stats.get("bonus_projectiles", 0))
	var attack_speed: float = float(stats.get("attack_speed", 4.0))
	var hit_damage: float = base_damage * projectile_mult
	var projectiles_per_attack: int = 1 + bonus_projectiles
	var rate_mult: float = 1.0
	var hit_label: String = "HIT"
	var attack_label: String = "VOLLEY"

	match core_id:
		"scatter":
			hit_damage = base_damage * 0.42 * projectile_mult
			projectiles_per_attack = 5 + bonus_projectiles * 2
			rate_mult = 0.42
			hit_label = "PELLET"
			attack_label = "FULL BLAST"
		"piercer":
			hit_damage = base_damage * 2.40 * projectile_mult
			rate_mult = 0.35
		"sprayer":
			hit_damage = base_damage * 0.52 * projectile_mult
			rate_mult = 1.80
			hit_label = "BULLET"
		_:
			pass

	var attacks_per_second: float = attack_speed * rate_mult
	var attack_damage: float = hit_damage * float(projectiles_per_attack)
	var sheet_dps: float = attack_damage * attacks_per_second
	var current_weapon: Dictionary = equipped.get("weapon", {}) as Dictionary
	var current_dps: float = _weapon_sheet_dps_for_item(current_weapon)
	var dps_delta: float = sheet_dps - current_dps
	var delta_text: String = _weapon_dps_delta_text(item, dps_delta)

	var text: String = "[color=#777f8d][font_size=11]WEAPON OUTPUT[/font_size][/color]"
	text += "\n[font_size=22][b]%.1f DPS[/b][/font_size]%s" % [sheet_dps, delta_text]
	text += "\n[color=#9aa2ae]%s[/color] [b]%.1f[/b]    [color=#9aa2ae]%s[/color] [b]%.1f[/b]" % [hit_label, hit_damage, attack_label, attack_damage]
	text += "\n[color=#9aa2ae]ATTACK RATE[/color] [b]%.2f/s[/b]" % attacks_per_second
	if projectiles_per_attack > 1:
		text += "    [color=#9aa2ae]PROJECTILES[/color] [b]%d[/b]" % projectiles_per_attack
	return text

func _blade_output_bbcode(item: Dictionary, stats: Dictionary) -> String:
	var core_id: String = String(stats.get("weapon_core", "cleaver"))
	var base_damage: float = float(stats.get("damage", 18.0))
	var melee_mult: float = float(stats.get("melee_damage_mult", 1.0))
	var range_mult: float = float(stats.get("melee_range_mult", 1.0))
	var attack_speed: float = float(stats.get("attack_speed", 4.0))
	var hit_damage: float = base_damage * melee_mult
	var rate_mult: float = 1.0
	var reach: float = 98.0 * range_mult
	var shape_text: String = "105° ARC"

	match core_id:
		"duelist":
			hit_damage *= 1.18
			rate_mult = 1.42
			reach = 132.0 * range_mult
			shape_text = "35° STAB"
		"whirlwind":
			hit_damage *= 1.05
			rate_mult = 0.70
			reach = 94.0 * range_mult
			shape_text = "360° SPIN"
		"throwing":
			hit_damage *= 1.15
			rate_mult = 0.80
			reach = 310.0 * range_mult
			shape_text = "OUT + RETURN"
		_:
			hit_damage *= 1.70
			rate_mult = 0.78

	var attacks_per_second: float = attack_speed * rate_mult
	var sheet_dps: float = hit_damage * attacks_per_second
	var current_weapon: Dictionary = equipped.get("weapon", {}) as Dictionary
	var current_dps: float = _weapon_sheet_dps_for_item(current_weapon)
	var dps_delta: float = sheet_dps - current_dps
	var delta_text: String = _weapon_dps_delta_text(item, dps_delta)

	var text: String = "[color=#777f8d][font_size=11]BLADE OUTPUT[/font_size][/color]"
	text += "\n[font_size=22][b]%.1f DPS[/b][/font_size]%s" % [sheet_dps, delta_text]
	text += "\n[color=#9aa2ae]HIT[/color] [b]%.1f[/b]    [color=#9aa2ae]RATE[/color] [b]%.2f/s[/b]" % [hit_damage, attacks_per_second]
	text += "\n[color=#9aa2ae]PATTERN[/color] [b]%s[/b]" % shape_text
	if reach > 0.0:
		text += "    [color=#9aa2ae]REACH[/color] [b]%.0f[/b]" % reach
	return text

func _weapon_dps_delta_text(item: Dictionary, dps_delta: float) -> String:
	var current_weapon: Dictionary = equipped.get("weapon", {}) as Dictionary
	if current_weapon.is_empty() or int(current_weapon.get("id", -999)) == int(item.get("id", -1)) or absf(dps_delta) < 0.05:
		return ""
	var delta_color: String = "#72df8b" if dps_delta > 0.0 else "#ff6d79"
	return "  [color=%s](%+.1f)[/color]" % [delta_color, dps_delta]

func _weapon_sheet_dps_for_item(item: Dictionary) -> float:
	if item.is_empty():
		return 0.0
	return _weapon_sheet_dps_from_stats(_calculate_player_stats_with_override("weapon", item))

func _armor_output_bbcode(item: Dictionary) -> String:
	var candidate: Dictionary = _calculate_player_stats_with_override("armor", item)
	var current: Dictionary = _calculate_player_stats()

	var hp: float = float(candidate.get("max_hp", 100.0))
	var current_hp: float = float(current.get("max_hp", 100.0))
	var move: float = float(candidate.get("move_speed", 270.0))
	var current_move: float = float(current.get("move_speed", 270.0))
	var dash: float = 0.85 * float(candidate.get("dash_cooldown_mult", 1.0))
	var current_dash: float = 0.85 * float(current.get("dash_cooldown_mult", 1.0))
	var taken_pct: float = float(candidate.get("damage_taken_mult", 1.0)) * 100.0
	var current_taken_pct: float = float(current.get("damage_taken_mult", 1.0)) * 100.0

	var text: String = "[color=#777f8d][font_size=11]ARMOR OUTPUT[/font_size][/color]"
	text += "\n[font_size=20][b]%.0f MAX HP[/b][/font_size]%s" % [hp, _output_delta(hp, current_hp, false, false)]
	text += "\n[color=#9aa2ae]MOVE[/color] [b]%.0f[/b]%s" % [move, _output_delta(move, current_move, false, false)]
	text += "\n[color=#9aa2ae]DASH[/color] [b]%.2fs[/b]%s" % [dash, _output_delta(dash, current_dash, true, true)]
	text += "    [color=#9aa2ae]DMG TAKEN[/color] [b]%.0f%%[/b]%s" % [taken_pct, _output_delta(taken_pct, current_taken_pct, true, false)]

	var currency_find: float = float(candidate.get("currency_find", 0.0))
	var current_currency_find: float = float(current.get("currency_find", 0.0))
	var item_find: float = float(candidate.get("item_find", 0.0))
	var current_item_find: float = float(current.get("item_find", 0.0))
	if absf(currency_find - current_currency_find) >= 0.05 or absf(item_find - current_item_find) >= 0.05:
		text += "\n[color=#9aa2ae]FIND[/color] [b]%.1f%% C[/b]%s   [b]%.1f%% I[/b]%s" % [currency_find, _output_delta(currency_find, current_currency_find, false, false), item_find, _output_delta(item_find, current_item_find, false, false)]
	return text

func _charm_output_bbcode(item: Dictionary) -> String:
	var candidate: Dictionary = _calculate_player_stats_with_override("charm", item)
	var current: Dictionary = _calculate_player_stats()

	var candidate_dps: float = _weapon_sheet_dps_from_stats(candidate)
	var current_dps: float = _weapon_sheet_dps_from_stats(current)
	var hp: float = float(candidate.get("max_hp", 100.0))
	var current_hp: float = float(current.get("max_hp", 100.0))
	var move: float = float(candidate.get("move_speed", 270.0))
	var current_move: float = float(current.get("move_speed", 270.0))
	var currency_find: float = float(candidate.get("currency_find", 0.0))
	var current_currency_find: float = float(current.get("currency_find", 0.0))
	var item_find: float = float(candidate.get("item_find", 0.0))
	var current_item_find: float = float(current.get("item_find", 0.0))

	var text: String = "[color=#777f8d][font_size=11]CHARM OUTPUT[/font_size][/color]"
	text += "\n[font_size=20][b]%.1f DPS[/b][/font_size]%s" % [candidate_dps, _output_delta(candidate_dps, current_dps, false, false)]
	text += "\n[color=#9aa2ae]MAX HP[/color] [b]%.0f[/b]%s    [color=#9aa2ae]MOVE[/color] [b]%.0f[/b]%s" % [hp, _output_delta(hp, current_hp, false, false), move, _output_delta(move, current_move, false, false)]
	text += "\n[color=#9aa2ae]CURRENCY FIND[/color] [b]%.1f%%[/b]%s" % [currency_find, _output_delta(currency_find, current_currency_find, false, false)]
	text += "\n[color=#9aa2ae]ITEM FIND[/color] [b]%.1f%%[/b]%s" % [item_find, _output_delta(item_find, current_item_find, false, false)]
	return text

func _output_delta(value: float, current_value: float, lower_is_better: bool = false, two_decimals: bool = false) -> String:
	var delta: float = value - current_value
	if absf(delta) < 0.005:
		return ""
	var beneficial: bool = delta < 0.0 if lower_is_better else delta > 0.0
	var color_hex: String = "#72df8b" if beneficial else "#ff6d79"
	var formatted: String = "%+.2f" % delta if two_decimals else "%+.1f" % delta
	if not two_decimals and absf(delta - round(delta)) < 0.01:
		formatted = "%+.0f" % delta
	return " [color=%s](%s)[/color]" % [color_hex, formatted]

func _weapon_sheet_dps_from_stats(stats: Dictionary) -> float:
	var archetype: String = String(stats.get("weapon_archetype", "gun"))
	var core_id: String = String(stats.get("weapon_core", "repeater"))
	var base_damage: float = float(stats.get("damage", 18.0))
	var attacks_per_second: float = float(stats.get("attack_speed", 4.0))

	if archetype == "blade":
		var hit_damage: float = base_damage * float(stats.get("melee_damage_mult", 1.0))
		match core_id:
			"duelist":
				hit_damage *= 1.18
				attacks_per_second *= 1.42
			"whirlwind":
				hit_damage *= 1.05
				attacks_per_second *= 0.70
			"throwing":
				hit_damage *= 2.30
				attacks_per_second *= 0.80
			_:
				hit_damage *= 1.70
				attacks_per_second *= 0.78
		return hit_damage * attacks_per_second

	var projectile_mult: float = float(stats.get("projectile_damage_mult", 1.0))
	var bonus_projectiles: int = int(stats.get("bonus_projectiles", 0))
	var hit_damage: float = base_damage * projectile_mult
	var projectile_count: int = 1 + bonus_projectiles
	match core_id:
		"scatter":
			hit_damage = base_damage * 0.42 * projectile_mult
			projectile_count = 5 + bonus_projectiles * 2
			attacks_per_second *= 0.42
		"piercer":
			hit_damage = base_damage * 2.40 * projectile_mult
			attacks_per_second *= 0.35
		"sprayer":
			hit_damage = base_damage * 0.52 * projectile_mult
			attacks_per_second *= 1.80
		_:
			pass
	return hit_damage * float(projectile_count) * attacks_per_second

func _apply_item_mechanics_to_stats(stats: Dictionary, item: Dictionary) -> void:
	var mechanics_variant: Variant = item.get("mechanics", [])
	if typeof(mechanics_variant) != TYPE_ARRAY:
		return
	for mechanic_variant: Variant in mechanics_variant as Array:
		if typeof(mechanic_variant) != TYPE_DICTIONARY:
			continue
		var mechanic: Dictionary = mechanic_variant as Dictionary
		match String(mechanic.get("id", "")):
			"point_blank":
				stats["point_blank_bonus"] = maxf(float(stats["point_blank_bonus"]), 0.45)
			"heavy_rounds":
				stats["knockback_mult"] = float(stats["knockback_mult"]) * 1.90
				stats["projectile_radius_mult"] = float(stats["projectile_radius_mult"]) * 1.15
			"quickstep":
				stats["dash_cooldown_mult"] = float(stats["dash_cooldown_mult"]) * 0.78
			"adrenaline_lining":
				stats["hurt_speed_bonus"] = maxf(float(stats["hurt_speed_bonus"]), 0.35)
				stats["hurt_speed_duration"] = maxf(float(stats["hurt_speed_duration"]), 1.20)
			"magnet_heart":
				stats["pickup_radius"] = float(stats["pickup_radius"]) + 140.0
			"field_medic":
				stats["gear_pickup_heal"] = float(stats["gear_pickup_heal"]) + 8.0
			"split_chamber":
				stats["bonus_projectiles"] = int(stats["bonus_projectiles"]) + 1
				stats["projectile_damage_mult"] = float(stats["projectile_damage_mult"]) * 0.72
			"bore_rounds":
				stats["bonus_pierce"] = int(stats["bonus_pierce"]) + 2
			"second_wind":
				stats["kill_heal"] = float(stats["kill_heal"]) + 1.5
			"hoarders_bargain":
				stats["currency_find"] = float(stats["currency_find"]) + 25.0
				stats["max_hp_mult"] = float(stats["max_hp_mult"]) * 0.85
			"ricochet":
				stats["ricochet_count"] = int(stats["ricochet_count"]) + 1
			"kill_frenzy":
				stats["frenzy_on_kill"] = true
			"armored_greed":
				stats["item_find"] = float(stats["item_find"]) + 20.0
				stats["damage_taken_mult"] = float(stats["damage_taken_mult"]) * 1.15
			"treasure_scent":
				stats["treasure_room_bonus"] = float(stats["treasure_room_bonus"]) + 0.07
			"explosive_rounds":
				stats["explosion_fraction"] = maxf(float(stats["explosion_fraction"]), 0.45)
			"glass_rat":
				stats["move_speed_mult"] = float(stats["move_speed_mult"]) * 1.30
				stats["max_hp_mult"] = float(stats["max_hp_mult"]) * 0.75
			"elite_tax":
				stats["elite_currency_bonus"] = float(stats["elite_currency_bonus"]) + 0.50
				stats["normal_currency_penalty"] = float(stats["normal_currency_penalty"]) + 0.15
			"kings_barrage":
				stats["bonus_projectiles"] = int(stats["bonus_projectiles"]) + 2
				stats["projectile_damage_mult"] = float(stats["projectile_damage_mult"]) * 0.62
			"dead_mans_insurance":
				stats["cheat_death"] = true
			"hoarders_curse":
				stats["currency_find"] = float(stats["currency_find"]) + 60.0
				stats["damage_taken_mult"] = float(stats["damage_taken_mult"]) * 1.30
			"double_drop":
				stats["gear_duplicate_chance"] = float(stats["gear_duplicate_chance"]) + 0.10
			"keen_edge":
				stats["melee_damage_mult"] = float(stats["melee_damage_mult"]) * 1.18
			"long_reach":
				stats["melee_range_mult"] = float(stats["melee_range_mult"]) * 1.22
			"brutal_edge":
				stats["knockback_mult"] = float(stats["knockback_mult"]) * 1.65

func _generate_gear(item_depth: int, from_elite: bool) -> Dictionary:
	var gear_slots: Array[String] = ["weapon", "armor", "charm"]
	var slot: String = gear_slots[rng.randi_range(0, gear_slots.size() - 1)]
	var item_level: int = maxi(1, 1 + (claim_tier - 1) * 4 + (item_depth - 1) + (1 if from_elite else 0))
	var rarity: String = _roll_item_rarity(item_depth, from_elite)
	var base: Dictionary = _roll_item_base(slot)

	var item: Dictionary = {
		"id": next_item_id,
		"slot": slot,
		"rarity": rarity,
		"depth": item_depth,
		"item_level": item_level,
		"base_name": String(base.get("name", "Gear")),
		"weapon_archetype": String(base.get("weapon_archetype", "")) if slot == "weapon" else "",
		"core_id": _random_core_for_archetype(String(base.get("weapon_archetype", "gun"))) if slot == "weapon" else "",
		"damage": 0.0,
		"attack_speed": 0.0,
		"max_hp": 0.0,
		"move_speed": 0.0,
		"currency_find": 0.0,
		"item_find": 0.0,
		"implicit": {},
		"affixes": [],
		"mechanics": []
	}
	next_item_id += 1

	var implicit_stat: String = String(base.get("implicit_stat", ""))
	var implicit_value: float = float(base.get("implicit_value", 0.0))
	if not implicit_stat.is_empty() and implicit_value != 0.0:
		_apply_item_stat(item, implicit_stat, implicit_value)
		item["implicit"] = {
			"stat": implicit_stat,
			"value": implicit_value,
			"label": _stat_label(implicit_stat)
		}

	var affix_count: int = 0
	var mechanic_count: int = 0
	match rarity:
		"Magic":
			affix_count = 1
			mechanic_count = 1
		"Rare":
			affix_count = 2
			mechanic_count = 1
		"Gilded":
			affix_count = 3
			mechanic_count = 2

	var mechanics: Array[Dictionary] = []
	var used_mechanics: Array[String] = []
	for mechanic_index in range(mechanic_count):
		var prefer_high: bool = rarity == "Gilded" and mechanic_index == 0
		var rolled_mechanic: Dictionary = _roll_mechanic(slot, used_mechanics, prefer_high, String(item.get("weapon_archetype", "")))
		if rolled_mechanic.is_empty():
			break
		mechanics.append(rolled_mechanic)
		used_mechanics.append(String(rolled_mechanic.get("id", "")))
	item["mechanics"] = mechanics

	var candidates: Array[String] = _affix_candidates(slot)
	var used_stats: Array[String] = []
	var affixes: Array[Dictionary] = []

	# Gilded items always carry one greed-oriented affix so they are chase loot,
	# not merely a fourth random stat.
	if rarity == "Gilded":
		var greed_stat: String = "currency_find" if rng.randf() < 0.55 else "item_find"
		var greed_tier: int = _roll_affix_tier(item_depth)
		var greed_value: float = _roll_affix_value(greed_stat, greed_tier)
		_apply_item_stat(item, greed_stat, greed_value)
		affixes.append(_make_affix_record(greed_stat, greed_tier, greed_value))
		used_stats.append(greed_stat)

	while affixes.size() < affix_count:
		var available: Array[String] = []
		for candidate: String in candidates:
			if not used_stats.has(candidate):
				available.append(candidate)
		if available.is_empty():
			break
		var stat: String = available[rng.randi_range(0, available.size() - 1)]
		var tier: int = _roll_affix_tier(item_depth)
		var value: float = _roll_affix_value(stat, tier)
		_apply_item_stat(item, stat, value)
		affixes.append(_make_affix_record(stat, tier, value))
		used_stats.append(stat)

	item["affixes"] = affixes
	item["name"] = _make_generated_item_name(item)
	item["value"] = _item_value(item)
	return item

func _roll_item_rarity(item_depth: int, from_elite: bool) -> String:
	# Claim Tier is a hard eligibility gate. Depth can improve odds, but it
	# cannot cause an early Claim to leak later progression rewards.
	var depth_bonus: float = float(maxi(0, item_depth - 1))
	var rare_chance: float = 0.0
	var gilded_chance: float = 0.0
	var magic_chance: float = 0.30

	match claim_tier:
		1:
			# T1 is deliberately humble: Common gear and increasingly frequent
			# Magic gear. Rare is impossible regardless of how deep you descend.
			magic_chance = minf(0.62, 0.28 + depth_bonus * 0.055 + (0.10 if from_elite else 0.0))
		2:
			magic_chance = minf(0.68, 0.38 + depth_bonus * 0.045 + (0.10 if from_elite else 0.0))
			# Even after T2 is earned, a Rare cannot appear on Depth 1.
			if item_depth >= 2:
				rare_chance = minf(0.11, 0.012 + float(item_depth - 2) * 0.014 + (0.035 if from_elite else 0.0))
		3:
			magic_chance = minf(0.70, 0.42 + depth_bonus * 0.035 + (0.08 if from_elite else 0.0))
			if item_depth >= 2:
				rare_chance = minf(0.20, 0.045 + float(item_depth - 2) * 0.022 + (0.065 if from_elite else 0.0))
		4:
			magic_chance = minf(0.70, 0.44 + depth_bonus * 0.030 + (0.07 if from_elite else 0.0))
			if item_depth >= 2:
				rare_chance = minf(0.30, 0.09 + float(item_depth - 2) * 0.028 + (0.09 if from_elite else 0.0))
		_:
			magic_chance = minf(0.68, 0.42 + depth_bonus * 0.025 + (0.06 if from_elite else 0.0))
			if item_depth >= 2:
				rare_chance = minf(0.34, 0.13 + float(item_depth - 2) * 0.026 + (0.10 if from_elite else 0.0))
			# Gilded is true chase loot: T5 only, and never before Depth 5.
			if item_depth >= 5:
				gilded_chance = minf(0.022, 0.0025 + float(item_depth - 5) * 0.0018 + (0.0075 if from_elite else 0.0))

	# Preserve a healthy Common share. We subtract special rarities before Magic.
	var roll: float = rng.randf()
	if roll < gilded_chance:
		return "Gilded"
	if roll < gilded_chance + rare_chance:
		return "Rare"
	if roll < gilded_chance + rare_chance + magic_chance:
		return "Magic"
	return "Common"

func _roll_item_base(slot: String) -> Dictionary:
	var bases: Array[Dictionary] = []
	match slot:
		"weapon":
			bases = [
				{"name":"Scrap Gun", "weapon_archetype":"gun", "implicit_stat":"damage", "implicit_value":2.5},
				{"name":"Cutdown Gun", "weapon_archetype":"gun", "implicit_stat":"damage", "implicit_value":4.0},
				{"name":"Heavy-Frame Gun", "weapon_archetype":"gun", "implicit_stat":"damage", "implicit_value":6.0},
				{"name":"Rapid-Frame Gun", "weapon_archetype":"gun", "implicit_stat":"attack_speed", "implicit_value":0.35},
				{"name":"Scrap Blade", "weapon_archetype":"blade", "implicit_stat":"damage", "implicit_value":3.0},
				{"name":"Long Blade", "weapon_archetype":"blade", "implicit_stat":"damage", "implicit_value":4.5},
				{"name":"Heavy Blade", "weapon_archetype":"blade", "implicit_stat":"damage", "implicit_value":6.5},
				{"name":"Quick Blade", "weapon_archetype":"blade", "implicit_stat":"attack_speed", "implicit_value":0.30}
			]
		"armor":
			bases = [
				{"name":"Padded Rags", "implicit_stat":"max_hp", "implicit_value":14.0},
				{"name":"Runner Jacket", "implicit_stat":"move_speed", "implicit_value":12.0},
				{"name":"Reinforced Vest", "implicit_stat":"max_hp", "implicit_value":24.0},
				{"name":"Scavenger Coat", "implicit_stat":"item_find", "implicit_value":5.0}
			]
		_:
			bases = [
				{"name":"Bent Lucky Coin", "implicit_stat":"currency_find", "implicit_value":4.0},
				{"name":"Finder's Eye", "implicit_stat":"item_find", "implicit_value":4.0},
				{"name":"Rat Fang", "implicit_stat":"damage", "implicit_value":2.5},
				{"name":"Runner Token", "implicit_stat":"move_speed", "implicit_value":8.0}
			]
	return bases[rng.randi_range(0, bases.size() - 1)].duplicate(true)

func _random_core_for_archetype(archetype: String) -> String:
	var cores: Array[String] = ["repeater", "scatter", "piercer", "sprayer"]
	if archetype == "blade":
		cores = ["cleaver", "duelist", "whirlwind", "throwing"]
	return cores[rng.randi_range(0, cores.size() - 1)]

func _core_archetype(core_id: String) -> String:
	if ["cleaver", "duelist", "whirlwind", "throwing"].has(core_id):
		return "blade"
	return "gun"

func _core_name(core_id: String) -> String:
	match core_id:
		"scatter": return "Scatter"
		"piercer": return "Piercer"
		"sprayer": return "Sprayer"
		"cleaver": return "Cleaver"
		"duelist": return "Duelist"
		"whirlwind": return "Whirlwind"
		"throwing": return "Recall"
		_: return "Repeater"

func _core_description(core_id: String) -> String:
	match core_id:
		"scatter": return "Five-pellet close-range blast"
		"piercer": return "Slow heavy shot with innate pierce"
		"sprayer": return "Very high fire rate with lower bullet damage"
		"cleaver": return "Slow, wide, heavy frontal sweep"
		"duelist": return "Fast narrow stab with long melee reach"
		"whirlwind": return "360° spin that hits everything around you"
		"throwing": return "Throw once, then recall through enemies for a second hit"
		_: return "Reliable automatic single-projectile fire"

func _affix_candidates(slot: String) -> Array[String]:
	match slot:
		"weapon":
			return ["damage", "attack_speed", "currency_find", "item_find"]
		"armor":
			return ["max_hp", "move_speed", "currency_find", "item_find"]
		_:
			return ["damage", "max_hp", "move_speed", "currency_find", "item_find"]

func _mechanic_pool(slot: String, weapon_archetype: String = "") -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	match slot:
		"weapon":
			if weapon_archetype == "blade":
				pool = [
					{"id":"keen_edge", "tier":1, "name":"Keen Edge", "prefix":"Keen", "description":"+18% melee damage."},
					{"id":"long_reach", "tier":1, "name":"Long Reach", "prefix":"Long-Reach", "description":"+22% melee reach."},
					{"id":"brutal_edge", "tier":2, "name":"Brutal Edge", "prefix":"Brutal", "description":"+65% melee knockback."},
					{"id":"kill_frenzy", "tier":3, "name":"Kill Frenzy", "prefix":"Frenzied", "description":"Kills grant +8% attack rate for 3 sec, stacking up to 5 times."}
				]
			else:
				pool = [
					{"id":"point_blank", "tier":1, "name":"Point Blank", "prefix":"Close-Quarters", "description":"+45% projectile damage within 125 px."},
					{"id":"heavy_rounds", "tier":1, "name":"Heavy Rounds", "prefix":"Heavy", "description":"Projectiles are larger and deal 90% more knockback."},
					{"id":"split_chamber", "tier":2, "name":"Split Chamber", "prefix":"Split", "description":"Fires extra projectiles, but each projectile deals less damage."},
					{"id":"bore_rounds", "tier":2, "name":"Bore Rounds", "prefix":"Boring", "description":"Projectiles pierce 2 additional enemies."},
					{"id":"ricochet", "tier":3, "name":"Ricochet", "prefix":"Ricocheting", "description":"Projectiles bounce to 1 nearby enemy after their final hit."},
					{"id":"kill_frenzy", "tier":3, "name":"Kill Frenzy", "prefix":"Frenzied", "description":"Kills grant +8% fire rate for 3 sec, stacking up to 5 times."},
					{"id":"explosive_rounds", "tier":4, "name":"Explosive Rounds", "prefix":"Explosive", "description":"Projectile kills explode for 45% of the killing shot's damage."},
					{"id":"kings_barrage", "tier":5, "name":"King's Barrage", "prefix":"Barrage", "description":"Fires 2 additional projectiles with reduced damage per projectile."}
				]
		"armor":
			pool = [
				{"id":"quickstep", "tier":1, "name":"Quickstep", "prefix":"Quickstep", "description":"Dash cooldown is 22% shorter."},
				{"id":"adrenaline_lining", "tier":1, "name":"Adrenaline Lining", "prefix":"Adrenaline", "description":"Taking damage grants +35% movement for 1.2 sec."},
				{"id":"second_wind", "tier":2, "name":"Second Wind", "prefix":"Second-Wind", "description":"Each kill restores 1.5 HP."},
				{"id":"armored_greed", "tier":3, "name":"Armored Greed", "prefix":"Greed-Lined", "description":"+20% Item Find, but you take 15% more damage."},
				{"id":"glass_rat", "tier":4, "name":"Glass Rat", "prefix":"Glass", "description":"+30% movement speed, but -25% maximum HP."},
				{"id":"dead_mans_insurance", "tier":5, "name":"Dead Man's Insurance", "prefix":"Insured", "description":"Once per Claim depth, lethal damage leaves you at 1 HP."}
			]
		_:
			pool = [
				{"id":"magnet_heart", "tier":1, "name":"Magnet Heart", "prefix":"Magnetic", "description":"Loot magnet radius is dramatically increased."},
				{"id":"field_medic", "tier":1, "name":"Field Medic", "prefix":"Medic", "description":"Picking up gear restores 8 HP."},
				{"id":"hoarders_bargain", "tier":2, "name":"Hoarder's Bargain", "prefix":"Bargain", "description":"+25% Currency Find, but -15% maximum HP."},
				{"id":"treasure_scent", "tier":3, "name":"Treasure Scent", "prefix":"Treasure-Scented", "description":"Treasure rooms are 7 percentage points more common."},
				{"id":"elite_tax", "tier":4, "name":"Elite Tax", "prefix":"Taxing", "description":"Elites drop +50% currency; normal enemies drop -15% currency."},
				{"id":"hoarders_curse", "tier":5, "name":"Hoarder's Curse", "prefix":"Cursed", "description":"+60% Currency Find, but you take 30% more damage."},
				{"id":"double_drop", "tier":5, "name":"Double Drop", "prefix":"Duplicating", "description":"Gear drops have a 10% chance to produce an extra item."}
			]
	return pool

func _roll_mechanic(slot: String, used_ids: Array[String], prefer_high: bool = false, weapon_archetype: String = "") -> Dictionary:
	var eligible: Array[Dictionary] = []
	var preferred: Array[Dictionary] = []
	for mechanic: Dictionary in _mechanic_pool(slot, weapon_archetype):
		var mechanic_id: String = String(mechanic.get("id", ""))
		var mechanic_tier: int = int(mechanic.get("tier", 1))
		if mechanic_tier > claim_tier or used_ids.has(mechanic_id):
			continue
		eligible.append(mechanic)
		if mechanic_tier >= maxi(1, claim_tier - 1):
			preferred.append(mechanic)

	if eligible.is_empty():
		return {}
	var source: Array[Dictionary] = eligible
	if prefer_high and not preferred.is_empty():
		source = preferred
	elif not preferred.is_empty() and rng.randf() < 0.60:
		source = preferred
	return source[rng.randi_range(0, source.size() - 1)].duplicate(true)

func _best_affix_tier() -> int:
	# T1/T2/T3/T4/T5 cap out at T5/T4/T3/T2/T1 affixes respectively.
	return clampi(6 - claim_tier, 1, 5)

func _roll_affix_tier(item_depth: int) -> int:
	var best: int = _best_affix_tier()
	if best >= 5:
		return 5

	# Going deeper makes the best tier available in this Claim more likely,
	# but never unlocks a tier belonging to a later Claim.
	var best_chance: float = minf(0.82, 0.38 + float(maxi(0, item_depth - 1)) * 0.055)
	var roll: float = rng.randf()
	if roll < best_chance:
		return best

	var second: int = mini(5, best + 1)
	if second >= 5:
		return second

	if roll < best_chance + 0.42:
		return second
	return mini(5, best + 2)

func _roll_affix_value(stat: String, tier: int) -> float:
	var low: float = 0.0
	var high: float = 0.0
	match stat:
		"damage":
			match tier:
				1: low = 17.0; high = 25.0
				2: low = 12.0; high = 18.0
				3: low = 8.0; high = 13.0
				4: low = 5.0; high = 9.0
				_: low = 3.0; high = 6.0
		"attack_speed":
			match tier:
				1: low = 0.85; high = 1.15
				2: low = 0.60; high = 0.90
				3: low = 0.40; high = 0.65
				4: low = 0.25; high = 0.45
				_: low = 0.15; high = 0.30
		"max_hp":
			match tier:
				1: low = 60.0; high = 90.0
				2: low = 42.0; high = 65.0
				3: low = 28.0; high = 45.0
				4: low = 18.0; high = 32.0
				_: low = 10.0; high = 20.0
		"move_speed":
			match tier:
				1: low = 23.0; high = 32.0
				2: low = 17.0; high = 24.0
				3: low = 12.0; high = 18.0
				4: low = 8.0; high = 14.0
				_: low = 5.0; high = 10.0
		_:
			match tier:
				1: low = 21.0; high = 30.0
				2: low = 15.0; high = 22.0
				3: low = 10.0; high = 16.0
				4: low = 7.0; high = 12.0
				_: low = 4.0; high = 8.0

	var value: float = rng.randf_range(low, high)
	if stat == "attack_speed":
		return snappedf(value, 0.01)
	if stat == "max_hp" or stat == "move_speed":
		return snappedf(value, 1.0)
	return snappedf(value, 0.1)

func _make_affix_record(stat: String, tier: int, value: float) -> Dictionary:
	return {
		"stat": stat,
		"tier": tier,
		"value": value,
		"label": _stat_label(stat)
	}

func _apply_item_stat(item: Dictionary, stat: String, value: float) -> void:
	item[stat] = float(item.get(stat, 0.0)) + value

func _stat_label(stat: String) -> String:
	match stat:
		"damage": return "Damage"
		"attack_speed": return "Attack Rate"
		"max_hp": return "Max HP"
		"move_speed": return "Move Speed"
		"currency_find": return "Currency Find"
		"item_find": return "Item Find"
		_: return stat.capitalize()

func _format_stat_value(stat: String, value: float, include_plus: bool = true) -> String:
	var prefix: String = "+" if include_plus and value >= 0.0 else ""
	match stat:
		"attack_speed":
			return "%s%.2f Attack Rate" % [prefix, value]
		"currency_find", "item_find":
			return "%s%.1f%% %s" % [prefix, value, _stat_label(stat)]
		"max_hp", "move_speed":
			return "%s%.0f %s" % [prefix, value, _stat_label(stat)]
		_:
			return "%s%.1f %s" % [prefix, value, _stat_label(stat)]

func _make_generated_item_name(item: Dictionary) -> String:
	var rarity: String = String(item.get("rarity", "Common"))
	var base_name: String = String(item.get("base_name", "Gear"))
	var suffixes: Array[String] = ["of Plenty", "of Hunger", "of the Hoard", "of Fortune", "of Greed", "of Scavenging"]
	var gilded_titles: Array[String] = ["Rat King's", "Vaultborn", "Midas-Touched", "Crownmarked", "Hoardlord's"]
	var mechanic_prefix: String = ""

	var mechanics_variant: Variant = item.get("mechanics", [])
	if typeof(mechanics_variant) == TYPE_ARRAY:
		var mechanic_array: Array = mechanics_variant as Array
		if not mechanic_array.is_empty() and typeof(mechanic_array[0]) == TYPE_DICTIONARY:
			mechanic_prefix = String((mechanic_array[0] as Dictionary).get("prefix", ""))

	match rarity:
		"Magic":
			return "%s %s" % [mechanic_prefix if not mechanic_prefix.is_empty() else "Modified", base_name]
		"Rare":
			return "%s %s %s" % [mechanic_prefix if not mechanic_prefix.is_empty() else "Hoarded", base_name, suffixes[rng.randi_range(0, suffixes.size() - 1)]]
		"Gilded":
			return "%s %s" % [gilded_titles[rng.randi_range(0, gilded_titles.size() - 1)], base_name]
		_:
			return base_name

func _item_value(item: Dictionary) -> int:
	var item_level: int = int(item.get("item_level", item.get("depth", 1)))
	var score: float = 35.0 + float(item_level) * 24.0
	score += float(item.get("damage", 0.0)) * 20.0
	score += float(item.get("attack_speed", 0.0)) * 190.0
	score += float(item.get("max_hp", 0.0)) * 4.8
	score += float(item.get("move_speed", 0.0)) * 5.5
	score += float(item.get("currency_find", 0.0)) * 15.0
	score += float(item.get("item_find", 0.0)) * 15.0

	var mechanics_variant: Variant = item.get("mechanics", [])
	if typeof(mechanics_variant) == TYPE_ARRAY:
		for mechanic_variant: Variant in mechanics_variant as Array:
			if typeof(mechanic_variant) == TYPE_DICTIONARY:
				score += 45.0 + float(int((mechanic_variant as Dictionary).get("tier", 1))) * 25.0

	var rarity: String = String(item.get("rarity", "Common"))
	match rarity:
		"Magic": score *= 1.25
		"Rare": score *= 1.65
		"Gilded": score *= 2.80
	return maxi(25, int(round(score)))

func _item_to_bbcode(item: Dictionary, compact: bool = false) -> String:
	if item.is_empty():
		return "[color=#7f8794]Empty[/color]"

	var rarity: String = String(item.get("rarity", "Common"))
	var color_hex: String = _rarity_color_hex(rarity)
	var name_value: String = String(item.get("name", "Item"))
	var value: int = int(item.get("value", 0))
	var item_level: int = int(item.get("item_level", item.get("depth", 1)))
	var base_name: String = String(item.get("base_name", "Legacy Gear"))
	var slot: String = String(item.get("slot", "gear"))
	var type_text: String = base_name
	if slot == "weapon":
		type_text = String(item.get("weapon_archetype", "gun")).capitalize()

	if compact:
		return "[color=%s][b]%s[/b][/color]\n[color=#737c8d]%s • ilvl %d[/color]" % [color_hex, name_value, type_text, item_level]

	var text: String = "[font_size=18][color=%s][b]%s[/b][/color][/font_size]" % [color_hex, name_value]
	text += "\n[color=#f6d05f][b]₵%d[/b][/color]   [color=#747b87]%s • %s • ilvl %d[/color]" % [value, rarity, type_text, item_level]
	if rarity != "Common":
		text += "\n[color=#6f6758]MODIFIERS %d/%d[/color]" % [_item_affix_count(item), _rarity_affix_cap(rarity)]

	match slot:
		"weapon":
			var core_id: String = String(item.get("core_id", item.get("weapon_type", "repeater")))
			text += "\n\n[color=#777f8d][font_size=11]CORE[/font_size][/color]"
			text += "\n[color=#6fd4ff][b]◇ %s CORE[/b][/color]" % _core_name(core_id).to_upper()
			text += "\n[color=#aeb6c4]%s[/color]" % _core_description(core_id)
			text += "\n\n" + _weapon_output_bbcode(item)
		"armor":
			text += "\n\n" + _armor_output_bbcode(item)
		"charm":
			text += "\n\n" + _charm_output_bbcode(item)

	var implicit_variant: Variant = item.get("implicit", {})
	if typeof(implicit_variant) == TYPE_DICTIONARY:
		var implicit: Dictionary = implicit_variant as Dictionary
		if not implicit.is_empty():
			var implicit_stat: String = String(implicit.get("stat", ""))
			var implicit_value: float = float(implicit.get("value", 0.0))
			text += "\n\n[color=#777f8d][font_size=11]ITEM ROLLS[/font_size][/color]"
			text += "\n[color=#e2c768][b]%s[/b][/color]" % _format_stat_value(implicit_stat, implicit_value)

	var mechanics_variant: Variant = item.get("mechanics", [])
	if typeof(mechanics_variant) == TYPE_ARRAY:
		var mechanics: Array = mechanics_variant as Array
		if not mechanics.is_empty():
			var mechanic_header: String = "AUGMENTS" if slot == "weapon" else "MECHANICS"
			text += "\n\n[color=#777f8d][font_size=11]%s[/font_size][/color]" % mechanic_header
			for mechanic_variant: Variant in mechanics:
				if typeof(mechanic_variant) != TYPE_DICTIONARY:
					continue
				var mechanic: Dictionary = mechanic_variant as Dictionary
				var mechanic_name: String = String(mechanic.get("name", "Mechanic"))
				var mechanic_description: String = _compact_mechanic_description(mechanic)
				text += "\n[color=#ffb45d][b]◆ %s[/b][/color]" % mechanic_name
				if not mechanic_description.is_empty():
					text += "\n[color=#b8bec8]%s[/color]" % mechanic_description

	var affixes_variant: Variant = item.get("affixes", [])
	if typeof(affixes_variant) == TYPE_ARRAY:
		var affix_array: Array = affixes_variant as Array
		if not affix_array.is_empty():
			text += "\n\n[color=#777f8d][font_size=11]MODIFIERS[/font_size][/color]"
			for affix_variant: Variant in affix_array:
				if typeof(affix_variant) != TYPE_DICTIONARY:
					continue
				var affix: Dictionary = affix_variant as Dictionary
				var affix_stat: String = String(affix.get("stat", ""))
				var affix_value: float = float(affix.get("value", 0.0))
				var tier: int = int(affix.get("tier", 5))
				text += "\n[color=#858d99]T%d[/color]  [color=#e6e8ec]%s[/color]" % [tier, _format_stat_value(affix_stat, affix_value)]

	return text

func _compact_mechanic_description(mechanic: Dictionary) -> String:
	match String(mechanic.get("id", "")):
		"point_blank": return "+45% damage at close range"
		"heavy_rounds": return "Larger shots • +90% knockback"
		"split_chamber": return "Extra projectiles • lower per-shot damage"
		"bore_rounds": return "+2 projectile pierce"
		"ricochet": return "Shots bounce to 1 nearby enemy"
		"kill_frenzy": return "Kills grant +8% fire rate • stacks 5×"
		"quickstep": return "Dash cooldown -22%"
		"adrenaline_lining": return "Taking damage grants +35% move speed"
		"second_wind": return "Kills restore 1.5 HP"
		"armored_greed": return "+20% Item Find • +15% damage taken"
		"glass_rat": return "+30% move speed • -25% max HP"
		"dead_mans_insurance": return "Survive lethal damage at 1 HP once per depth"
		"magnet_heart": return "Greatly increased loot pickup radius"
		"field_medic": return "Picking up gear restores 8 HP"
		"hoarders_bargain": return "+25% Currency Find • -15% max HP"
		"treasure_scent": return "+7% Treasure Room chance"
		"elite_tax": return "Elites +50% currency • normals -15%"
		"hoarders_curse": return "+60% Currency Find • +30% damage taken"
		"double_drop": return "10% chance for an extra gear drop"
		"explosive_rounds": return "Kills explode for 45% of shot damage"
		"kings_barrage": return "+2 projectiles • lower per-shot damage"
		"keen_edge": return "+18% melee damage"
		"long_reach": return "+22% melee reach"
		"brutal_edge": return "+65% melee knockback"
		_: return String(mechanic.get("description", ""))

func _rarity_color_hex(rarity: String) -> String:
	match rarity:
		"Gilded": return "#ffd34d"
		"Rare": return "#d96cff"
		"Magic": return "#63a9ff"
		_: return "#cfd4dc"

func _normalize_item(raw_item: Dictionary) -> Dictionary:
	var item: Dictionary = raw_item.duplicate(true)
	if not item.has("item_level"):
		item["item_level"] = maxi(1, int(item.get("depth", 1)))
	if not item.has("base_name"):
		item["base_name"] = String(item.get("name", "Legacy Gear"))
	var slot: String = String(item.get("slot", ""))
	if slot == "weapon":
		var legacy_type: String = String(item.get("weapon_type", "repeater"))
		if legacy_type == "scattergun":
			legacy_type = "scatter"
		item["weapon_archetype"] = String(item.get("weapon_archetype", "gun"))
		item["core_id"] = String(item.get("core_id", legacy_type))
		var base_name: String = String(item.get("base_name", "Scrap Gun"))
		match base_name:
			"Scrap Repeater": item["base_name"] = "Scrap Gun"
			"Sawed Scattergun": item["base_name"] = "Cutdown Gun"
			"Heavy Piercer": item["base_name"] = "Heavy-Frame Gun"
			"Bullet Hose": item["base_name"] = "Rapid-Frame Gun"
		item.erase("weapon_type")
	else:
		item["weapon_archetype"] = ""
		item["core_id"] = ""
	if not item.has("implicit"):
		item["implicit"] = {}
	if not item.has("mechanics"):
		item["mechanics"] = []
	if not item.has("affixes"):
		var legacy_affixes: Array[Dictionary] = []
		var legacy_stats: Array[String] = ["damage", "attack_speed", "max_hp", "move_speed", "currency_find", "item_find"]
		for stat: String in legacy_stats:
			var legacy_value: float = float(item.get(stat, 0.0))
			if legacy_value > 0.0:
				legacy_affixes.append(_make_affix_record(stat, 5, legacy_value))
		item["affixes"] = legacy_affixes
	return item

func _make_starter_item(slot: String) -> Dictionary:
	var item: Dictionary
	match slot:
		"weapon":
			item = {
				"id":next_item_id, "slot":"weapon", "rarity":"Common", "name":"Rusty Scrap Gun",
				"base_name":"Scrap Gun", "weapon_archetype":"gun", "core_id":"repeater", "depth":0, "item_level":1,
				"damage":3.0, "attack_speed":0.0, "max_hp":0.0, "move_speed":0.0,
				"currency_find":0.0, "item_find":0.0,
				"implicit":{"stat":"damage", "value":3.0, "label":"Damage"}, "affixes":[], "mechanics":[]
			}
		"armor":
			item = {
				"id":next_item_id, "slot":"armor", "rarity":"Common", "name":"Padded Rags",
				"base_name":"Padded Rags", "weapon_archetype":"", "core_id":"", "depth":0, "item_level":1,
				"damage":0.0, "attack_speed":0.0, "max_hp":12.0, "move_speed":0.0,
				"currency_find":0.0, "item_find":0.0,
				"implicit":{"stat":"max_hp", "value":12.0, "label":"Max HP"}, "affixes":[], "mechanics":[]
			}
		_:
			item = {
				"id":next_item_id, "slot":"charm", "rarity":"Common", "name":"Bent Lucky Coin",
				"base_name":"Bent Lucky Coin", "weapon_archetype":"", "core_id":"", "depth":0, "item_level":1,
				"damage":0.0, "attack_speed":0.0, "max_hp":0.0, "move_speed":0.0,
				"currency_find":3.0, "item_find":0.0,
				"implicit":{"stat":"currency_find", "value":3.0, "label":"Currency Find"}, "affixes":[], "mechanics":[]
			}
	next_item_id += 1
	item["value"] = _item_value(item)
	return item

func _claim_tier_depth_requirement(next_tier: int) -> int:
	match next_tier:
		2: return 4
		3: return 5
		4: return 6
		5: return 8
		_: return 999

func _claim_tier_unlock_cost(next_tier: int) -> int:
	match next_tier:
		2: return 1200
		3: return 6000
		4: return 25000
		5: return 100000
		_: return 0

func _tier_loot_ceiling(tier_value: int) -> String:
	match tier_value:
		1: return "MAGIC"
		2, 3, 4: return "RARE"
		_: return "GILDED"

func _record_successful_extraction() -> void:
	var key: String = str(claim_tier)
	var previous_best: int = int(tier_best_depths.get(key, 0))
	if depth > previous_best:
		tier_best_depths[key] = depth

func _unlock_next_claim_tier() -> void:
	if claim_tier >= 5:
		return
	var next_tier: int = claim_tier + 1
	var requirement: int = _claim_tier_depth_requirement(next_tier)
	var best_depth: int = int(tier_best_depths.get(str(claim_tier), 0))
	var cost: int = _claim_tier_unlock_cost(next_tier)
	if best_depth < requirement or stash_coins < cost:
		return
	stash_coins -= cost
	claim_tier = next_tier
	_clear_juice()
	_update_hub_ui()
	_save_game()

func _update_claim_unlock_button() -> void:
	if claim_unlock_button == null:
		return
	if claim_tier >= 5:
		claim_unlock_button.text = "MAX CLAIM TIER REACHED"
		claim_unlock_button.disabled = true
		return

	var next_tier: int = claim_tier + 1
	var requirement: int = _claim_tier_depth_requirement(next_tier)
	var best_depth: int = int(tier_best_depths.get(str(claim_tier), 0))
	var cost: int = _claim_tier_unlock_cost(next_tier)

	if best_depth < requirement:
		claim_unlock_button.text = "T%d LOCKED  •  EXTRACT DEPTH %d" % [next_tier, requirement]
		claim_unlock_button.disabled = true
	elif stash_coins < cost:
		claim_unlock_button.text = "UNLOCK T%d  •  ₵%d NEEDED" % [next_tier, cost]
		claim_unlock_button.disabled = true
	else:
		claim_unlock_button.text = "UNLOCK T%d  •  ₵%d" % [next_tier, cost]
		claim_unlock_button.disabled = false

func _update_hub_ui() -> void:
	var invested: int = juice_density + juice_quantity + juice_currency + juice_elite
	var risk: String = "LOW"
	var risk_color: String = "#7de38f"
	if invested >= 4:
		risk = "SPICY"
		risk_color = "#ffd45c"
	if invested >= 9:
		risk = "DANGEROUS"
		risk_color = "#ff914d"
	if invested >= 15:
		risk = "RAT BRAIN"
		risk_color = "#ff5d73"

	var best_depth: int = int(tier_best_depths.get(str(claim_tier), 0))
	var affix_ceiling: int = _best_affix_tier()
	var next_gate: String = "MAX TIER"
	if claim_tier < 5:
		var next_tier: int = claim_tier + 1
		next_gate = "T%d: extract D%d + ₵%d" % [next_tier, _claim_tier_depth_requirement(next_tier), _claim_tier_unlock_cost(next_tier)]

	claim_label.text = "[font_size=20][b]TIER %d[/b][/font_size]   [color=%s][b]%s[/b][/color]\n[color=#8d96a6]Best extraction[/color]  D%d     [color=#8d96a6]Seals[/color]  %d     [color=#8d96a6]Invested[/color]  %d\n[color=#8d96a6]Loot[/color]  %s     [color=#8d96a6]Affixes[/color]  T%d\n[color=#6f7785]%s[/color]" % [claim_tier, risk_color, risk, best_depth, stash_seals, invested, _tier_loot_ceiling(claim_tier), affix_ceiling, next_gate]

	var stats: Dictionary = _calculate_player_stats()
	stats_label.text = "[color=#82745a][font_size=10]BUILD SUMMARY[/font_size][/color]\n[color=#d7bd7b][b]%s • %s[/b][/color]\n\n[b]%.1f[/b] Damage      [b]%.2f[/b]/s\n[b]%.0f[/b] Max HP      [b]%.0f[/b] Move\n\n[color=#82745a][font_size=10]LOOT[/font_size][/color]\n[b]%.1f%%[/b] Currency   [b]%.1f%%[/b] Items" % [String(stats.get("weapon_archetype", "gun")).capitalize(), _core_name(String(stats.get("weapon_core", "repeater"))), float(stats["damage"]), float(stats["attack_speed"]), float(stats["max_hp"]), float(stats["move_speed"]), float(stats["currency_find"]), float(stats["item_find"])]

	_update_equipped_slot_buttons()

	_rebuild_inventory()
	_refresh_selected_item()
	_update_stash_controls()
	_update_claim_unlock_button()
	if crafting_panel != null and crafting_panel.visible:
		_refresh_crafting_panel()
	_update_top_bar()

func _update_equipped_slot_buttons() -> void:
	var slot_names: Array[String] = ["weapon", "armor", "charm"]
	for slot_name: String in slot_names:
		var button_variant: Variant = equipped_slot_buttons.get(slot_name)
		if not button_variant is Button:
			continue
		var button := button_variant as Button
		var item: Dictionary = equipped.get(slot_name, {}) as Dictionary
		if item.is_empty():
			button.text = "%s\nEMPTY" % slot_name.to_upper()
			button.add_theme_color_override("font_color", Color(0.46, 0.43, 0.38))
			button.add_theme_stylebox_override("normal", _arpg_slot_style(Color(0.18, 0.16, 0.12)))
			continue
		var rarity: String = String(item.get("rarity", "Common"))
		var detail: String = ""
		if slot_name == "weapon":
			detail = "%s • %s Core" % [String(item.get("weapon_archetype", "gun")).capitalize(), _core_name(String(item.get("core_id", "repeater")))]
		else:
			detail = String(item.get("base_name", slot_name.capitalize()))
		button.text = "%s\n%s\n%s" % [slot_name.to_upper(), String(item.get("name", "Item")), detail]
		button.add_theme_font_size_override("font_size", 11)
		button.add_theme_color_override("font_color", _rarity_color(rarity))
		button.add_theme_stylebox_override("normal", _arpg_slot_style(_rarity_color(rarity)))
		button.add_theme_stylebox_override("hover", _arpg_slot_style(Color(0.72, 0.54, 0.25), true))

func _rebuild_inventory() -> void:
	for child: Node in inventory_list.get_children():
		child.queue_free()

	var filtered_items: Array[Dictionary] = []
	for item: Dictionary in stash_gear:
		if stash_filter == "all" or String(item.get("slot", "")) == stash_filter:
			filtered_items.append(item)

	match stash_sort_mode:
		"value":
			filtered_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("value", 0)) > int(b.get("value", 0)))
		"rarity":
			filtered_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				var rarity_a: int = _rarity_rank(String(a.get("rarity", "Common")))
				var rarity_b: int = _rarity_rank(String(b.get("rarity", "Common")))
				if rarity_a == rarity_b:
					return int(a.get("value", 0)) > int(b.get("value", 0))
				return rarity_a > rarity_b
			)
		"newest":
			filtered_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("id", 0)) > int(b.get("id", 0)))

	stash_count_label.text = "%d / 40" % filtered_items.size()

	for item: Dictionary in filtered_items:
		var item_id: int = int(item.get("id", -1))
		var rarity: String = String(item.get("rarity", "Common"))
		var slot: String = String(item.get("slot", "gear"))
		var button := Button.new()
		button.custom_minimum_size = Vector2(64.0, 64.0)
		button.text = _grid_item_glyph(slot) + "\n" + _grid_item_short_name(item)
		button.add_theme_font_size_override("font_size", 9)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.tooltip_text = "%s\n%s • ilvl %d\n₵%d" % [String(item.get("name", "Item")), rarity, int(item.get("item_level", 1)), int(item.get("value", 0))]
		var selected: bool = item_id == selected_stash_item_id
		button.add_theme_stylebox_override("normal", _arpg_slot_style(_rarity_color(rarity), selected))
		button.add_theme_stylebox_override("hover", _arpg_slot_style(Color(0.74, 0.57, 0.29), true))
		button.add_theme_color_override("font_color", _rarity_color(rarity))
		button.pressed.connect(_select_stash_item.bind(item_id))
		inventory_list.add_child(button)

	var visible_cells: int = mini(40, filtered_items.size())
	for _cell in range(visible_cells, 40):
		var empty := Panel.new()
		empty.custom_minimum_size = Vector2(64.0, 64.0)
		empty.add_theme_stylebox_override("panel", _empty_grid_cell_style())
		inventory_list.add_child(empty)

func _grid_item_glyph(slot: String) -> String:
	match slot:
		"weapon": return "⚔"
		"armor": return "▣"
		"charm": return "◆"
		_: return "•"

func _grid_item_short_name(item: Dictionary) -> String:
	var base_name: String = String(item.get("base_name", item.get("name", "Item")))
	if base_name.length() <= 8:
		return base_name
	return base_name.left(7) + "…"

func _empty_grid_cell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.013, 0.012, 0.011)
	style.border_color = Color(0.105, 0.090, 0.062)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style

func _rarity_rank(rarity: String) -> int:
	match rarity:
		"Gilded": return 4
		"Rare": return 3
		"Magic": return 2
		_: return 1

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Gilded": return Color(1.0, 0.82, 0.28)
		"Rare": return Color(0.86, 0.44, 1.0)
		"Magic": return Color(0.39, 0.68, 1.0)
		_: return Color(0.82, 0.84, 0.88)

func _set_stash_filter(filter_value: String) -> void:
	stash_filter = filter_value
	_rebuild_inventory()
	_update_stash_controls()

func _cycle_stash_sort() -> void:
	match stash_sort_mode:
		"value": stash_sort_mode = "rarity"
		"rarity": stash_sort_mode = "newest"
		_: stash_sort_mode = "value"
	_rebuild_inventory()
	_update_stash_controls()

func _update_stash_controls() -> void:
	for key_variant: Variant in filter_buttons.keys():
		var key: String = String(key_variant)
		var button_variant: Variant = filter_buttons.get(key)
		if button_variant is Button:
			var button := button_variant as Button
			var active: bool = key == stash_filter
			button.disabled = false
			button.add_theme_stylebox_override("normal", _arpg_button_style(active, false))
			button.add_theme_color_override("font_color", Color(0.93, 0.81, 0.55) if active else Color(0.59, 0.56, 0.50))
	if sort_button != null:
		match stash_sort_mode:
			"rarity": sort_button.text = "RARITY"
			"newest": sort_button.text = "NEWEST"
			_: sort_button.text = "VALUE"

func _select_equipped_slot(slot_name: String) -> void:
	var item: Dictionary = equipped.get(slot_name, {}) as Dictionary
	if item.is_empty():
		return
	selected_stash_item_id = -1
	selected_item_label.text = _item_to_bbcode(item)
	selected_equip_button.disabled = true
	selected_sell_button.disabled = true

func _select_stash_item(item_id: int) -> void:
	selected_stash_item_id = item_id
	_rebuild_inventory()
	_refresh_selected_item()

func _refresh_selected_item() -> void:
	if selected_item_label == null:
		return
	var index: int = _find_stash_item_index(selected_stash_item_id)
	if index < 0:
		selected_stash_item_id = -1
		selected_item_label.text = "[color=#686157]Select an item from the stash.[/color]"
		selected_equip_button.disabled = true
		selected_sell_button.disabled = true
		return

	var item: Dictionary = stash_gear[index]
	var slot: String = String(item.get("slot", "charm"))
	var current: Dictionary = equipped.get(slot, {}) as Dictionary
	var comparison: String = _comparison_bbcode(item, current)
	selected_item_label.text = _item_to_bbcode(item)
	if comparison != "[color=#8d96a6]No numerical or mechanical change.[/color]":
		selected_item_label.text += "\n\n[color=#777f8d][font_size=11]VS EQUIPPED[/font_size][/color]\n%s" % comparison
	selected_equip_button.disabled = false
	selected_sell_button.disabled = false
	selected_sell_button.text = "SELL FOR ₵%d" % int(item.get("value", 0))
	if crafting_panel != null and crafting_panel.visible:
		_refresh_crafting_panel()

func _comparison_bbcode(candidate: Dictionary, current: Dictionary) -> String:
	var lines: Array[String] = []
	if String(candidate.get("slot", "")) == "weapon":
		var new_core: String = String(candidate.get("core_id", "repeater"))
		var old_core: String = String(current.get("core_id", "repeater"))
		if new_core != old_core:
			lines.append("[color=#6fd4ff]Core: %s → %s[/color]" % [_core_name(old_core), _core_name(new_core)])

	var stat_defs: Array[Dictionary] = [
		{"key":"damage", "label":"Damage", "decimals":1},
		{"key":"attack_speed", "label":"Attack Rate", "decimals":2},
		{"key":"max_hp", "label":"Max HP", "decimals":0},
		{"key":"move_speed", "label":"Move Speed", "decimals":0},
		{"key":"currency_find", "label":"Currency Find", "decimals":1},
		{"key":"item_find", "label":"Item Find", "decimals":1}
	]
	for stat_def: Dictionary in stat_defs:
		var key: String = String(stat_def["key"])
		var delta: float = float(candidate.get(key, 0.0)) - float(current.get(key, 0.0))
		if absf(delta) < 0.005:
			continue
		var decimals: int = int(stat_def["decimals"])
		var number_text: String
		if decimals == 0:
			number_text = "%+.0f" % delta
		elif decimals == 2:
			number_text = "%+.2f" % delta
		else:
			number_text = "%+.1f" % delta
		var suffix: String = "%" if key == "currency_find" or key == "item_find" else ""
		var color_hex: String = "#72df8b" if delta > 0.0 else "#ff6d79"
		lines.append("[color=%s]%s  %s%s[/color]" % [color_hex, String(stat_def["label"]), number_text, suffix])

	var candidate_mechanics: Dictionary = {}
	var current_mechanics: Dictionary = {}
	var candidate_variant: Variant = candidate.get("mechanics", [])
	if typeof(candidate_variant) == TYPE_ARRAY:
		for mechanic_variant: Variant in candidate_variant as Array:
			if typeof(mechanic_variant) == TYPE_DICTIONARY:
				var mechanic: Dictionary = mechanic_variant as Dictionary
				candidate_mechanics[String(mechanic.get("id", ""))] = String(mechanic.get("name", "Mechanic"))
	var current_variant: Variant = current.get("mechanics", [])
	if typeof(current_variant) == TYPE_ARRAY:
		for mechanic_variant: Variant in current_variant as Array:
			if typeof(mechanic_variant) == TYPE_DICTIONARY:
				var mechanic: Dictionary = mechanic_variant as Dictionary
				current_mechanics[String(mechanic.get("id", ""))] = String(mechanic.get("name", "Mechanic"))

	for mechanic_id_variant: Variant in candidate_mechanics.keys():
		var mechanic_id: String = String(mechanic_id_variant)
		if not current_mechanics.has(mechanic_id):
			lines.append("[color=#72df8b]+ %s[/color]" % String(candidate_mechanics[mechanic_id]))
	for mechanic_id_variant: Variant in current_mechanics.keys():
		var mechanic_id: String = String(mechanic_id_variant)
		if not candidate_mechanics.has(mechanic_id):
			lines.append("[color=#ff6d79]- %s[/color]" % String(current_mechanics[mechanic_id]))

	if lines.is_empty():
		return "[color=#8d96a6]No numerical or mechanical change.[/color]"
	return "\n".join(PackedStringArray(lines))

func _equip_selected_item() -> void:
	if selected_stash_item_id >= 0:
		_equip_item(selected_stash_item_id)

func _sell_selected_item() -> void:
	if selected_stash_item_id >= 0:
		_sell_item(selected_stash_item_id)

func _sell_filtered_gear() -> void:
	var sale: int = 0
	var kept: Array[Dictionary] = []
	for item: Dictionary in stash_gear:
		var matches_filter: bool = stash_filter == "all" or String(item.get("slot", "")) == stash_filter
		if matches_filter:
			sale += int(item.get("value", 0))
		else:
			kept.append(item)
	stash_coins += sale
	stash_gear = kept
	selected_stash_item_id = -1
	_update_hub_ui()
	_save_game()

func _equip_item(item_id: int) -> void:
	var index: int = _find_stash_item_index(item_id)
	if index < 0:
		return
	var item: Dictionary = stash_gear[index]
	var slot: String = String(item.get("slot", "charm"))
	var old_item: Dictionary = equipped.get(slot, {}) as Dictionary
	stash_gear.remove_at(index)
	if not old_item.is_empty():
		stash_gear.append(old_item.duplicate(true))
	equipped[slot] = item.duplicate(true)
	selected_stash_item_id = -1
	_update_hub_ui()
	_save_game()

func _sell_item(item_id: int) -> void:
	var index: int = _find_stash_item_index(item_id)
	if index < 0:
		return
	var item: Dictionary = stash_gear[index]
	stash_coins += int(item.get("value", 0))
	stash_gear.remove_at(index)
	selected_stash_item_id = -1
	_update_hub_ui()
	_save_game()

func _sell_all_gear() -> void:
	var sale: int = 0
	for item in stash_gear:
		sale += int(item.get("value", 0))
	stash_coins += sale
	stash_gear.clear()
	selected_stash_item_id = -1
	_update_hub_ui()
	_save_game()

func _find_stash_item_index(item_id: int) -> int:
	for i in range(stash_gear.size()):
		if int(stash_gear[i].get("id", -1)) == item_id:
			return i
	return -1

func _open_crafting_panel() -> void:
	_open_hub_station("craft")

func _close_crafting_panel() -> void:
	_close_hub_station()

func _refresh_crafting_panel() -> void:
	if crafting_panel == null:
		return
	crafting_currency_label.text = "[color=#82745a][font_size=10]MATERIALS[/font_size][/color]  Mut %d  Spl %d  Scr %d  Crn %d  Hrd %d  Chs %d  Pol %d  Mec %d" % [
		int(stash_crafting.get("mutation", 0)),
		int(stash_crafting.get("splice", 0)),
		int(stash_crafting.get("scrap", 0)),
		int(stash_crafting.get("crown", 0)),
		int(stash_crafting.get("hoarder", 0)),
		int(stash_crafting.get("chaos", 0)),
		int(stash_crafting.get("polish", 0)),
		int(stash_crafting.get("mechanist", 0))
	]
	_refresh_crafting_sources()

	var item: Dictionary = _get_crafting_target_item()
	if item.is_empty():
		crafting_item_label.text = "[color=#686157]Choose an equipped item or a stash item.[/color]"
		for button_variant: Variant in crafting_buttons.values():
			if button_variant is Button:
				(button_variant as Button).disabled = true
		for button_variant: Variant in core_buttons.values():
			if button_variant is Button:
				(button_variant as Button).disabled = true
				(button_variant as Button).visible = false
		return

	crafting_item_label.text = _item_to_bbcode(item)
	var rarity: String = String(item.get("rarity", "Common"))
	var affix_count: int = _item_affix_count(item)
	var affix_cap: int = _rarity_affix_cap(rarity)
	var is_weapon: bool = String(item.get("slot", "")) == "weapon"
	var weapon_archetype: String = String(item.get("weapon_archetype", "gun"))
	var current_core: String = String(item.get("core_id", "repeater"))

	for core_id_variant: Variant in core_buttons.keys():
		var core_id: String = String(core_id_variant)
		var core_button_variant: Variant = core_buttons.get(core_id)
		if core_button_variant is Button:
			var core_button := core_button_variant as Button
			var compatible: bool = is_weapon and _core_archetype(core_id) == weapon_archetype
			core_button.visible = compatible
			var slotted: bool = compatible and core_id == current_core
			core_button.text = "%s  x%d%s" % [_core_name(core_id).to_upper(), int(stash_cores.get(core_id, 0)), "  • SLOTTED" if slotted else ""]
			core_button.disabled = not compatible or slotted or int(stash_cores.get(core_id, 0)) <= 0
			core_button.add_theme_stylebox_override("normal", _arpg_button_style(slotted, false))

	_set_craft_button_state("mutation", rarity == "Common" and int(stash_crafting.get("mutation", 0)) > 0)
	_set_craft_button_state("splice", rarity == "Magic" and affix_count < 2 and int(stash_crafting.get("splice", 0)) > 0)
	_set_craft_button_state("scrap", rarity == "Magic" and int(stash_crafting.get("scrap", 0)) > 0)
	_set_craft_button_state("crown", claim_tier >= 2 and rarity == "Magic" and int(stash_crafting.get("crown", 0)) > 0)
	_set_craft_button_state("hoarder", claim_tier >= 2 and (rarity == "Rare" or rarity == "Gilded") and affix_count < affix_cap and int(stash_crafting.get("hoarder", 0)) > 0)
	_set_craft_button_state("chaos", claim_tier >= 2 and (rarity == "Rare" or rarity == "Gilded") and affix_count > 0 and int(stash_crafting.get("chaos", 0)) > 0)
	_set_craft_button_state("polish", claim_tier >= 3 and rarity != "Common" and affix_count > 0 and int(stash_crafting.get("polish", 0)) > 0)
	_set_craft_button_state("mechanist", claim_tier >= 3 and rarity != "Common" and int(stash_crafting.get("mechanist", 0)) > 0)

	var labels: Dictionary = {
		"mutation":"MUTATION SHARD  x%d\nCommon → Magic + 1 modifier" % int(stash_crafting.get("mutation", 0)),
		"splice":"SPLICE SHARD  x%d\nAdd 1 modifier to Magic" % int(stash_crafting.get("splice", 0)),
		"scrap":"SCRAP ORB  x%d\nReforge Magic modifiers" % int(stash_crafting.get("scrap", 0)),
		"crown":"CROWN TOKEN  x%d\nMagic → Rare, keep mods + add 1" % int(stash_crafting.get("crown", 0)),
		"hoarder":"HOARDER'S ORB  x%d\nAdd 1 modifier to Rare" % int(stash_crafting.get("hoarder", 0)),
		"chaos":"CHAOS TOKEN  x%d\nReplace 1 random Rare modifier" % int(stash_crafting.get("chaos", 0)),
		"polish":"POLISH ORB  x%d\nReroll values, keep tiers" % int(stash_crafting.get("polish", 0)),
		"mechanist":"MECHANIST'S SEAL  x%d\nAdd or reroll an Augment" % int(stash_crafting.get("mechanist", 0))
	}
	for key_variant: Variant in labels.keys():
		var key: String = String(key_variant)
		var button_variant: Variant = crafting_buttons.get(key)
		if button_variant is Button:
			var button := button_variant as Button
			button.text = String(labels[key])
			if key == "crown" and claim_tier < 2:
				button.text = "CROWN TOKEN\nLocked until Claim T2"
			elif (key == "hoarder" or key == "chaos") and claim_tier < 2:
				button.text = "%s\nLocked until Claim T2" % _craft_currency_name(key).to_upper()
			elif (key == "polish" or key == "mechanist") and claim_tier < 3:
				button.text = "%s\nLocked until Claim T3" % _craft_currency_name(key).to_upper()

func _refresh_crafting_sources() -> void:
	for slot_name: String in ["weapon", "armor", "charm"]:
		var button_variant: Variant = crafting_equipped_buttons.get(slot_name)
		if not button_variant is Button:
			continue
		var button := button_variant as Button
		var item: Dictionary = equipped.get(slot_name, {}) as Dictionary
		var selected: bool = crafting_target_source == "equipped" and crafting_target_slot == slot_name
		if item.is_empty():
			button.text = "%s\nEMPTY" % slot_name.to_upper()
			button.disabled = true
			button.add_theme_color_override("font_color", Color(0.42, 0.40, 0.36))
		else:
			button.text = "%s\n%s" % [slot_name.to_upper(), _grid_item_short_name(item)]
			button.disabled = false
			button.add_theme_color_override("font_color", _rarity_color(String(item.get("rarity", "Common"))))
		button.add_theme_stylebox_override("normal", _arpg_button_style(selected, false))

	if crafting_stash_grid == null:
		return
	for child: Node in crafting_stash_grid.get_children():
		child.queue_free()

	for item: Dictionary in stash_gear:
		var item_id: int = int(item.get("id", -1))
		var rarity: String = String(item.get("rarity", "Common"))
		var selected: bool = crafting_target_source == "stash" and selected_stash_item_id == item_id
		var button := Button.new()
		button.custom_minimum_size = Vector2(70.0, 58.0)
		button.text = "%s\n%s" % [_grid_item_glyph(String(item.get("slot", "gear"))), _grid_item_short_name(item)]
		button.add_theme_font_size_override("font_size", 9)
		button.tooltip_text = "%s\n%s • ilvl %d" % [String(item.get("name", "Item")), rarity, int(item.get("item_level", 1))]
		button.add_theme_color_override("font_color", _rarity_color(rarity))
		button.add_theme_stylebox_override("normal", _arpg_slot_style(_rarity_color(rarity), selected))
		button.add_theme_stylebox_override("hover", _arpg_slot_style(Color(0.74, 0.57, 0.29), true))
		button.pressed.connect(_select_crafting_stash_item.bind(item_id))
		crafting_stash_grid.add_child(button)

func _select_crafting_stash_item(item_id: int) -> void:
	if _find_stash_item_index(item_id) < 0:
		return
	selected_stash_item_id = item_id
	crafting_target_source = "stash"
	crafting_target_slot = ""
	crafting_feedback_label.text = "Stash item selected."
	_refresh_crafting_panel()

func _select_crafting_equipped(slot_name: String) -> void:
	var item: Dictionary = equipped.get(slot_name, {}) as Dictionary
	if item.is_empty():
		return
	crafting_target_source = "equipped"
	crafting_target_slot = slot_name
	selected_stash_item_id = -1
	crafting_feedback_label.text = "%s selected from equipped gear." % slot_name.capitalize()
	_refresh_crafting_panel()

func _get_crafting_target_item() -> Dictionary:
	if crafting_target_source == "equipped":
		return (equipped.get(crafting_target_slot, {}) as Dictionary).duplicate(true)
	if crafting_target_source == "stash":
		var index: int = _find_stash_item_index(selected_stash_item_id)
		if index >= 0:
			return stash_gear[index].duplicate(true)
	return {}

func _store_crafting_target_item(item: Dictionary) -> void:
	if crafting_target_source == "equipped":
		if not crafting_target_slot.is_empty():
			equipped[crafting_target_slot] = item.duplicate(true)
	elif crafting_target_source == "stash":
		var index: int = _find_stash_item_index(selected_stash_item_id)
		if index >= 0:
			stash_gear[index] = item.duplicate(true)

func _set_craft_button_state(key: String, enabled: bool) -> void:
	var button_variant: Variant = crafting_buttons.get(key)
	if button_variant is Button:
		(button_variant as Button).disabled = not enabled

func _slot_core(core_id: String) -> void:
	if int(stash_cores.get(core_id, 0)) <= 0:
		return
	var item: Dictionary = _get_crafting_target_item()
	if item.is_empty() or String(item.get("slot", "")) != "weapon":
		return
	var weapon_archetype: String = String(item.get("weapon_archetype", "gun"))
	if _core_archetype(core_id) != weapon_archetype:
		return
	var old_core: String = String(item.get("core_id", "repeater"))
	if old_core == core_id:
		return
	stash_cores[core_id] = int(stash_cores.get(core_id, 0)) - 1
	stash_cores[old_core] = int(stash_cores.get(old_core, 0)) + 1
	item["core_id"] = core_id
	item["name"] = _make_generated_item_name(item)
	_store_crafting_target_item(item)
	crafting_feedback_label.text = "%s CORE SLOTTED — %s returned to storage." % [_core_name(core_id).to_upper(), _core_name(old_core)]
	_after_craft()

func _rarity_affix_cap(rarity: String) -> int:
	match rarity:
		"Gilded": return 4
		"Rare": return 4
		"Magic": return 2
		_: return 0

func _roll_unique_affix(item: Dictionary, used_stats: Array[String]) -> Dictionary:
	var available: Array[String] = []
	for candidate: String in _affix_candidates(String(item.get("slot", "charm"))):
		if not used_stats.has(candidate):
			available.append(candidate)
	if available.is_empty():
		return {}
	var stat: String = available[rng.randi_range(0, available.size() - 1)]
	var tier: int = _roll_affix_tier(maxi(1, int(item.get("depth", 1))))
	return _make_affix_record(stat, tier, _roll_affix_value(stat, tier))

func _used_affix_stats(item: Dictionary) -> Array[String]:
	var used: Array[String] = []
	var affixes_variant: Variant = item.get("affixes", [])
	if typeof(affixes_variant) == TYPE_ARRAY:
		var affixes: Array = affixes_variant as Array
		for affix_variant: Variant in affixes:
			if typeof(affix_variant) == TYPE_DICTIONARY:
				used.append(String((affix_variant as Dictionary).get("stat", "")))
	return used

func _append_random_affix(item: Dictionary) -> bool:
	if _item_affix_count(item) >= _rarity_affix_cap(String(item.get("rarity", "Common"))):
		return false
	var affix: Dictionary = _roll_unique_affix(item, _used_affix_stats(item))
	if affix.is_empty():
		return false
	var affixes_variant: Variant = item.get("affixes", [])
	var affixes: Array = (affixes_variant as Array).duplicate(true) if typeof(affixes_variant) == TYPE_ARRAY else []
	affixes.append(affix)
	item["affixes"] = affixes
	_rebuild_item_stats(item)
	return true

func _craft_mutation() -> void:
	if int(stash_crafting.get("mutation", 0)) <= 0:
		return
	var item: Dictionary = _get_crafting_target_item()
	if item.is_empty() or String(item.get("rarity", "Common")) != "Common":
		return
	item["rarity"] = "Magic"
	item["affixes"] = []
	_append_random_affix(item)
	_finalize_crafted_item(item)
	_store_crafting_target_item(item)
	_spend_crafting_currency("mutation")
	crafting_feedback_label.text = "MUTATED — Magic item created with one random modifier."
	_after_craft()

func _craft_splice() -> void:
	if int(stash_crafting.get("splice", 0)) <= 0:
		return
	var item: Dictionary = _get_crafting_target_item()
	if item.is_empty() or String(item.get("rarity", "Common")) != "Magic" or _item_affix_count(item) >= 2:
		return
	if not _append_random_affix(item):
		return
	_finalize_crafted_item(item)
	_store_crafting_target_item(item)
	_spend_crafting_currency("splice")
	crafting_feedback_label.text = "SPLICED — one random modifier added. Existing rolls survived."
	_after_craft()

func _craft_scrap() -> void:
	if int(stash_crafting.get("scrap", 0)) <= 0:
		return
	var item: Dictionary = _get_crafting_target_item()
	if item.is_empty() or String(item.get("rarity", "Common")) != "Magic":
		return
	item["affixes"] = []
	var mod_count: int = 2 if rng.randf() < 0.45 else 1
	for _i in range(mod_count):
		if not _append_random_affix(item):
			break
	_finalize_crafted_item(item)
	_store_crafting_target_item(item)
	_spend_crafting_currency("scrap")
	crafting_feedback_label.text = "SCRAPPED — Magic modifiers completely reforged."
	_after_craft()

func _craft_crown() -> void:
	if claim_tier < 2 or int(stash_crafting.get("crown", 0)) <= 0:
		return
	var item: Dictionary = _get_crafting_target_item()
	if item.is_empty() or String(item.get("rarity", "Common")) != "Magic":
		return
	item["rarity"] = "Rare"
	_append_random_affix(item)
	_finalize_crafted_item(item)
	_store_crafting_target_item(item)
	_spend_crafting_currency("crown")
	crafting_feedback_label.text = "CROWNED — your Magic rolls survived and the item became Rare."
	_after_craft()

func _craft_hoarder() -> void:
	if claim_tier < 2 or int(stash_crafting.get("hoarder", 0)) <= 0:
		return
	var item: Dictionary = _get_crafting_target_item()
	var rarity: String = String(item.get("rarity", "Common"))
	if item.is_empty() or (rarity != "Rare" and rarity != "Gilded"):
		return
	if not _append_random_affix(item):
		return
	_finalize_crafted_item(item)
	_store_crafting_target_item(item)
	_spend_crafting_currency("hoarder")
	crafting_feedback_label.text = "HOARDER SLAM — one new modifier added. No take-backs."
	_after_craft()

func _craft_chaos() -> void:
	if claim_tier < 2 or int(stash_crafting.get("chaos", 0)) <= 0:
		return
	var item: Dictionary = _get_crafting_target_item()
	var rarity: String = String(item.get("rarity", "Common"))
	if item.is_empty() or (rarity != "Rare" and rarity != "Gilded"):
		return
	var affixes_variant: Variant = item.get("affixes", [])
	if typeof(affixes_variant) != TYPE_ARRAY:
		return
	var affixes: Array = (affixes_variant as Array).duplicate(true)
	if affixes.is_empty():
		return
	affixes.remove_at(rng.randi_range(0, affixes.size() - 1))
	item["affixes"] = affixes
	_rebuild_item_stats(item)
	_append_random_affix(item)
	_finalize_crafted_item(item)
	_store_crafting_target_item(item)
	_spend_crafting_currency("chaos")
	crafting_feedback_label.text = "CHAOS SLAMMED — one modifier was sacrificed for a random replacement."
	_after_craft()

func _craft_polish() -> void:
	if claim_tier < 3 or int(stash_crafting.get("polish", 0)) <= 0:
		return
	var item: Dictionary = _get_crafting_target_item()
	if item.is_empty() or String(item.get("rarity", "Common")) == "Common":
		return
	var affixes_variant: Variant = item.get("affixes", [])
	if typeof(affixes_variant) != TYPE_ARRAY or (affixes_variant as Array).is_empty():
		return
	var polished: Array[Dictionary] = []
	var affixes: Array = affixes_variant as Array
	for affix_variant: Variant in affixes:
		if typeof(affix_variant) != TYPE_DICTIONARY:
			continue
		var affix: Dictionary = affix_variant as Dictionary
		var stat: String = String(affix.get("stat", "damage"))
		var tier: int = int(affix.get("tier", 5))
		polished.append(_make_affix_record(stat, tier, _roll_affix_value(stat, tier)))
	item["affixes"] = polished
	_rebuild_item_stats(item)
	_finalize_crafted_item(item)
	_store_crafting_target_item(item)
	_spend_crafting_currency("polish")
	crafting_feedback_label.text = "POLISHED — modifier identities and tiers stayed; values rerolled."
	_after_craft()

func _craft_mechanist() -> void:
	if claim_tier < 3 or int(stash_crafting.get("mechanist", 0)) <= 0:
		return
	var item: Dictionary = _get_crafting_target_item()
	if item.is_empty() or String(item.get("rarity", "Common")) == "Common":
		return
	var mechanics_variant: Variant = item.get("mechanics", [])
	var mechanics: Array = (mechanics_variant as Array).duplicate(true) if typeof(mechanics_variant) == TYPE_ARRAY else []
	var max_mechanics: int = 2 if String(item.get("rarity", "Common")) == "Gilded" else 1
	var used_ids: Array[String] = []
	for mechanic_variant: Variant in mechanics:
		if typeof(mechanic_variant) == TYPE_DICTIONARY:
			used_ids.append(String((mechanic_variant as Dictionary).get("id", "")))
	if mechanics.size() < max_mechanics:
		var added: Dictionary = _roll_mechanic(String(item.get("slot", "charm")), used_ids, true, String(item.get("weapon_archetype", "")))
		if added.is_empty():
			return
		mechanics.append(added)
		crafting_feedback_label.text = "MECHANIST — a new Augment was installed."
	else:
		var target_index: int = rng.randi_range(0, mechanics.size() - 1)
		var kept_ids: Array[String] = []
		for i in range(mechanics.size()):
			if i == target_index or typeof(mechanics[i]) != TYPE_DICTIONARY:
				continue
			kept_ids.append(String((mechanics[i] as Dictionary).get("id", "")))
		var replacement: Dictionary = _roll_mechanic(String(item.get("slot", "charm")), kept_ids, true, String(item.get("weapon_archetype", "")))
		if replacement.is_empty():
			return
		mechanics[target_index] = replacement
		crafting_feedback_label.text = "MECHANIST — one Augment was rerolled."
	item["mechanics"] = mechanics
	_finalize_crafted_item(item)
	_store_crafting_target_item(item)
	_spend_crafting_currency("mechanist")
	_after_craft()

func _after_craft() -> void:
	_update_hub_ui()
	if is_instance_valid(player) and state == "hub":
		player.configure(_calculate_player_stats())
	_refresh_crafting_panel()
	_save_game()

func _spend_crafting_currency(key: String) -> void:
	stash_crafting[key] = maxi(0, int(stash_crafting.get(key, 0)) - 1)

func _item_affix_count(item: Dictionary) -> int:
	var affixes_variant: Variant = item.get("affixes", [])
	return (affixes_variant as Array).size() if typeof(affixes_variant) == TYPE_ARRAY else 0

func _item_mechanic_count(item: Dictionary) -> int:
	var mechanics_variant: Variant = item.get("mechanics", [])
	return (mechanics_variant as Array).size() if typeof(mechanics_variant) == TYPE_ARRAY else 0

func _rebuild_item_stats(item: Dictionary) -> void:
	var stat_keys: Array[String] = ["damage", "attack_speed", "max_hp", "move_speed", "currency_find", "item_find"]
	for stat: String in stat_keys:
		item[stat] = 0.0

	var implicit_variant: Variant = item.get("implicit", {})
	if typeof(implicit_variant) == TYPE_DICTIONARY:
		var implicit: Dictionary = implicit_variant as Dictionary
		if not implicit.is_empty():
			_apply_item_stat(item, String(implicit.get("stat", "")), float(implicit.get("value", 0.0)))

	var affixes_variant: Variant = item.get("affixes", [])
	if typeof(affixes_variant) == TYPE_ARRAY:
		for affix_variant: Variant in affixes_variant as Array:
			if typeof(affix_variant) != TYPE_DICTIONARY:
				continue
			var affix: Dictionary = affix_variant as Dictionary
			_apply_item_stat(item, String(affix.get("stat", "")), float(affix.get("value", 0.0)))

func _finalize_crafted_item(item: Dictionary) -> void:
	item["crafted"] = true
	item["name"] = _make_generated_item_name(item)
	item["value"] = _item_value(item)

func _craft_currency_name(key: String) -> String:
	match key:
		"mutation": return "Mutation Shard"
		"splice": return "Splice Shard"
		"scrap": return "Scrap Orb"
		"crown": return "Crown Token"
		"hoarder": return "Hoarder's Orb"
		"chaos": return "Chaos Token"
		"polish": return "Polish Orb"
		"mechanist": return "Mechanist's Seal"
		_: return key.capitalize()

func _crafting_inventory_value(inventory: Dictionary) -> int:
	return (
		int(inventory.get("mutation", 0)) * 90 +
		int(inventory.get("splice", 0)) * 110 +
		int(inventory.get("scrap", 0)) * 70 +
		int(inventory.get("crown", 0)) * 320 +
		int(inventory.get("hoarder", 0)) * 700 +
		int(inventory.get("chaos", 0)) * 650 +
		int(inventory.get("polish", 0)) * 1200 +
		int(inventory.get("mechanist", 0)) * 1800
	)

func _crafting_inventory_count(inventory: Dictionary) -> int:
	var total: int = 0
	var keys: Array[String] = ["mutation", "splice", "scrap", "crown", "hoarder", "chaos", "polish", "mechanist"]
	for key: String in keys:
		total += int(inventory.get(key, 0))
	return total

func _core_inventory_value(inventory: Dictionary) -> int:
	return _core_inventory_count(inventory) * 250

func _core_inventory_count(inventory: Dictionary) -> int:
	var total: int = 0
	var core_ids: Array[String] = ["repeater", "scatter", "piercer", "sprayer", "cleaver", "duelist", "whirlwind", "throwing"]
	for core_id: String in core_ids:
		total += int(inventory.get(core_id, 0))
	return total

func _juice_density() -> void:
	if juice_density < 5 and _spend_seal_for_juice():
		juice_density += 1
	_update_hub_ui()

func _juice_quantity() -> void:
	if juice_quantity < 5 and _spend_seal_for_juice():
		juice_quantity += 1
	_update_hub_ui()

func _juice_currency() -> void:
	if juice_currency < 5 and _spend_seal_for_juice():
		juice_currency += 1
	_update_hub_ui()

func _juice_elite() -> void:
	if juice_elite < 5 and _spend_seal_for_juice():
		juice_elite += 1
	_update_hub_ui()

func _spend_seal_for_juice() -> bool:
	if stash_seals <= 0:
		return false
	stash_seals -= 1
	return true

func _reset_juice() -> void:
	if state == "hub":
		stash_seals += juice_density + juice_quantity + juice_currency + juice_elite
	_clear_juice()
	if state == "hub":
		_update_hub_ui()

func _clear_juice() -> void:
	juice_density = 0
	juice_quantity = 0
	juice_currency = 0
	juice_elite = 0

func _update_top_bar() -> void:
	if top_label == null:
		return
	coins_label.text = "COINS\n₵%d" % stash_coins
	seals_label.text = "SEALS\n◈ %d" % stash_seals
	networth_label.text = "NET WORTH\n₵%d" % _calculate_net_worth()

	if state == "run":
		top_label.text = "CLAIM"
		run_label.text = "T%d  D%d  •  ROOM %d/%d  %s  •  %d ENEMIES  •  UNSECURED ₵%d" % [claim_tier, depth, room_index, rooms_total, current_room_type, alive_enemies, _current_run_value()]
	else:
		top_label.text = "HIDEOUT"
		run_label.text = ""

func _add_feed(text_value: String) -> void:
	feed_lines.push_front(text_value)
	while feed_lines.size() > 7:
		feed_lines.pop_back()
	feed_label.text = "\n".join(feed_lines)

func _clear_runtime_nodes() -> void:
	var layers: Array[Node2D] = [actor_layer, projectile_layer, loot_layer]
	for layer: Node2D in layers:
		if layer == null:
			continue
		for child: Node in layer.get_children():
			child.queue_free()
	alive_enemies = 0
	player = null

func _ensure_starter_gear() -> void:
	if (equipped.get("weapon", {}) as Dictionary).is_empty():
		equipped["weapon"] = _make_starter_item("weapon")
	if (equipped.get("armor", {}) as Dictionary).is_empty():
		equipped["armor"] = _make_starter_item("armor")
	if (equipped.get("charm", {}) as Dictionary).is_empty():
		equipped["charm"] = _make_starter_item("charm")
	if not blade_intro_granted:
		stash_gear.append(_make_intro_blade())
		blade_intro_granted = true

func _make_intro_blade() -> Dictionary:
	var item: Dictionary = {
		"id": next_item_id,
		"slot": "weapon",
		"rarity": "Common",
		"name": "Rusty Scrap Blade",
		"base_name": "Scrap Blade",
		"weapon_archetype": "blade",
		"core_id": "cleaver",
		"depth": 0,
		"item_level": 1,
		"damage": 3.0,
		"attack_speed": 0.0,
		"max_hp": 0.0,
		"move_speed": 0.0,
		"currency_find": 0.0,
		"item_find": 0.0,
		"implicit": {"stat":"damage", "value":3.0, "label":"Damage"},
		"affixes": [],
		"mechanics": []
	}
	next_item_id += 1
	item["value"] = _item_value(item)
	return item

func _save_game() -> void:
	var data: Dictionary = {
		"coins": stash_coins,
		"seals": stash_seals,
		"gear": stash_gear,
		"crafting": stash_crafting,
		"cores": stash_cores,
		"equipped": equipped,
		"next_item_id": next_item_id,
		"blade_intro_granted": blade_intro_granted,
		"claim_tier": claim_tier,
		"tier_best_depths": tier_best_depths
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed as Dictionary
	stash_coins = int(data.get("coins", 0))
	stash_seals = int(data.get("seals", 5))
	if data.has("cores"):
		var cores_variant: Variant = data.get("cores", {})
		if typeof(cores_variant) == TYPE_DICTIONARY:
			var loaded_cores: Dictionary = cores_variant as Dictionary
			var core_keys: Array[String] = ["repeater", "scatter", "piercer", "sprayer", "cleaver", "duelist", "whirlwind", "throwing"]
			for core_key: String in core_keys:
				stash_cores[core_key] = maxi(0, int(loaded_cores.get(core_key, 0)))
	if data.has("cores"):
		var blade_seed_keys: Array[String] = ["cleaver", "duelist", "whirlwind", "throwing"]
		var saved_cores_variant: Variant = data.get("cores", {})
		if typeof(saved_cores_variant) == TYPE_DICTIONARY:
			var saved_cores: Dictionary = saved_cores_variant as Dictionary
			for blade_core: String in blade_seed_keys:
				if not saved_cores.has(blade_core):
					stash_cores[blade_core] = 1
	var crafting_variant: Variant = data.get("crafting", {})
	if typeof(crafting_variant) == TYPE_DICTIONARY:
		var loaded_crafting: Dictionary = crafting_variant as Dictionary
		var crafting_keys: Array[String] = ["mutation", "splice", "scrap", "crown", "hoarder", "chaos", "polish", "mechanist"]
		for currency_key: String in crafting_keys:
			stash_crafting[currency_key] = maxi(0, int(loaded_crafting.get(currency_key, 0)))
	next_item_id = int(data.get("next_item_id", 1))
	blade_intro_granted = bool(data.get("blade_intro_granted", false))
	claim_tier = clampi(int(data.get("claim_tier", 1)), 1, 5)
	var depths_variant: Variant = data.get("tier_best_depths", {})
	if typeof(depths_variant) == TYPE_DICTIONARY:
		var loaded_depths: Dictionary = depths_variant as Dictionary
		for tier_number in range(1, 6):
			var tier_key: String = str(tier_number)
			tier_best_depths[tier_key] = maxi(0, int(loaded_depths.get(tier_key, 0)))
	var gear_variant: Variant = data.get("gear", [])
	if typeof(gear_variant) == TYPE_ARRAY:
		var loaded_gear: Array = gear_variant as Array
		for entry: Variant in loaded_gear:
			if typeof(entry) == TYPE_DICTIONARY:
				stash_gear.append(_normalize_item(entry as Dictionary))
	var equipped_variant: Variant = data.get("equipped", {})
	if typeof(equipped_variant) == TYPE_DICTIONARY:
		var loaded_equipped: Dictionary = equipped_variant as Dictionary
		var gear_slots: Array[String] = ["weapon", "armor", "charm"]
		for slot_name: String in gear_slots:
			var item_variant: Variant = loaded_equipped.get(slot_name, {})
			if typeof(item_variant) == TYPE_DICTIONARY:
				equipped[slot_name] = _normalize_item(item_variant as Dictionary)

func _wipe_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	stash_coins = 0
	stash_seals = 5
	stash_gear.clear()
	stash_crafting = {"scrap": 0, "mutation": 0, "splice": 0, "crown": 0, "hoarder": 0, "chaos": 0, "polish": 0, "mechanist": 0}
	stash_cores = {"repeater": 0, "scatter": 1, "piercer": 1, "sprayer": 1, "cleaver": 1, "duelist": 1, "whirlwind": 1, "throwing": 1}
	equipped = {"weapon": {}, "armor": {}, "charm": {}}
	next_item_id = 1
	blade_intro_granted = false
	selected_stash_item_id = -1
	crafting_target_source = "none"
	crafting_target_slot = ""
	stash_filter = "all"
	stash_sort_mode = "value"
	claim_tier = 1
	tier_best_depths = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
	_ensure_starter_gear()
	_update_hub_ui()
	_save_game()
