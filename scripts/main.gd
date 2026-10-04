extends Node2D

const SAVE_PATH: String = "user://loot_rat_save.json"
const ARENA_BOUNDS: Rect2 = Rect2(40.0, 80.0, 1200.0, 590.0)
const HIDEOUT_BOUNDS: Rect2 = Rect2(70.0, 105.0, 1140.0, 535.0)
const HideoutScript = preload("res://scripts/hideout.gd")

var rng := RandomNumberGenerator.new()

var arena: LootArena = null
var hideout: Node2D = null
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
var inventory_list: VBoxContainer = null
var equipped_label: RichTextLabel = null
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
var stash_crafting: Dictionary = {"scrap": 0, "mutation": 0, "chaos": 0, "mechanist": 0}
var equipped: Dictionary = {"weapon": {}, "armor": {}, "charm": {}}
var next_item_id: int = 1

var run_coins: int = 0
var run_seals: int = 0
var run_gear: Array[Dictionary] = []
var run_crafting: Dictionary = {"scrap": 0, "mutation": 0, "chaos": 0, "mechanist": 0}

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
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 12.0
	return style

func _section_title(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
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
	hub_panel.position = Vector2(18.0, 90.0)
	hub_panel.size = Vector2(300.0, 574.0)
	hub_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.030, 0.036, 0.050), Color(0.16, 0.19, 0.25), 1))
	hud.add_child(hub_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	hub_panel.add_child(root)

	root.add_child(_section_title("CLAIM PREP"))
	root.add_child(_muted_label("Invest Seals now. The payout stays unsecured until you extract."))

	claim_label = RichTextLabel.new()
	claim_label.bbcode_enabled = true
	claim_label.fit_content = false
	claim_label.custom_minimum_size = Vector2(270.0, 154.0)
	claim_label.add_theme_font_size_override("normal_font_size", 15)
	root.add_child(claim_label)

	var juice_title := _muted_label("MODIFIERS  •  each click costs 1 Seal")
	juice_title.add_theme_color_override("font_color", Color(0.68, 0.72, 0.80))
	root.add_child(juice_title)

	root.add_child(_make_button("DENSITY  +20%", _juice_density, Vector2(270.0, 31.0)))
	root.add_child(_make_button("ITEM QUANTITY  +25%", _juice_quantity, Vector2(270.0, 31.0)))
	root.add_child(_make_button("CURRENCY  +25%", _juice_currency, Vector2(270.0, 31.0)))
	root.add_child(_make_button("ELITE CHANCE  +3.5%", _juice_elite, Vector2(270.0, 31.0)))

	var run_button := _make_button("RUN CLAIM", _start_claim, Vector2(270.0, 42.0))
	run_button.add_theme_font_size_override("font_size", 19)
	root.add_child(run_button)

	var reset_button := _make_button("RESET INVESTMENT", _reset_juice, Vector2(270.0, 27.0))
	reset_button.add_theme_font_size_override("font_size", 12)
	root.add_child(reset_button)

	claim_unlock_button = _make_button("NEXT TIER LOCKED", _unlock_next_claim_tier, Vector2(270.0, 31.0))
	claim_unlock_button.add_theme_font_size_override("font_size", 12)
	root.add_child(claim_unlock_button)

func _build_character_panel() -> void:
	character_panel = PanelContainer.new()
	character_panel.position = Vector2(328.0, 90.0)
	character_panel.size = Vector2(340.0, 574.0)
	character_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.030, 0.036, 0.050), Color(0.16, 0.19, 0.25), 1))
	hud.add_child(character_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	character_panel.add_child(root)

	root.add_child(_section_title("LOADOUT"))
	root.add_child(_muted_label("Equipped gear drives combat power and loot efficiency."))

	equipped_label = RichTextLabel.new()
	equipped_label.bbcode_enabled = true
	equipped_label.fit_content = false
	equipped_label.custom_minimum_size = Vector2(310.0, 190.0)
	equipped_label.add_theme_font_size_override("normal_font_size", 14)
	root.add_child(equipped_label)

	var divider := HSeparator.new()
	root.add_child(divider)

	var stat_header := Label.new()
	stat_header.text = "BUILD STATS"
	stat_header.add_theme_font_size_override("font_size", 18)
	stat_header.add_theme_color_override("font_color", Color(0.78, 0.82, 0.90))
	root.add_child(stat_header)

	stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.fit_content = false
	stats_label.custom_minimum_size = Vector2(310.0, 255.0)
	stats_label.add_theme_font_size_override("normal_font_size", 15)
	root.add_child(stats_label)

func _build_gear_panel() -> void:
	gear_panel = PanelContainer.new()
	gear_panel.position = Vector2(678.0, 90.0)
	gear_panel.size = Vector2(584.0, 574.0)
	gear_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.030, 0.036, 0.050), Color(0.16, 0.19, 0.25), 1))
	hud.add_child(gear_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	gear_panel.add_child(root)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	root.add_child(header_row)

	var title := _section_title("STASH")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	stash_count_label = _muted_label("")
	stash_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stash_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(stash_count_label)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 5)
	root.add_child(filter_row)

	var filter_specs: Array[Dictionary] = [
		{"key":"all", "label":"ALL"},
		{"key":"weapon", "label":"WEAPONS"},
		{"key":"armor", "label":"ARMOR"},
		{"key":"charm", "label":"CHARMS"}
	]
	for spec: Dictionary in filter_specs:
		var key: String = String(spec["key"])
		var filter_button := _make_button(String(spec["label"]), _set_stash_filter.bind(key), Vector2(78.0, 32.0))
		filter_button.add_theme_font_size_override("font_size", 12)
		filter_buttons[key] = filter_button
		filter_row.add_child(filter_button)

	sort_button = _make_button("SORT: VALUE", _cycle_stash_sort, Vector2(135.0, 32.0))
	sort_button.add_theme_font_size_override("font_size", 12)
	filter_row.add_child(sort_button)

	var content_row := HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 10)
	root.add_child(content_row)

	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(310.0, 430.0)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.020, 0.024, 0.034), Color(0.10, 0.12, 0.16), 1))
	content_row.add_child(list_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(scroll)

	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 5)
	scroll.add_child(inventory_list)

	var inspector_panel := PanelContainer.new()
	inspector_panel.custom_minimum_size = Vector2(230.0, 430.0)
	inspector_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.022, 0.027, 0.038), Color(0.12, 0.15, 0.20), 1))
	content_row.add_child(inspector_panel)

	var inspector_root := VBoxContainer.new()
	inspector_root.add_theme_constant_override("separation", 8)
	inspector_panel.add_child(inspector_root)

	var inspect_header := Label.new()
	inspect_header.text = "ITEM INSPECTOR"
	inspect_header.add_theme_font_size_override("font_size", 16)
	inspect_header.add_theme_color_override("font_color", Color(0.78, 0.82, 0.90))
	inspector_root.add_child(inspect_header)

	selected_item_label = RichTextLabel.new()
	selected_item_label.bbcode_enabled = true
	selected_item_label.fit_content = false
	selected_item_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selected_item_label.custom_minimum_size = Vector2(202.0, 238.0)
	selected_item_label.add_theme_font_size_override("normal_font_size", 14)
	inspector_root.add_child(selected_item_label)

	selected_equip_button = _make_button("EQUIP SELECTED", _equip_selected_item, Vector2(202.0, 38.0))
	inspector_root.add_child(selected_equip_button)

	selected_sell_button = _make_button("SELL SELECTED", _sell_selected_item, Vector2(202.0, 38.0))
	inspector_root.add_child(selected_sell_button)

	selected_craft_button = _make_button("CRAFT SELECTED", _open_crafting_panel, Vector2(202.0, 38.0))
	selected_craft_button.add_theme_font_size_override("font_size", 13)
	inspector_root.add_child(selected_craft_button)

	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 8)
	root.add_child(footer_row)
	footer_row.add_child(_make_button("SELL FILTERED", _sell_filtered_gear, Vector2(150.0, 34.0)))
	var wipe_button := _make_button("WIPE SAVE", _wipe_save, Vector2(105.0, 34.0))
	wipe_button.add_theme_font_size_override("font_size", 11)
	footer_row.add_child(wipe_button)

