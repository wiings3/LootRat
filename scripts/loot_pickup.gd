class_name LootPickup
extends Area2D

signal collected(pickup: LootPickup)

var loot_type: String = "coin"
var amount: int = 1
var gear: Dictionary = {}
var velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _collected: bool = false
var player: LootPlayer = null

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0 if loot_type == "jackpot" else 9.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_build_ground_label()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_age += delta
	velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	global_position += velocity * delta
	if loot_type == "seal" or loot_type == "craft" or loot_type == "core":
		rotation += delta * 1.8
	elif loot_type == "gear" or loot_type == "jackpot":
		var pulse: float = 1.0 + sin(_age * 5.0) * 0.045
		scale = Vector2.ONE * pulse
	if _age > 0.35 and is_instance_valid(player):
		var magnet_radius: float = maxf(45.0, player.pickup_radius)
		var dist: float = global_position.distance_to(player.global_position)
		if dist < magnet_radius:
			var pull: float = remap(clampf(dist, 18.0, magnet_radius), 18.0, magnet_radius, 1050.0, 260.0)
			global_position = global_position.move_toward(player.global_position, pull * delta)

func _build_ground_label() -> void:
	if loot_type == "coin":
		return
	var label := Label.new()
	label.z_index = 5
	label.position = Vector2(-62.0, -35.0)
	label.size = Vector2(124.0, 24.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	match loot_type:
		"seal":
			label.text = "SEAL"
			label.add_theme_color_override("font_color", Color(0.35, 0.88, 1.0))
		"jackpot":
			label.text = "JACKPOT  ₵%d" % amount
			label.add_theme_font_size_override("font_size", 18)
			label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.18))
		"craft":
			var currency_key: String = String(gear.get("currency", "scrap"))
			match currency_key:
				"mutation":
					label.text = "MUTATION SHARD"
					label.add_theme_color_override("font_color", Color(0.46, 0.90, 0.58))
				"splice":
					label.text = "SPLICE SHARD"
					label.add_theme_color_override("font_color", Color(0.38, 0.80, 0.92))
				"crown":
					label.text = "CROWN TOKEN"
					label.add_theme_color_override("font_color", Color(0.96, 0.76, 0.32))
				"hoarder":
					label.text = "HOARDER'S ORB"
					label.add_theme_color_override("font_color", Color(0.98, 0.55, 0.22))
				"chaos":
					label.text = "CHAOS TOKEN"
					label.add_theme_color_override("font_color", Color(0.82, 0.42, 1.0))
				"polish":
					label.text = "POLISH ORB"
					label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.72))
				"mechanist":
					label.text = "MECHANIST'S SEAL"
					label.add_theme_color_override("font_color", Color(1.0, 0.60, 0.20))
				_:
					label.text = "SCRAP ORB"
					label.add_theme_color_override("font_color", Color(0.80, 0.84, 0.90))
		"core":
			var core_id: String = String(gear.get("core", "repeater"))
			label.text = "%s CORE" % core_id.to_upper()
			label.add_theme_font_size_override("font_size", 16)
			label.add_theme_color_override("font_color", Color(0.38, 0.84, 1.0))
		"gear":
			label.text = "%s  ~₵%d" % [String(gear.get("name", "Gear")), int(gear.get("value", 0))]
			var rarity: String = String(gear.get("rarity", "Common"))
			var text_color := Color(0.82, 0.84, 0.88)
			if rarity == "Magic":
				text_color = Color(0.39, 0.66, 1.0)
			elif rarity == "Rare":
				text_color = Color(0.85, 0.42, 1.0)
			elif rarity == "Gilded":
				text_color = Color(1.0, 0.82, 0.20)
				label.add_theme_font_size_override("font_size", 17)
			label.add_theme_color_override("font_color", text_color)
	add_child(label)

func collect_now() -> void:
	_collect()

func _on_body_entered(body: Node) -> void:
	if body is LootPlayer:
		_collect()

func _collect() -> void:
	if _collected:
		return
	_collected = true
	collected.emit(self)
	queue_free()

func _draw() -> void:
	match loot_type:
		"coin":
			draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.78, 0.08))
			draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.95, 0.48))
		"seal":
			draw_colored_polygon(PackedVector2Array([Vector2(0,-10), Vector2(9,0), Vector2(0,10), Vector2(-9,0)]), Color(0.25, 0.85, 1.0))
		"craft":
			var currency_key: String = String(gear.get("currency", "scrap"))
			var craft_color := Color(0.80, 0.84, 0.90)
			if currency_key == "mutation":
				craft_color = Color(0.38, 0.92, 0.55)
			elif currency_key == "splice":
				craft_color = Color(0.30, 0.76, 0.92)
			elif currency_key == "crown":
				craft_color = Color(0.96, 0.72, 0.22)
			elif currency_key == "hoarder":
				craft_color = Color(0.98, 0.46, 0.16)
			elif currency_key == "chaos":
				craft_color = Color(0.78, 0.34, 1.0)
			elif currency_key == "polish":
				craft_color = Color(0.88, 0.86, 0.66)
			elif currency_key == "mechanist":
				craft_color = Color(1.0, 0.52, 0.12)
			draw_circle(Vector2.ZERO, 12.0, Color(craft_color.r, craft_color.g, craft_color.b, 0.18))
			draw_colored_polygon(PackedVector2Array([Vector2(0,-10), Vector2(8,-5), Vector2(9,5), Vector2(0,10), Vector2(-9,5), Vector2(-8,-5)]), craft_color)
			draw_circle(Vector2.ZERO, 3.0, Color(0.10, 0.11, 0.14))
		"core":
			var core_color := Color(0.28, 0.78, 1.0)
			draw_circle(Vector2.ZERO, 15.0, Color(core_color.r, core_color.g, core_color.b, 0.16))
			draw_circle(Vector2.ZERO, 10.0, core_color, false, 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0,-8), Vector2(7,0), Vector2(0,8), Vector2(-7,0)]), core_color)
			draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
		"gear":
			var rarity: String = String(gear.get("rarity", "Common"))
			var gear_color := Color(0.82, 0.84, 0.88)
			if rarity == "Magic":
				gear_color = Color(0.39, 0.66, 1.0)
			elif rarity == "Rare":
				gear_color = Color(0.85, 0.32, 1.0)
			elif rarity == "Gilded":
				gear_color = Color(1.0, 0.75, 0.10)
			draw_circle(Vector2.ZERO, 15.0 if rarity != "Gilded" else 20.0, Color(gear_color.r, gear_color.g, gear_color.b, 0.16))
			draw_colored_polygon(PackedVector2Array([Vector2(0,-11), Vector2(10,-3), Vector2(6,10), Vector2(-6,10), Vector2(-10,-3)]), gear_color)
		"jackpot":
			draw_circle(Vector2.ZERO, 22.0, Color(1.0, 0.75, 0.10, 0.16))
			draw_colored_polygon(PackedVector2Array([Vector2(0,-14), Vector2(13,0), Vector2(0,14), Vector2(-13,0)]), Color(1.0, 0.72, 0.08))
			draw_circle(Vector2.ZERO, 5.0, Color.WHITE)
