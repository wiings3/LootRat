class_name LootEnemy
extends CharacterBody2D

signal killed(enemy: LootEnemy)

var target: LootPlayer = null
var max_hp: float = 35.0
var hp: float = 35.0
var move_speed: float = 105.0
var contact_damage: float = 10.0
var attack_cooldown: float = 0.7
var attack_range: float = 38.0
var reward_scale: float = 1.0
var is_elite: bool = false
var enemy_kind: int = 0

var _attack_timer: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0 if not is_elite else 21.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()

func configure(kind: int, depth: int, elite: bool) -> void:
	enemy_kind = kind
	is_elite = elite
	var depth_scale: float = 1.0 + float(maxi(0, depth - 1)) * 0.18
	match enemy_kind:
		0:
			max_hp = 30.0 * depth_scale
			move_speed = 110.0 + float(depth) * 2.0
			contact_damage = 9.0 * depth_scale
		1:
			max_hp = 18.0 * depth_scale
			move_speed = 175.0 + float(depth) * 3.0
			contact_damage = 7.0 * depth_scale
		2:
			max_hp = 72.0 * depth_scale
			move_speed = 72.0 + float(depth)
			contact_damage = 15.0 * depth_scale
	if is_elite:
		max_hp *= 2.6
		move_speed *= 1.12
		contact_damage *= 1.55
		attack_range = 45.0
		reward_scale = 4.0
	else:
		attack_range = 38.0
	hp = max_hp
	queue_redraw()

func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var to_target: Vector2 = target.global_position - global_position
	var distance_to_target: float = to_target.length()
	# CharacterBody2D collision keeps enemy/player centers roughly 31-37 px
	# apart, so the old 23 px attack threshold could never be reached.
	if distance_to_target > attack_range:
		velocity = to_target.normalized() * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			target.take_damage(contact_damage)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		killed.emit(self)
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var body_color: Color
	match enemy_kind:
		1:
			body_color = Color(1.0, 0.42, 0.35)
		2:
			body_color = Color(0.55, 0.34, 0.75)
		_:
			body_color = Color(0.42, 0.85, 0.38)
	if is_elite:
		body_color = Color(1.0, 0.54, 0.08)
		draw_circle(Vector2.ZERO, 25.0, Color(1.0, 0.72, 0.08, 0.2))
	var radius: float = 21.0 if is_elite else 15.0
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_circle(Vector2(-5.0, -4.0), 2.5, Color(0.07, 0.07, 0.09))
	draw_circle(Vector2(5.0, -4.0), 2.5, Color(0.07, 0.07, 0.09))
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0)
	if ratio < 1.0:
		draw_rect(Rect2(-18.0, -27.0, 36.0, 4.0), Color(0.15, 0.03, 0.03))
		draw_rect(Rect2(-18.0, -27.0, 36.0 * ratio, 4.0), Color(0.95, 0.18, 0.18))
