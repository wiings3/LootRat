extends Node2D

const SAVE_PATH: String = "user://loot_rat_save.json"
const ARENA_BOUNDS: Rect2 = Rect2(40.0, 80.0, 1200.0, 590.0)

var rng := RandomNumberGenerator.new()

var arena: LootArena = null
var actor_layer: Node2D = null
var projectile_layer: Node2D = null
var loot_layer: Node2D = null
var player: LootPlayer = null

var hud: CanvasLayer = null
var top_label: Label = null
var run_label: Label = null
var feed_label: Label = null
var hp_bar: ProgressBar = null
var hub_panel: PanelContainer = null
var gear_panel: PanelContainer = null
var decision_panel: PanelContainer = null
var decision_title: Label = null
var decision_body: Label = null
var inventory_list: VBoxContainer = null
var equipped_label: RichTextLabel = null
var claim_label: RichTextLabel = null
var stats_label: RichTextLabel = null

var state: String = "hub"
var depth: int = 1
var alive_enemies: int = 0
var floor_kills: int = 0
var total_run_kills: int = 0
var decision_open: bool = false

var stash_coins: int = 0
var stash_seals: int = 5
var stash_gear: Array[Dictionary] = []
var equipped: Dictionary = {"weapon": {}, "armor": {}, "charm": {}}
var next_item_id: int = 1

var run_coins: int = 0
var run_seals: int = 0
var run_gear: Array[Dictionary] = []

var juice_density: int = 0
var juice_quantity: int = 0
var juice_currency: int = 0
var juice_elite: int = 0

var feed_lines: Array[String] = []

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
	top_bg.color = Color(0.025, 0.03, 0.045, 0.96)
	top_bg.position = Vector2.ZERO
	top_bg.size = Vector2(1280.0, 62.0)
	hud.add_child(top_bg)

	top_label = Label.new()
	top_label.position = Vector2(20.0, 14.0)
	top_label.add_theme_font_size_override("font_size", 22)
	hud.add_child(top_label)

	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(430.0, 16.0)
	hp_bar.size = Vector2(260.0, 26.0)
	hp_bar.min_value = 0.0
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.show_percentage = true
	hud.add_child(hp_bar)

	run_label = Label.new()
	run_label.position = Vector2(715.0, 14.0)
	run_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(run_label)

	feed_label = Label.new()
	feed_label.position = Vector2(935.0, 84.0)
	feed_label.size = Vector2(325.0, 180.0)
	feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	feed_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(feed_label)

	_build_hub_panel()
	_build_gear_panel()
	_build_decision_panel()

	var controls := Label.new()
	controls.text = "WASD move   •   Hold LMB fire   •   SPACE dash"
	controls.position = Vector2(20.0, 682.0)
	controls.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	hud.add_child(controls)

func _build_hub_panel() -> void:
	hub_panel = PanelContainer.new()
	hub_panel.position = Vector2(50.0, 92.0)
	hub_panel.size = Vector2(555.0, 550.0)
	hud.add_child(hub_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	hub_panel.add_child(root)

	var title := Label.new()
	title.text = "CLAIM TABLE"
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)

	var intro := Label.new()
	intro.text = "Spend Seals to juice the next Claim. More danger = more loot."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	claim_label = RichTextLabel.new()
	claim_label.bbcode_enabled = true
	claim_label.fit_content = true
	claim_label.custom_minimum_size = Vector2(500.0, 160.0)
	root.add_child(claim_label)

	var juice_grid := GridContainer.new()
	juice_grid.columns = 2
	juice_grid.add_theme_constant_override("h_separation", 8)
	juice_grid.add_theme_constant_override("v_separation", 8)
	root.add_child(juice_grid)

	juice_grid.add_child(_make_button("+ Density  [1 Seal]", _juice_density))
	juice_grid.add_child(_make_button("+ Quantity  [1 Seal]", _juice_quantity))
	juice_grid.add_child(_make_button("+ Currency  [1 Seal]", _juice_currency))
	juice_grid.add_child(_make_button("+ Elite Chance [1 Seal]", _juice_elite))

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	root.add_child(action_row)
	action_row.add_child(_make_button("RUN CLAIM", _start_claim, Vector2(250.0, 52.0)))
	action_row.add_child(_make_button("RESET JUICE", _reset_juice, Vector2(180.0, 52.0)))

	stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.custom_minimum_size = Vector2(500.0, 100.0)
	root.add_child(stats_label)

