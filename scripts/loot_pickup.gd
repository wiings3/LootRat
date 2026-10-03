class_name LootPickup
extends Area2D

signal collected(pickup: LootPickup)

var loot_type: String = "coin"
var amount: int = 1
var gear: Dictionary = {}
var velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var player: LootPlayer = null

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_age += delta
	velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	global_position += velocity * delta
	if _age > 0.35 and is_instance_valid(player):
		var dist: float = global_position.distance_to(player.global_position)
		if dist < 135.0:
			var pull: float = remap(clampf(dist, 18.0, 135.0), 18.0, 135.0, 950.0, 260.0)
			global_position = global_position.move_toward(player.global_position, pull * delta)

func _on_body_entered(body: Node) -> void:
	if body is LootPlayer:
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
			draw_colored_polygon(PackedVector2Array([Vector2(0,-11), Vector2(10,-3), Vector2(6,10), Vector2(-6,10), Vector2(-10,-3)]), Color(0.85, 0.32, 1.0))