func _build_crafting_panel() -> void:
	crafting_panel = PanelContainer.new()
	crafting_panel.position = Vector2(385.0, 92.0)
	crafting_panel.size = Vector2(510.0, 560.0)
	crafting_panel.visible = false
	crafting_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.030, 0.042, 0.99), Color(0.55, 0.39, 0.16), 2))
	hud.add_child(crafting_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	crafting_panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := _section_title("CRAFTING BENCH")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := _make_button("CLOSE", _close_crafting_panel, Vector2(82.0, 30.0))
	close_button.add_theme_font_size_override("font_size", 12)
	header.add_child(close_button)

	root.add_child(_muted_label("Build an item over time. Every craft consumes a dropped currency permanently."))

	crafting_currency_label = RichTextLabel.new()
	crafting_currency_label.bbcode_enabled = true
	crafting_currency_label.fit_content = false
	crafting_currency_label.custom_minimum_size = Vector2(475.0, 48.0)
	crafting_currency_label.add_theme_font_size_override("normal_font_size", 14)
	root.add_child(crafting_currency_label)

	crafting_item_label = RichTextLabel.new()
	crafting_item_label.bbcode_enabled = true
	crafting_item_label.fit_content = false
	crafting_item_label.custom_minimum_size = Vector2(475.0, 160.0)
	crafting_item_label.add_theme_font_size_override("normal_font_size", 14)
	root.add_child(crafting_item_label)

	var scrap_button := _make_button("SCRAP ORB  •  REROLL VALUES", _craft_scrap, Vector2(475.0, 40.0))
	scrap_button.add_theme_font_size_override("font_size", 13)
	crafting_buttons["scrap"] = scrap_button
	root.add_child(scrap_button)

	var mutation_button := _make_button("MUTATION SHARD  •  SLAM COMMON → MAGIC", _craft_mutation, Vector2(475.0, 40.0))
	mutation_button.add_theme_font_size_override("font_size", 13)
	crafting_buttons["mutation"] = mutation_button
	root.add_child(mutation_button)

	var chaos_button := _make_button("CHAOS TOKEN  •  REROLL NORMAL AFFIXES", _craft_chaos, Vector2(475.0, 40.0))
	chaos_button.add_theme_font_size_override("font_size", 13)
	crafting_buttons["chaos"] = chaos_button
	root.add_child(chaos_button)

	var mechanist_button := _make_button("MECHANIST'S SEAL  •  REROLL MECHANIC", _craft_mechanist, Vector2(475.0, 40.0))
	mechanist_button.add_theme_font_size_override("font_size", 13)
	crafting_buttons["mechanist"] = mechanist_button
	root.add_child(mechanist_button)

	crafting_feedback_label = _muted_label("Select a stash item, then decide how much you are willing to risk on it.")
	crafting_feedback_label.custom_minimum_size = Vector2(475.0, 38.0)
	crafting_feedback_label.add_theme_color_override("font_color", Color(0.78, 0.70, 0.52))
	root.add_child(crafting_feedback_label)

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
	run_crafting = {"scrap": 0, "mutation": 0, "chaos": 0, "mechanist": 0}
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
	if rng.randf() < 0.030 * quantity_mult * elite_mult:
		_spawn_pickup("craft", 1, {"currency":"scrap"}, position_value)
	if rng.randf() < 0.008 * quantity_mult * (3.0 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"mutation"}, position_value)
	if claim_tier >= 2 and rng.randf() < 0.0025 * quantity_mult * (4.0 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"chaos"}, position_value)
	if claim_tier >= 3 and rng.randf() < 0.0008 * quantity_mult * (5.0 if elite else 1.0):
		_spawn_pickup("craft", 1, {"currency":"mechanist"}, position_value)

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
	decision_body.text = "Unsecured haul: ₵%d + %d Seals + %d gear + %d crafting mats\nEstimated run value: ₵%d\n\nExtract and bank it, or descend for more density, elites and loot." % [run_coins, run_seals, run_gear.size(), _crafting_inventory_count(run_crafting), _current_run_value()]
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
	for item in run_gear:
		stash_gear.append(item.duplicate(true))
	_add_feed("Banked ₵%d" % _current_run_value())
	run_coins = 0
	run_seals = 0
	run_gear.clear()
	run_crafting = {"scrap": 0, "mutation": 0, "chaos": 0, "mechanist": 0}
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
	decision_body.text = "The unsecured haul was lost.\n\nLost: ₵%d + %d Seals + %d gear + %d crafting mats\nReached depth %d after %d kills." % [run_coins, run_seals, run_gear.size(), _crafting_inventory_count(run_crafting), depth, total_run_kills]
	run_coins = 0
	run_seals = 0
	run_gear.clear()
	run_crafting = {"scrap": 0, "mutation": 0, "chaos": 0, "mechanist": 0}
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
	var value: int = run_coins + run_seals * 100 + _crafting_inventory_value(run_crafting)
	for item in run_gear:
		value += int(item.get("value", 0))
	return value

