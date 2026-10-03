class_name LootProjectile
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 760.0
var damage: float = 18.0
var life: float = 1.25
var pierces: int = 0
var radius: float = 5.0
var knockback_force: float = 110.0
var weapon_type: String = "repeater"
var _hit_ids: Dictionary = {}

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body is LootEnemy:
		return
	var id: int = body.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	var enemy := body as LootEnemy
	enemy.take_damage(damage, direction, knockback_force)
	if pierces > 0:
		pierces -= 1
	else:
		queue_free()

func _draw() -> void:
	var outer := Color(1.0, 0.86, 0.2)
	match weapon_type:
		"scattergun": outer = Color(1.0, 0.52, 0.18)
		"piercer": outer = Color(0.72, 0.38, 1.0)
		"sprayer": outer = Color(0.28, 1.0, 0.55)
	draw_circle(Vector2.ZERO, radius, outer)
	draw_circle(Vector2.ZERO, maxf(1.5, radius * 0.42), Color.WHITE)