func _build_gear_panel() -> void:
	gear_panel = PanelContainer.new()
	gear_panel.position = Vector2(625.0, 92.0)
	gear_panel.size = Vector2(605.0, 550.0)
	hud.add_child(gear_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	gear_panel.add_child(root)

	var title := Label.new()
	title.text = "STASH / GEAR"
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)

	equipped_label = RichTextLabel.new()
	equipped_label.bbcode_enabled = true
	equipped_label.fit_content = true
	equipped_label.custom_minimum_size = Vector2(550.0, 125.0)
	root.add_child(equipped_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)
	row.add_child(_make_button("SELL ALL UNEQUIPPED", _sell_all_gear, Vector2(230.0, 38.0)))
	row.add_child(_make_button("WIPE SAVE", _wipe_save, Vector2(130.0, 38.0)))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(550.0, 320.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 6)
	scroll.add_child(inventory_list)

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

func _process(_delta: float) -> void:
	_update_top_bar()
	if state == "run" and alive_enemies <= 0 and not decision_open and is_instance_valid(player):
		_open_floor_clear()

func _enter_hub() -> void:
	state = "hub"
	decision_open = false
	decision_panel.visible = false
	arena.visible = false
	hub_panel.visible = true
	gear_panel.visible = true
	hp_bar.visible = false
	run_label.visible = false
	feed_label.visible = false
	_clear_runtime_nodes()
	_update_hub_ui()
	_save_game()

func _start_claim() -> void:
	state = "run"
	depth = 1
	run_coins = 0
	run_seals = 0
	run_gear.clear()
	total_run_kills = 0
	feed_lines.clear()
	hub_panel.visible = false
	gear_panel.visible = false
	hp_bar.visible = true
	run_label.visible = true
	feed_label.visible = true
	arena.visible = true
	decision_panel.visible = false
	decision_open = false
	_begin_floor()

func _begin_floor() -> void:
	_clear_runtime_nodes()
	decision_panel.visible = false
	decision_open = false
	floor_kills = 0
	_spawn_player()
	_spawn_floor_enemies()
	_add_feed("Entered depth %d" % depth)

func _spawn_player() -> void:
	player = LootPlayer.new()
	player.global_position = ARENA_BOUNDS.get_center()
	player.world_bounds = ARENA_BOUNDS.grow(-18.0)
	player.projectile_parent = projectile_layer
	player.configure(_calculate_player_stats())
	player.died.connect(_on_player_died)
	player.hp_changed.connect(_on_player_hp_changed)
	actor_layer.add_child(player)
	_on_player_hp_changed(player.hp, player.max_hp)

func _spawn_floor_enemies() -> void:
	var density_mult: float = 1.0 + float(juice_density) * 0.20 + float(depth - 1) * 0.12
	var base_count: int = 12 + depth * 3
	var spawn_count: int = maxi(8, int(round(float(base_count) * density_mult)))
	var elite_chance: float = 0.05 + float(juice_elite) * 0.035 + float(depth - 1) * 0.018
	alive_enemies = spawn_count

	for i in range(spawn_count):
		var enemy := LootEnemy.new()
		var kind: int = rng.randi_range(0, 2)
		var elite: bool = rng.randf() < elite_chance
		enemy.configure(kind, depth, elite)
		enemy.target = player
		enemy.global_position = _random_spawn_position()
		enemy.killed.connect(_on_enemy_killed)
		actor_layer.add_child(enemy)