func _calculate_net_worth() -> int:
	var value: int = stash_coins + stash_seals * 100 + _crafting_inventory_value(stash_crafting)
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
		"weapon_type": "repeater",
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
		"move_speed_mult": 1.0
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
			stats["weapon_type"] = String(item.get("weapon_type", "repeater"))
		_apply_item_mechanics_to_stats(stats, item)

	stats["max_hp"] = float(stats["max_hp"]) * float(stats["max_hp_mult"])
	stats["move_speed"] = float(stats["move_speed"]) * float(stats["move_speed_mult"])
	return stats

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
		"weapon_type": String(base.get("weapon_type", "")),
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
		var rolled_mechanic: Dictionary = _roll_mechanic(slot, used_mechanics, prefer_high)
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
				{"name":"Scrap Repeater", "weapon_type":"repeater", "implicit_stat":"damage", "implicit_value":2.5},
				{"name":"Sawed Scattergun", "weapon_type":"scattergun", "implicit_stat":"damage", "implicit_value":4.0},
				{"name":"Heavy Piercer", "weapon_type":"piercer", "implicit_stat":"damage", "implicit_value":6.0},
				{"name":"Bullet Hose", "weapon_type":"sprayer", "implicit_stat":"attack_speed", "implicit_value":0.35}
			]
		"armor":
			bases = [
				{"name":"Padded Rags", "weapon_type":"", "implicit_stat":"max_hp", "implicit_value":14.0},
				{"name":"Runner Jacket", "weapon_type":"", "implicit_stat":"move_speed", "implicit_value":12.0},
				{"name":"Reinforced Vest", "weapon_type":"", "implicit_stat":"max_hp", "implicit_value":24.0},
				{"name":"Scavenger Coat", "weapon_type":"", "implicit_stat":"item_find", "implicit_value":5.0}
			]
		_:
			bases = [
				{"name":"Bent Lucky Coin", "weapon_type":"", "implicit_stat":"currency_find", "implicit_value":4.0},
				{"name":"Finder's Eye", "weapon_type":"", "implicit_stat":"item_find", "implicit_value":4.0},
				{"name":"Rat Fang", "weapon_type":"", "implicit_stat":"damage", "implicit_value":2.5},
				{"name":"Runner Token", "weapon_type":"", "implicit_stat":"move_speed", "implicit_value":8.0}
			]
	return bases[rng.randi_range(0, bases.size() - 1)].duplicate(true)

