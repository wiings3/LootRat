class_name LootEnemy
extends CharacterBody2D

const EnemyProjectileScript = preload("res://scripts/enemy_projectile.gd")

signal killed(enemy: LootEnemy)

var target: LootPlayer = null
var projectile_parent: Node = null
var max_hp: float = 35.0
var hp: float = 35.0
var move_speed: float = 105.0
var contact_damage: float = 10.0
var attack_cooldown: float = 0.7
var attack_range: float = 38.0
var reward_scale: float = 1.0
var is_elite: bool = false
var is_boss: bool = false
var enemy_kind: int = 0

var _attack_timer: float = 0.0
var _hit_flash_timer: float = 0.0
var _attack_flash_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 25.0 if is_boss else (21.0 if is_elite else 15.0)
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
			move_speed = 112.0 + float(depth) * 2.0
			contact_damage = 9.0 * depth_scale
			attack_cooldown = 0.72
			reward_scale = 1.0
		1:
			max_hp = 17.0 * depth_scale
			move_speed = 190.0 + float(depth) * 3.0
			contact_damage = 6.0 * depth_scale
			attack_cooldown = 0.55
			reward_scale = 0.80
		2:
			max_hp = 78.0 * depth_scale
			move_speed = 70.0 + float(depth)
			contact_damage = 16.0 * depth_scale
			attack_cooldown = 1.0
			reward_scale = 1.65
		3:
			max_hp = 25.0 * depth_scale
			move_speed = 94.0 + float(depth) * 1.5
			contact_damage = 8.0 * depth_scale
			attack_cooldown = 1.25
			attack_range = 255.0
			reward_scale = 1.20
	if is_elite:
		max_hp *= 2.6
		move_speed *= 1.10
		contact_damage *= 1.55
		reward_scale *= 3.3
		if enemy_kind != 3:
			attack_range = 45.0
	elif enemy_kind != 3:
		attack_range = 38.0
	hp = max_hp
	queue_redraw()

func make_boss(depth: int) -> void:
	is_boss = true
	is_elite = true
	max_hp *= 2.25
	hp = max_hp
	move_speed *= 0.92
	contact_damage *= 1.28
	attack_range = 52.0
	reward_scale = maxf(reward_scale, 10.0 + float(depth) * 0.5)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
	_attack_flash_timer = maxf(0.0, _attack_flash_timer - delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 850.0 * delta)
	if _hit_flash_timer > 0.0 or _attack_flash_timer > 0.0:
		queue_redraw()

	if not is_instance_valid(target):
		velocity = _knockback_velocity
		move_and_slide()
		return

	var to_target: Vector2 = target.global_position - global_position
	var distance_to_target: float = to_target.length()
	var desired_velocity := Vector2.ZERO

	if enemy_kind == 3:
		if distance_to_target > 235.0:
			desired_velocity = to_target.normalized() * move_speed
		elif distance_to_target < 135.0:
			desired_velocity = -to_target.normalized() * move_speed * 0.82
		elif _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			_attack_flash_timer = 0.18
			call_deferred("_fire_ranged_projectile", to_target.normalized())
	else:
		if distance_to_target > attack_range:
			desired_velocity = to_target.normalized() * move_speed
		elif _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			_attack_flash_timer = 0.12
			target.take_damage(contact_damage)

	velocity = desired_velocity + _knockback_velocity
	move_and_slide()

func _fire_ranged_projectile(direction: Vector2) -> void:
	if projectile_parent == null or not is_instance_valid(target):
		return
	var projectile := EnemyProjectileScript.new()
	projectile.direction = direction.normalized()
	projectile.damage = contact_damage
	projectile.speed = 410.0 if is_elite else 340.0
	projectile.radius = 8.0 if is_elite else 6.0
	projectile.is_elite = is_elite
	projectile_parent.add_child(projectile)
	projectile.global_position = global_position + projectile.direction * (34.0 if is_elite else 27.0)

func take_damage(amount: float, hit_direction: Vector2 = Vector2.ZERO, force: float = 0.0) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	_hit_flash_timer = 0.10
	if hit_direction.length_squared() > 0.0 and force > 0.0:
		_knockback_velocity += hit_direction.normalized() * force
	call_deferred("_spawn_damage_number", amount)
	if hp <= 0.0:
		killed.emit(self)
		queue_free()
	else:
		queue_redraw()

func _spawn_damage_number(amount: float) -> void:
	if not is_inside_tree():
		return
	var label := Label.new()
	label.text = str(maxi(1, int(round(amount))))
	label.z_index = 20
	label.add_theme_font_size_override("font_size", 17 if not is_boss else 21)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.66))
	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector2(-8.0, -30.0)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0.0, -28.0), 0.38)
	tween.tween_property(label, "modulate:a", 0.0, 0.38)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)

func _draw() -> void:
	var body_color: Color
	match enemy_kind:
		1:
			body_color = Color(1.0, 0.42, 0.35)
		2:
			body_color = Color(0.55, 0.34, 0.75)
		3:
			body_color = Color(0.25, 0.72, 0.86)
		_:
			body_color = Color(0.42, 0.85, 0.38)
	if is_elite:
		body_color = Color(1.0, 0.54, 0.08)
	if is_boss:
		body_color = Color(0.88, 0.25, 0.72)
	if _hit_flash_timer > 0.0:
		body_color = Color.WHITE

	var radius: float = 25.0 if is_boss else (21.0 if is_elite else 15.0)
	if is_elite:
		draw_circle(Vector2.ZERO, radius + 5.0, Color(body_color.r, body_color.g, body_color.b, 0.18))
	draw_circle(Vector2.ZERO, radius, body_color)
	if enemy_kind == 3:
		draw_rect(Rect2(-4.0, -radius - 8.0, 8.0, 13.0), Color(0.72, 0.92, 1.0))
	draw_circle(Vector2(-5.0, -4.0), 2.5, Color(0.07, 0.07, 0.09))
	draw_circle(Vector2(5.0, -4.0), 2.5, Color(0.07, 0.07, 0.09))
	if _attack_flash_timer > 0.0:
		draw_circle(Vector2.ZERO, radius + 10.0, Color(1.0, 0.18, 0.12, 0.28), false, 3.0)

	var ratio: float = clampf(hp / max_hp, 0.0, 1.0)
	if ratio < 1.0:
		var bar_width: float = 50.0 if is_boss else 36.0
		draw_rect(Rect2(-bar_width * 0.5, -radius - 12.0, bar_width, 4.0), Color(0.15, 0.03, 0.03))
		draw_rect(Rect2(-bar_width * 0.5, -radius - 12.0, bar_width * ratio, 4.0), Color(0.95, 0.18, 0.18))