func _random_spawn_position() -> Vector2:
	var pos := Vector2.ZERO
	for _attempt in range(12):
		pos = Vector2(
			rng.randf_range(ARENA_BOUNDS.position.x + 30.0, ARENA_BOUNDS.end.x - 30.0),
			rng.randf_range(ARENA_BOUNDS.position.y + 30.0, ARENA_BOUNDS.end.y - 30.0)
		)
		if pos.distance_to(ARENA_BOUNDS.get_center()) > 210.0:
			break
	return pos

func _on_enemy_killed(enemy: LootEnemy) -> void:
	alive_enemies = maxi(0, alive_enemies - 1)
	floor_kills += 1
	total_run_kills += 1
	_spawn_loot_burst(enemy.global_position, enemy.reward_scale, enemy.is_elite)

func _spawn_loot_burst(position_value: Vector2, reward_scale: float, elite: bool) -> void:
	if not is_instance_valid(player):
		return
	var currency_mult: float = _run_currency_multiplier() * (1.0 + player.currency_find / 100.0)
	var quantity_mult: float = _run_quantity_multiplier() * (1.0 + player.item_find / 100.0)
	var coin_piles: int = maxi(2, int(round(rng.randf_range(2.0, 4.0) * quantity_mult * sqrt(reward_scale))))

	for _i in range(coin_piles):
		var amount: int = maxi(1, int(round(rng.randf_range(4.0, 10.0) * currency_mult * reward_scale * (1.0 + float(depth - 1) * 0.22))))
		_spawn_pickup("coin", amount, {}, position_value)

	var seal_chance: float = 0.045 * quantity_mult * (2.5 if elite else 1.0)
	if rng.randf() < seal_chance:
		_spawn_pickup("seal", 1, {}, position_value)

	var gear_chance: float = 0.10 * quantity_mult * reward_scale
	gear_chance = minf(0.68, gear_chance)
	if rng.randf() < gear_chance:
		var gear_item: Dictionary = _generate_gear(depth, elite)
		_spawn_pickup("gear", 1, gear_item, position_value)

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
		"gear":
			run_gear.append(pickup.gear.duplicate(true))
			_add_feed("GEAR: %s  (~₵%d)" % [String(pickup.gear.get("name", "Item")), int(pickup.gear.get("value", 0))])

func _open_floor_clear() -> void:
	decision_open = true
	decision_panel.visible = true
	decision_title.text = "DEPTH %d CLEARED" % depth
	decision_body.text = "Unsecured haul: ₵%d + %d Seals + %d gear\nEstimated run value: ₵%d\n\nExtract and bank it, or descend for more density, elites and loot." % [run_coins, run_seals, run_gear.size(), _current_run_value()]
	_set_decision_buttons(true, true)

func _descend() -> void:
	if state != "run":
		return
	depth += 1
	_begin_floor()

func _extract_run() -> void:
	if state != "run":
		return
	stash_coins += run_coins
	stash_seals += run_seals
	for item in run_gear:
		stash_gear.append(item.duplicate(true))
	_add_feed("Banked ₵%d" % _current_run_value())
	run_coins = 0
	run_seals = 0
	run_gear.clear()
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
	decision_body.text = "The unsecured haul was lost.\n\nLost: ₵%d + %d Seals + %d gear\nReached depth %d after %d kills." % [run_coins, run_seals, run_gear.size(), depth, total_run_kills]
	run_coins = 0
	run_seals = 0
	run_gear.clear()
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
	return 1.0 + float(juice_quantity) * 0.25 + float(depth - 1) * 0.22

func _run_currency_multiplier() -> float:
	return 1.0 + float(juice_currency) * 0.25 + float(depth - 1) * 0.20

func _current_run_value() -> int:
	var value: int = run_coins + run_seals * 100
	for item in run_gear:
		value += int(item.get("value", 0))
	return value

func _calculate_net_worth() -> int:
	var value: int = stash_coins + stash_seals * 100
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
		"item_find": 0.0
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
	return stats