func _affix_candidates(slot: String) -> Array[String]:
	match slot:
		"weapon":
			return ["damage", "attack_speed", "currency_find", "item_find"]
		"armor":
			return ["max_hp", "move_speed", "currency_find", "item_find"]
		_:
			return ["damage", "max_hp", "move_speed", "currency_find", "item_find"]

func _mechanic_pool(slot: String) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	match slot:
		"weapon":
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

func _roll_mechanic(slot: String, used_ids: Array[String], prefer_high: bool = false) -> Dictionary:
	var eligible: Array[Dictionary] = []
	var preferred: Array[Dictionary] = []
	for mechanic: Dictionary in _mechanic_pool(slot):
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
	var text: String = "[color=%s][b]%s[/b][/color]  [color=#f6d05f]~₵%d[/color]" % [color_hex, name_value, value]

	if compact:
		return text + "\n[color=#737c8d]%s  •  ilvl %d[/color]" % [base_name, item_level]

	text += "\n[color=#737c8d]%s  •  %s  •  ilvl %d[/color]" % [rarity, base_name, item_level]
	if String(item.get("slot", "")) == "weapon":
		text += "\n[color=#8d96a6]Weapon: %s[/color]" % String(item.get("weapon_type", "repeater")).capitalize()

	var implicit_variant: Variant = item.get("implicit", {})
	if typeof(implicit_variant) == TYPE_DICTIONARY:
		var implicit: Dictionary = implicit_variant as Dictionary
		if not implicit.is_empty():
			var implicit_stat: String = String(implicit.get("stat", ""))
			var implicit_value: float = float(implicit.get("value", 0.0))
			text += "\n[color=#d4bd70]Implicit  %s[/color]" % _format_stat_value(implicit_stat, implicit_value)

	var mechanics_variant: Variant = item.get("mechanics", [])
	if typeof(mechanics_variant) == TYPE_ARRAY:
		for mechanic_variant: Variant in mechanics_variant as Array:
			if typeof(mechanic_variant) != TYPE_DICTIONARY:
				continue
			var mechanic: Dictionary = mechanic_variant as Dictionary
			text += "\n[color=#ffb45d][b]◆ %s[/b][/color]" % String(mechanic.get("name", "Mechanic"))
			text += "\n[color=#aeb6c4]%s[/color]" % String(mechanic.get("description", ""))

	var affixes_variant: Variant = item.get("affixes", [])
	if typeof(affixes_variant) == TYPE_ARRAY:
		var affix_array: Array = affixes_variant as Array
		for affix_variant: Variant in affix_array:
			if typeof(affix_variant) != TYPE_DICTIONARY:
				continue
			var affix: Dictionary = affix_variant as Dictionary
			var affix_stat: String = String(affix.get("stat", ""))
			var affix_value: float = float(affix.get("value", 0.0))
			var tier: int = int(affix.get("tier", 5))
			text += "\n[color=#6f7888][T%d][/color] %s" % [tier, _format_stat_value(affix_stat, affix_value)]

	return text

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
	if not item.has("weapon_type"):
		item["weapon_type"] = "repeater" if String(item.get("slot", "")) == "weapon" else ""
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
				"id":next_item_id, "slot":"weapon", "rarity":"Common", "name":"Rusty Repeater",
				"base_name":"Scrap Repeater", "weapon_type":"repeater", "depth":0, "item_level":1,
				"damage":3.0, "attack_speed":0.0, "max_hp":0.0, "move_speed":0.0,
				"currency_find":0.0, "item_find":0.0,
				"implicit":{"stat":"damage", "value":3.0, "label":"Damage"}, "affixes":[], "mechanics":[]
			}
		"armor":
			item = {
				"id":next_item_id, "slot":"armor", "rarity":"Common", "name":"Padded Rags",
				"base_name":"Padded Rags", "weapon_type":"", "depth":0, "item_level":1,
				"damage":0.0, "attack_speed":0.0, "max_hp":12.0, "move_speed":0.0,
				"currency_find":0.0, "item_find":0.0,
				"implicit":{"stat":"max_hp", "value":12.0, "label":"Max HP"}, "affixes":[], "mechanics":[]
			}
		_:
			item = {
				"id":next_item_id, "slot":"charm", "rarity":"Common", "name":"Bent Lucky Coin",
				"base_name":"Bent Lucky Coin", "weapon_type":"", "depth":0, "item_level":1,
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

	claim_label.text = "[color=#8d96a6]NEXT CLAIM[/color]  [b]TIER %d[/b]\n[b][font_size=20]ABANDONED CLAIM[/font_size][/b]\n[color=#8d96a6]Loot ceiling[/color] [b]%s[/b]   [color=#8d96a6]Affix ceiling[/color] [b]T%d[/b]\n[color=#8d96a6]Best extract[/color] D%d   [color=#8d96a6]%s[/color]\n[color=#8d96a6]Seals[/color] %d   [color=#8d96a6]Invested[/color] %d   [color=%s][b]%s[/b][/color]\n\nDensity [b]+%d%%[/b]  •  Items [b]+%d%%[/b]\nCurrency [b]+%d%%[/b]  •  Elite [b]+%.1f%%[/b]" % [claim_tier, _tier_loot_ceiling(claim_tier), affix_ceiling, best_depth, next_gate, stash_seals, invested, risk_color, risk, juice_density * 20, juice_quantity * 25, juice_currency * 25, float(juice_elite) * 3.5]

	var stats: Dictionary = _calculate_player_stats()
	stats_label.text = "[color=#8d96a6][b]OFFENSE[/b][/color]\nWeapon Base   [b]%s[/b]\nDamage        [b]%.1f[/b]\nAttack Rate   [b]%.2f / sec[/b]\n\n[color=#8d96a6][b]SURVIVAL[/b][/color]\nMax HP        [b]%.0f[/b]\nMove Speed    [b]%.0f[/b]\n\n[color=#8d96a6][b]LOOT[/b][/color]\nCurrency Find [color=#f6d05f][b]%.1f%%[/b][/color]\nItem Find     [color=#8dd7ff][b]%.1f%%[/b][/color]" % [String(stats["weapon_type"]).capitalize(), float(stats["damage"]), float(stats["attack_speed"]), float(stats["max_hp"]), float(stats["move_speed"]), float(stats["currency_find"]), float(stats["item_find"])]

	equipped_label.text = "[color=#8d96a6]WEAPON[/color]\n%s\n\n[color=#8d96a6]ARMOR[/color]\n%s\n\n[color=#8d96a6]CHARM[/color]\n%s" % [_item_to_bbcode(equipped.get("weapon", {}) as Dictionary, true), _item_to_bbcode(equipped.get("armor", {}) as Dictionary, true), _item_to_bbcode(equipped.get("charm", {}) as Dictionary, true)]

	_rebuild_inventory()
	_refresh_selected_item()
	_update_stash_controls()
	_update_claim_unlock_button()
	if crafting_panel != null and crafting_panel.visible:
		_refresh_crafting_panel()
	_update_top_bar()

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

	stash_count_label.text = "%d shown  •  %d total" % [filtered_items.size(), stash_gear.size()]

	if filtered_items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items in this category."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", Color(0.48, 0.52, 0.60))
		inventory_list.add_child(empty_label)
		return

	for item: Dictionary in filtered_items:
		var item_id: int = int(item.get("id", -1))
		var rarity: String = String(item.get("rarity", "Common"))
		var slot: String = String(item.get("slot", "gear")).to_upper()
		var name_value: String = String(item.get("name", "Item"))
		var prefix: String = "▶ " if item_id == selected_stash_item_id else ""
		var button := Button.new()
		button.custom_minimum_size = Vector2(276.0, 62.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s%s  •  %s\n   ~₵%d   %s" % [prefix, slot, rarity, int(item.get("value", 0)), name_value]
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", _rarity_color(rarity))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.pressed.connect(_select_stash_item.bind(item_id))
		inventory_list.add_child(button)

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
			(button_variant as Button).disabled = key == stash_filter
	if sort_button != null:
		match stash_sort_mode:
			"rarity": sort_button.text = "SORT: RARITY"
			"newest": sort_button.text = "SORT: NEWEST"
			_: sort_button.text = "SORT: VALUE"

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
		selected_item_label.text = "[color=#737c8d]Select an item from the stash to inspect it and compare it against your equipped gear.[/color]"
		selected_equip_button.disabled = true
		selected_sell_button.disabled = true
		if selected_craft_button != null:
			selected_craft_button.disabled = true
		return

	var item: Dictionary = stash_gear[index]
	var slot: String = String(item.get("slot", "charm"))
	var current: Dictionary = equipped.get(slot, {}) as Dictionary
	var current_name: String = String(current.get("name", "Empty"))
	selected_item_label.text = "[color=#8d96a6]SELECTED[/color]\n%s\n\n[color=#8d96a6]CURRENT %s[/color]\n%s\n\n[color=#8d96a6]STAT CHANGE[/color]\n%s" % [_item_to_bbcode(item), slot.to_upper(), current_name, _comparison_bbcode(item, current)]
	selected_equip_button.disabled = false
	selected_sell_button.disabled = false
	if selected_craft_button != null:
		selected_craft_button.disabled = false
	if crafting_panel != null and crafting_panel.visible:
		_refresh_crafting_panel()

func _comparison_bbcode(candidate: Dictionary, current: Dictionary) -> String:
	var lines: Array[String] = []
	if String(candidate.get("slot", "")) == "weapon":
		var new_base: String = String(candidate.get("weapon_type", "repeater")).capitalize()
		var old_base: String = String(current.get("weapon_type", "repeater")).capitalize()
		if new_base != old_base:
			lines.append("[color=#c8ced8]Base: %s → %s[/color]" % [old_base, new_base])

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
	crafting_currency_label.text = "[color=#8d96a6]MATERIALS[/color]  [color=#d5d9e2]Scrap %d[/color]   [color=#76dc96]Mutation %d[/color]   [color=#d878ff]Chaos %d[/color]   [color=#ffb85c]Mechanist %d[/color]" % [int(stash_crafting.get("scrap", 0)), int(stash_crafting.get("mutation", 0)), int(stash_crafting.get("chaos", 0)), int(stash_crafting.get("mechanist", 0))]

	var index: int = _find_stash_item_index(selected_stash_item_id)
	if index < 0:
		crafting_item_label.text = "[color=#737c8d]No stash item selected.[/color]"
		for button_variant: Variant in crafting_buttons.values():
			if button_variant is Button:
				(button_variant as Button).disabled = true
		return

	var item: Dictionary = stash_gear[index]
	crafting_item_label.text = "[color=#8d96a6]WORKING ITEM[/color]\n%s" % _item_to_bbcode(item)
	var rarity: String = String(item.get("rarity", "Common"))
	var affix_count: int = _item_affix_count(item)
	var mechanic_count: int = _item_mechanic_count(item)

	_set_craft_button_state("scrap", int(stash_crafting.get("scrap", 0)) > 0 and affix_count > 0)
	_set_craft_button_state("mutation", int(stash_crafting.get("mutation", 0)) > 0 and rarity == "Common")
	_set_craft_button_state("chaos", claim_tier >= 2 and int(stash_crafting.get("chaos", 0)) > 0 and rarity != "Common" and affix_count > 0)
	_set_craft_button_state("mechanist", claim_tier >= 3 and int(stash_crafting.get("mechanist", 0)) > 0 and mechanic_count > 0)

	var chaos_button_variant: Variant = crafting_buttons.get("chaos")
	if chaos_button_variant is Button:
		(chaos_button_variant as Button).text = "CHAOS TOKEN  •  REROLL NORMAL AFFIXES" if claim_tier >= 2 else "CHAOS TOKEN  •  UNLOCKS AT CLAIM T2"
	var mechanic_button_variant: Variant = crafting_buttons.get("mechanist")
	if mechanic_button_variant is Button:
		(mechanic_button_variant as Button).text = "MECHANIST'S SEAL  •  REROLL MECHANIC" if claim_tier >= 3 else "MECHANIST'S SEAL  •  UNLOCKS AT CLAIM T3"

func _set_craft_button_state(key: String, enabled: bool) -> void:
	var button_variant: Variant = crafting_buttons.get(key)
	if button_variant is Button:
		(button_variant as Button).disabled = not enabled

func _craft_scrap() -> void:
	var index: int = _find_stash_item_index(selected_stash_item_id)
	if index < 0 or int(stash_crafting.get("scrap", 0)) <= 0:
		return
	var item: Dictionary = stash_gear[index]
	var affixes_variant: Variant = item.get("affixes", [])
	if typeof(affixes_variant) != TYPE_ARRAY or (affixes_variant as Array).is_empty():
		return

	var rerolled: Array[Dictionary] = []
	for affix_variant: Variant in affixes_variant as Array:
		if typeof(affix_variant) != TYPE_DICTIONARY:
			continue
		var affix: Dictionary = affix_variant as Dictionary
		var stat: String = String(affix.get("stat", "damage"))
		var tier: int = int(affix.get("tier", 5))
		var value: float = _roll_affix_value(stat, tier)
		rerolled.append(_make_affix_record(stat, tier, value))
	item["affixes"] = rerolled
	_rebuild_item_stats(item)
	_finalize_crafted_item(item)
	stash_gear[index] = item
	_spend_crafting_currency("scrap")
	crafting_feedback_label.text = "SCRAP SLAMMED — values rerolled. Better? Worse? That's the game."
	_after_craft()

func _craft_mutation() -> void:
	var index: int = _find_stash_item_index(selected_stash_item_id)
	if index < 0 or int(stash_crafting.get("mutation", 0)) <= 0:
		return
	var item: Dictionary = stash_gear[index]
	if String(item.get("rarity", "Common")) != "Common":
		return

	item["rarity"] = "Magic"
	var mechanics: Array[Dictionary] = []
	var mechanic: Dictionary = _roll_mechanic(String(item.get("slot", "charm")), [])
	if not mechanic.is_empty():
		mechanics.append(mechanic)
	item["mechanics"] = mechanics

	var candidates: Array[String] = _affix_candidates(String(item.get("slot", "charm")))
	var stat: String = candidates[rng.randi_range(0, candidates.size() - 1)]
	var tier: int = _roll_affix_tier(maxi(1, int(item.get("depth", 1))))
	var value: float = _roll_affix_value(stat, tier)
	item["affixes"] = [_make_affix_record(stat, tier, value)]
	_rebuild_item_stats(item)
	_finalize_crafted_item(item)
	stash_gear[index] = item
	_spend_crafting_currency("mutation")
	crafting_feedback_label.text = "MUTATED — the clean base is now Magic. This is where projects begin."
	_after_craft()

func _craft_chaos() -> void:
	var index: int = _find_stash_item_index(selected_stash_item_id)
	if index < 0 or claim_tier < 2 or int(stash_crafting.get("chaos", 0)) <= 0:
		return
	var item: Dictionary = stash_gear[index]
	var affix_count: int = _item_affix_count(item)
	if affix_count <= 0 or String(item.get("rarity", "Common")) == "Common":
		return

	var candidates: Array[String] = _affix_candidates(String(item.get("slot", "charm")))
	var used_stats: Array[String] = []
	var new_affixes: Array[Dictionary] = []
	while new_affixes.size() < affix_count:
		var available: Array[String] = []
		for candidate: String in candidates:
			if not used_stats.has(candidate):
				available.append(candidate)
		if available.is_empty():
			break
		var stat: String = available[rng.randi_range(0, available.size() - 1)]
		var tier: int = _roll_affix_tier(maxi(1, int(item.get("depth", 1))))
		var value: float = _roll_affix_value(stat, tier)
		new_affixes.append(_make_affix_record(stat, tier, value))
		used_stats.append(stat)
	item["affixes"] = new_affixes
	_rebuild_item_stats(item)
	_finalize_crafted_item(item)
	stash_gear[index] = item
	_spend_crafting_currency("chaos")
	crafting_feedback_label.text = "CHAOS SLAMMED — base and mechanic survived. The normal affixes did not."
	_after_craft()

func _craft_mechanist() -> void:
	var index: int = _find_stash_item_index(selected_stash_item_id)
	if index < 0 or claim_tier < 3 or int(stash_crafting.get("mechanist", 0)) <= 0:
		return
	var item: Dictionary = stash_gear[index]
	var mechanics_variant: Variant = item.get("mechanics", [])
	if typeof(mechanics_variant) != TYPE_ARRAY:
		return
	var mechanics: Array = (mechanics_variant as Array).duplicate(true)
	if mechanics.is_empty():
		return

	var target_index: int = rng.randi_range(0, mechanics.size() - 1)
	var used_ids: Array[String] = []
	for i in range(mechanics.size()):
		if i == target_index or typeof(mechanics[i]) != TYPE_DICTIONARY:
			continue
		used_ids.append(String((mechanics[i] as Dictionary).get("id", "")))
	var replacement: Dictionary = _roll_mechanic(String(item.get("slot", "charm")), used_ids, true)
	if replacement.is_empty():
		return
	mechanics[target_index] = replacement
	item["mechanics"] = mechanics
	_finalize_crafted_item(item)
	stash_gear[index] = item
	_spend_crafting_currency("mechanist")
	crafting_feedback_label.text = "MECHANIST SLAMMED — the item's identity changed. Pray it changed for the better."
	_after_craft()

func _after_craft() -> void:
	_update_hub_ui()
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
		"scrap": return "Scrap Orb"
		"mutation": return "Mutation Shard"
		"chaos": return "Chaos Token"
		"mechanist": return "Mechanist's Seal"
		_: return key.capitalize()

func _crafting_inventory_value(inventory: Dictionary) -> int:
	return int(inventory.get("scrap", 0)) * 60 + int(inventory.get("mutation", 0)) * 180 + int(inventory.get("chaos", 0)) * 600 + int(inventory.get("mechanist", 0)) * 1800

func _crafting_inventory_count(inventory: Dictionary) -> int:
	return int(inventory.get("scrap", 0)) + int(inventory.get("mutation", 0)) + int(inventory.get("chaos", 0)) + int(inventory.get("mechanist", 0))

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

func _save_game() -> void:
	var data: Dictionary = {
		"coins": stash_coins,
		"seals": stash_seals,
		"gear": stash_gear,
		"crafting": stash_crafting,
		"equipped": equipped,
		"next_item_id": next_item_id,
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
	var crafting_variant: Variant = data.get("crafting", {})
	if typeof(crafting_variant) == TYPE_DICTIONARY:
		var loaded_crafting: Dictionary = crafting_variant as Dictionary
		var crafting_keys: Array[String] = ["scrap", "mutation", "chaos", "mechanist"]
		for currency_key: String in crafting_keys:
			stash_crafting[currency_key] = maxi(0, int(loaded_crafting.get(currency_key, 0)))
	next_item_id = int(data.get("next_item_id", 1))
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
	stash_crafting = {"scrap": 0, "mutation": 0, "chaos": 0, "mechanist": 0}
	equipped = {"weapon": {}, "armor": {}, "charm": {}}
	next_item_id = 1
	selected_stash_item_id = -1
	stash_filter = "all"
	stash_sort_mode = "value"
	claim_tier = 1
	tier_best_depths = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
	_ensure_starter_gear()
	_update_hub_ui()
	_save_game()
