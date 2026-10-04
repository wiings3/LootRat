class_name LootProjectile
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 760.0
var damage: float = 18.0
var life: float = 1.25
var pierces: int = 0
var radius: float = 5.0
var knockback_force: float = 110.0
var core_id: String = "repeater"
var origin_position: Vector2 = Vector2.ZERO
var point_blank_bonus: float = 0.0
var point_blank_range: float = 125.0
var ricochets: int = 0
var explosion_fraction: float = 0.0
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

	var hit_damage: float = damage
	if point_blank_bonus > 0.0 and global_position.distance_to(origin_position) <= point_blank_range:
		hit_damage *= 1.0 + point_blank_bonus

	var enemy := body as LootEnemy
	var killed: bool = enemy.take_damage(hit_damage, direction, knockback_force)
	if killed and explosion_fraction > 0.0:
		_explode(global_position, hit_damage * explosion_fraction)

	if pierces > 0:
		pierces -= 1
		return

	if ricochets > 0 and _retarget_ricochet():
		ricochets -= 1
		origin_position = global_position
		return

	queue_free()

func _retarget_ricochet() -> bool:
	var nearest: LootEnemy = null
	var nearest_distance: float = 180.0
	for node: Node in get_tree().get_nodes_in_group("loot_enemies"):
		if not node is LootEnemy:
			continue
		var candidate := node as LootEnemy
		if not is_instance_valid(candidate) or candidate.hp <= 0.0:
			continue
		if _hit_ids.has(candidate.get_instance_id()):
			continue
		var distance: float = global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	if nearest == null:
		return false
	direction = (nearest.global_position - global_position).normalized()
	rotation = direction.angle()
	return true

func _explode(center: Vector2, explosion_damage: float) -> void:
	for node: Node in get_tree().get_nodes_in_group("loot_enemies"):
		if not node is LootEnemy:
			continue
		var candidate := node as LootEnemy
		if not is_instance_valid(candidate) or candidate.hp <= 0.0:
			continue
		var offset: Vector2 = candidate.global_position - center
		if offset.length() > 105.0:
			continue
		var push_dir: Vector2 = offset.normalized() if offset.length_squared() > 0.0 else direction
		candidate.take_damage(explosion_damage, push_dir, knockback_force * 0.65)
	_spawn_explosion_visual(center)

func _spawn_explosion_visual(center: Vector2) -> void:
	if not is_inside_tree():
		return
	var ring := Node2D.new()
	ring.z_index = 5
	get_tree().current_scene.add_child(ring)
	ring.global_position = center
	ring.set_script(preload("res://scripts/explosion_flash.gd"))

func _draw() -> void:
	var outer := Color(1.0, 0.86, 0.2)
	match core_id:
		"scatter": outer = Color(1.0, 0.52, 0.18)
		"piercer": outer = Color(0.72, 0.38, 1.0)
		"sprayer": outer = Color(0.28, 1.0, 0.55)
		"throwing": outer = Color(1.0, 0.66, 0.26)
	draw_circle(Vector2.ZERO, radius, outer)
	draw_circle(Vector2.ZERO, maxf(1.5, radius * 0.42), Color.WHITE)