func _generate_gear(item_depth: int, from_elite: bool) -> Dictionary:
	var slot_roll: int = rng.randi_range(0, 2)
	var gear_slots: Array[String] = ["weapon", "armor", "charm"]
	var slot: String = gear_slots[slot_roll]
	var rarity_roll: float = rng.randf() + (0.16 if from_elite else 0.0) + float(item_depth - 1) * 0.012
	var rarity: String = "Common"
	var affixes: int = 1
	if rarity_roll > 0.90:
		rarity = "Rare"
		affixes = 3
	elif rarity_roll > 0.58:
		rarity = "Magic"
		affixes = 2

	var item: Dictionary = {
		"id": next_item_id,
		"slot": slot,
		"rarity": rarity,
		"depth": item_depth,
		"damage": 0.0,
		"attack_speed": 0.0,
		"max_hp": 0.0,
		"move_speed": 0.0,
		"currency_find": 0.0,
		"item_find": 0.0
	}
	next_item_id += 1

	var power: float = 1.0 + float(item_depth - 1) * 0.16
	var used: Array[String] = []
	for _i in range(affixes):
		var candidates: Array[String] = _affix_candidates(slot)
		var available: Array[String] = []
		for candidate in candidates:
			if not used.has(candidate):
				available.append(candidate)
		if available.is_empty():
			break
		var affix: String = available[rng.randi_range(0, available.size() - 1)]
		used.append(affix)
		match affix:
			"damage": item[affix] = snappedf(rng.randf_range(4.0, 10.0) * power, 0.1)
			"attack_speed": item[affix] = snappedf(rng.randf_range(0.25, 0.75) * power, 0.01)
			"max_hp": item[affix] = snappedf(rng.randf_range(12.0, 30.0) * power, 1.0)
			"move_speed": item[affix] = snappedf(rng.randf_range(8.0, 22.0) * power, 1.0)
			"currency_find": item[affix] = snappedf(rng.randf_range(5.0, 14.0) * power, 0.1)
			"item_find": item[affix] = snappedf(rng.randf_range(5.0, 14.0) * power, 0.1)

	item["name"] = _make_item_name(slot, rarity)
	item["value"] = _item_value(item)
	return item

func _affix_candidates(slot: String) -> Array[String]:
	match slot:
		"weapon": return ["damage", "attack_speed", "currency_find", "item_find"]
		"armor": return ["max_hp", "move_speed", "currency_find", "item_find"]
		_: return ["damage", "max_hp", "move_speed", "currency_find", "item_find"]

func _make_item_name(slot: String, rarity: String) -> String:
	var prefixes: Array[String] = ["Greedy", "Filthy", "Lucky", "Gilded", "Rattling", "Stolen", "Crooked", "Shiny"]
	var weapon_names: Array[String] = ["Blaster", "Repeater", "Hand Cannon", "Scrapgun", "Coinspitter"]
	var armor_names: Array[String] = ["Jacket", "Plate", "Vest", "Rags", "Carapace"]
	var charm_names: Array[String] = ["Idol", "Rat Tail", "Token", "Locket", "Trinket"]
	var nouns: Array[String]
	match slot:
		"weapon": nouns = weapon_names
		"armor": nouns = armor_names
		_: nouns = charm_names
	var name_value: String = nouns[rng.randi_range(0, nouns.size() - 1)]
	if rarity == "Common":
		return name_value
	return "%s %s" % [prefixes[rng.randi_range(0, prefixes.size() - 1)], name_value]

func _item_value(item: Dictionary) -> int:
	var score: float = 25.0 + float(item.get("depth", 1)) * 18.0
	score += float(item.get("damage", 0.0)) * 19.0
	score += float(item.get("attack_speed", 0.0)) * 170.0
	score += float(item.get("max_hp", 0.0)) * 4.5
	score += float(item.get("move_speed", 0.0)) * 5.0
	score += float(item.get("currency_find", 0.0)) * 13.0
	score += float(item.get("item_find", 0.0)) * 13.0
	var rarity: String = String(item.get("rarity", "Common"))
	if rarity == "Magic":
		score *= 1.25
	if rarity == "Rare":
		score *= 1.65
	return maxi(20, int(round(score)))

