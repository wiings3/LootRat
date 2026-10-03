extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 340.0
var damage: float = 8.0
var life: float = 2.4
var radius: float = 6.0
var is_elite: bool = false
var _hit: bool = false

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	monitoring = true
	monitorable = false
	rotation = direction.angle()
	z_index = 8

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
	if _hit:
		return
	if body is LootPlayer:
		_hit = true
		(body as LootPlayer).take_damage(damage)
		queue_free()

func _draw() -> void:
	var glow_color := Color(1.0, 0.42, 0.12, 0.22) if is_elite else Color(0.20, 0.82, 1.0, 0.20)
	var core_color := Color(1.0, 0.48, 0.14) if is_elite else Color(0.30, 0.88, 1.0)

	# Large translucent glow makes the shot readable even against busy loot.
	draw_circle(Vector2.ZERO, radius + 7.0, glow_color)
	# Short tail and bright core make its travel direction obvious.
	draw_line(Vector2(-18.0, 0.0), Vector2(-4.0, 0.0), core_color, maxf(3.0, radius * 0.65))
	draw_circle(Vector2.ZERO, radius, core_color)
	draw_circle(Vector2(2.0, -1.0), maxf(2.0, radius * 0.42), Color.WHITE)
