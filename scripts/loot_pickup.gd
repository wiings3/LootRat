class_name LootPickup
extends Area2D

const ItemArt = preload("res://scripts/item_art.gd")

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
	_build_sprite_art()
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

func _build_sprite_art() -> void:
	var texture: Texture2D = null
	match loot_type:
		"coin":
			texture = ItemArt.texture_for_misc("coin")
		"seal":
			texture = ItemArt.texture_for_misc("seal")
		"craft":
			texture = ItemArt.texture_for_currency(String(gear.get("currency", "scrap")))
		"core":
			texture = ItemArt.texture_for_core(String(gear.get("core", "repeater")))
		"gear":
			texture = ItemArt.texture_for_item(gear)
		"jackpot":
			texture = ItemArt.texture_for_misc("coin")
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 2
	var art_scale: float = 2.0
	if loot_type == "gear":
		art_scale = 2.0
	elif loot_type == "jackpot":
		art_scale = 3.0
	sprite.scale = Vector2.ONE * art_scale
	add_child(sprite)

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
	if loot_type == "gear":
		var rarity: String = String(gear.get("rarity", "Common"))
		var glow := Color(0.82, 0.84, 0.88)
		if rarity == "Magic":
			glow = Color(0.39, 0.66, 1.0)
		elif rarity == "Rare":
			glow = Color(0.85, 0.32, 1.0)
		elif rarity == "Gilded":
			glow = Color(1.0, 0.75, 0.10)
		draw_circle(Vector2.ZERO, 16.0 if rarity != "Gilded" else 21.0, Color(glow.r, glow.g, glow.b, 0.14))
	elif loot_type == "jackpot":
		draw_circle(Vector2.ZERO, 23.0, Color(1.0, 0.75, 0.10, 0.15))
	elif loot_type == "craft":
		draw_circle(Vector2.ZERO, 14.0, Color(0.80, 0.68, 0.34, 0.10))
	elif loot_type == "core":
		draw_circle(Vector2.ZERO, 14.0, Color(0.30, 0.78, 1.0, 0.10))