func _item_to_bbcode(item: Dictionary, compact: bool = false) -> String:
	if item.is_empty():
		return "[color=#7f8794]Empty[/color]"
	var rarity: String = String(item.get("rarity", "Common"))
	var color_hex: String = "#cfd4dc"
	if rarity == "Magic": color_hex = "#63a9ff"
	if rarity == "Rare": color_hex = "#d96cff"
	var text: String = "[color=%s][b]%s[/b][/color]  [color=#f6d05f]~₵%d[/color]" % [color_hex, String(item.get("name", "Item")), int(item.get("value", 0))]
	if compact:
		return text
	var stats: Array[String] = []
	if float(item.get("damage", 0.0)) > 0.0: stats.append("+%.1f Damage" % float(item.get("damage", 0.0)))
	if float(item.get("attack_speed", 0.0)) > 0.0: stats.append("+%.2f Attacks/sec" % float(item.get("attack_speed", 0.0)))
	if float(item.get("max_hp", 0.0)) > 0.0: stats.append("+%.0f Max HP" % float(item.get("max_hp", 0.0)))
	if float(item.get("move_speed", 0.0)) > 0.0: stats.append("+%.0f Move Speed" % float(item.get("move_speed", 0.0)))
	if float(item.get("currency_find", 0.0)) > 0.0: stats.append("+%.1f%% Currency Find" % float(item.get("currency_find", 0.0)))
	if float(item.get("item_find", 0.0)) > 0.0: stats.append("+%.1f%% Item Find" % float(item.get("item_find", 0.0)))
	if not stats.is_empty():
		var packed_stats := PackedStringArray(stats)
		text += "\n[color=#b6bdc9]%s[/color]" % "  •  ".join(packed_stats)
	return text

func _update_hub_ui() -> void:
	claim_label.text = "[b]ABANDONED CLAIM[/b]\nMonster Density: [color=#ffd75d]+%d%%[/color]\nItem Quantity: [color=#8dd7ff]+%d%%[/color]\nCurrency Quantity: [color=#ffd75d]+%d%%[/color]\nElite Chance: [color=#ff9b4a]+%.1f%%[/color]" % [juice_density * 20, juice_quantity * 25, juice_currency * 25, 5.0 + float(juice_elite) * 3.5]

	var stats: Dictionary = _calculate_player_stats()
	stats_label.text = "[b]Current build[/b]   Damage %.1f   •   %.2f attacks/s   •   %.0f HP\nMove %.0f   •   Currency Find %.1f%%   •   Item Find %.1f%%" % [float(stats["damage"]), float(stats["attack_speed"]), float(stats["max_hp"]), float(stats["move_speed"]), float(stats["currency_find"]), float(stats["item_find"])]

	equipped_label.text = "[b]EQUIPPED[/b]\nWeapon: %s\nArmor: %s\nCharm: %s" % [_item_to_bbcode(equipped.get("weapon", {}) as Dictionary, true), _item_to_bbcode(equipped.get("armor", {}) as Dictionary, true), _item_to_bbcode(equipped.get("charm", {}) as Dictionary, true)]
	_rebuild_inventory()
	_update_top_bar()

func _rebuild_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	if stash_gear.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No unequipped gear. Go be a loot rat."
		empty_label.add_theme_color_override("font_color", Color(0.55, 0.58, 0.64))
		inventory_list.add_child(empty_label)
		return

	var sorted_items: Array[Dictionary] = stash_gear.duplicate(true)
	sorted_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("value", 0)) > int(b.get("value", 0)))
	for item in sorted_items:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(530.0, 72.0)
		inventory_list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.custom_minimum_size = Vector2(345.0, 66.0)
		text.text = "[color=#8b93a3]%s[/color]  %s" % [String(item.get("slot", "gear")).to_upper(), _item_to_bbcode(item)]
		row.add_child(text)
		var equip_button := Button.new()
		equip_button.text = "EQUIP"
		equip_button.custom_minimum_size = Vector2(80.0, 42.0)
		var item_id: int = int(item.get("id", -1))
		equip_button.pressed.connect(_equip_item.bind(item_id))
		row.add_child(equip_button)
		var sell_button := Button.new()
		sell_button.text = "SELL"
		sell_button.custom_minimum_size = Vector2(72.0, 42.0)
		sell_button.pressed.connect(_sell_item.bind(item_id))
		row.add_child(sell_button)

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
	_update_hub_ui()
	_save_game()

