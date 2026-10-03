class_name LootProjectile
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 760.0
var damage: float = 18.0
var life: float = 1.25

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
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
	if body is LootEnemy:
		var enemy := body as LootEnemy
		enemy.take_damage(damage)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.86, 0.2))
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
