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
	if loot_type == "seal":
		rotation += delta * 1.8
	elif loot_type == "gear" or loot_type == "jackpot":
		var pulse: float = 1.0 + sin(_age * 5.0) * 0.045
		scale = Vector2.ONE * pulse
	if _age > 0.35 and is_instance_valid(player):
		var dist: float = global_position.distance_to(player.global_position)
		if dist < 145.0:
			var pull: float = remap(clampf(dist, 18.0, 145.0), 18.0, 145.0, 1050.0, 260.0)
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