func _sell_item(item_id: int) -> void:
	var index: int = _find_stash_item_index(item_id)
	if index < 0:
		return
	var item: Dictionary = stash_gear[index]
	stash_coins += int(item.get("value", 0))
	stash_gear.remove_at(index)
	_update_hub_ui()
	_save_game()

func _sell_all_gear() -> void:
	var sale: int = 0
	for item in stash_gear:
		sale += int(item.get("value", 0))
	stash_coins += sale
	stash_gear.clear()
	_update_hub_ui()
	_save_game()

func _find_stash_item_index(item_id: int) -> int:
	for i in range(stash_gear.size()):
		if int(stash_gear[i].get("id", -1)) == item_id:
			return i
	return -1

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
	top_label.text = "₵%d    ◈ %d Seals    NET WORTH ₵%d" % [stash_coins, stash_seals, _calculate_net_worth()]
	if state == "run":
		run_label.text = "DEPTH %d   •   ENEMIES %d   •   UNSECURED ₵%d" % [depth, alive_enemies, _current_run_value()]

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
		equipped["weapon"] = {"id": next_item_id, "slot":"weapon", "rarity":"Common", "name":"Rusty Coinspitter", "depth":0, "damage":3.0, "attack_speed":0.0, "max_hp":0.0, "move_speed":0.0, "currency_find":0.0, "item_find":0.0, "value":70}
		next_item_id += 1
	if (equipped.get("armor", {}) as Dictionary).is_empty():
		equipped["armor"] = {"id": next_item_id, "slot":"armor", "rarity":"Common", "name":"Padded Rags", "depth":0, "damage":0.0, "attack_speed":0.0, "max_hp":12.0, "move_speed":0.0, "currency_find":0.0, "item_find":0.0, "value":65}
		next_item_id += 1
	if (equipped.get("charm", {}) as Dictionary).is_empty():
		equipped["charm"] = {"id": next_item_id, "slot":"charm", "rarity":"Common", "name":"Bent Lucky Coin", "depth":0, "damage":0.0, "attack_speed":0.0, "max_hp":0.0, "move_speed":0.0, "currency_find":3.0, "item_find":3.0, "value":85}
		next_item_id += 1

func _save_game() -> void:
	var data: Dictionary = {
		"coins": stash_coins,
		"seals": stash_seals,
		"gear": stash_gear,
		"equipped": equipped,
		"next_item_id": next_item_id
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
	next_item_id = int(data.get("next_item_id", 1))
	var gear_variant: Variant = data.get("gear", [])
	if typeof(gear_variant) == TYPE_ARRAY:
		var loaded_gear: Array = gear_variant as Array
		for entry: Variant in loaded_gear:
			if typeof(entry) == TYPE_DICTIONARY:
				stash_gear.append((entry as Dictionary).duplicate(true))
	var equipped_variant: Variant = data.get("equipped", {})
	if typeof(equipped_variant) == TYPE_DICTIONARY:
		var loaded_equipped: Dictionary = equipped_variant as Dictionary
		var gear_slots: Array[String] = ["weapon", "armor", "charm"]
		for slot_name: String in gear_slots:
			var item_variant: Variant = loaded_equipped.get(slot_name, {})
			if typeof(item_variant) == TYPE_DICTIONARY:
				equipped[slot_name] = (item_variant as Dictionary).duplicate(true)

func _wipe_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	stash_coins = 0
	stash_seals = 5
	stash_gear.clear()
	equipped = {"weapon": {}, "armor": {}, "charm": {}}
	next_item_id = 1
	_ensure_starter_gear()
	_update_hub_ui()
	_save_game()
