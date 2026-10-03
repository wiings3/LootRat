class_name LootPlayer
extends CharacterBody2D

signal died
signal hp_changed(current_hp: float, max_hp: float)

var move_speed: float = 270.0
var max_hp: float = 100.0
var hp: float = 100.0
var damage: float = 18.0
var attack_speed: float = 4.0
var projectile_speed: float = 760.0
var currency_find: float = 0.0
var item_find: float = 0.0
var dash_speed: float = 720.0
var dash_duration: float = 0.12
var dash_cooldown: float = 0.85

var _attack_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cd_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _invulnerable: bool = false
var world_bounds: Rect2 = Rect2(40.0, 80.0, 1200.0, 590.0)
var projectile_parent: Node = null

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()

func configure(stats: Dictionary) -> void:
	move_speed = float(stats.get("move_speed", 270.0))
	max_hp = float(stats.get("max_hp", 100.0))
	hp = max_hp
	damage = float(stats.get("damage", 18.0))
	attack_speed = float(stats.get("attack_speed", 4.0))
	currency_find = float(stats.get("currency_find", 0.0))
	item_find = float(stats.get("item_find", 0.0))
	hp_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_dash_timer = maxf(0.0, _dash_timer - delta)
	_dash_cd_timer = maxf(0.0, _dash_cd_timer - delta)

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dash") and _dash_cd_timer <= 0.0 and input_dir.length_squared() > 0.0:
		_dash_dir = input_dir.normalized()
		_dash_timer = dash_duration
		_dash_cd_timer = dash_cooldown
		_invulnerable = true

	if _dash_timer > 0.0:
		velocity = _dash_dir * dash_speed
	else:
		_invulnerable = false
		velocity = input_dir * move_speed

	move_and_slide()
	global_position.x = clampf(global_position.x, world_bounds.position.x, world_bounds.end.x)
	global_position.y = clampf(global_position.y, world_bounds.position.y, world_bounds.end.y)

	look_at(get_global_mouse_position())
	if Input.is_action_pressed("attack") and _attack_timer <= 0.0:
		_attack_timer = 1.0 / maxf(0.1, attack_speed)
		_fire()

func _fire() -> void:
	if projectile_parent == null:
		return
	var projectile := LootProjectile.new()
	projectile.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 24.0
	projectile.direction = Vector2.RIGHT.rotated(rotation)
	projectile.damage = damage
	projectile.speed = projectile_speed
	projectile_parent.add_child(projectile)

func take_damage(amount: float) -> void:
	if _invulnerable or hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	hp_changed.emit(hp, max_hp)
	queue_redraw()
	if hp <= 0.0:
		died.emit()
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(0.28, 0.78, 1.0))
	draw_circle(Vector2.ZERO, 10.0, Color(0.08, 0.12, 0.17))
	draw_rect(Rect2(8.0, -4.0, 23.0, 8.0), Color(0.85, 0.88, 0.92))
	draw_circle(Vector2(0.0, -6.0), 3.0, Color.WHITE)
