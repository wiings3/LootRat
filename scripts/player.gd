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
var weapon_archetype: String = "gun"
var weapon_core: String = "repeater"
var dash_speed: float = 720.0
var dash_duration: float = 0.12
var dash_cooldown: float = 0.85

# Mechanical affix runtime values.
var dash_cooldown_mult: float = 1.0
var pickup_radius: float = 145.0
var gear_pickup_heal: float = 0.0
var kill_heal: float = 0.0
var damage_taken_mult: float = 1.0
var hurt_speed_bonus: float = 0.0
var hurt_speed_duration: float = 0.0
var point_blank_bonus: float = 0.0
var point_blank_range: float = 125.0
var knockback_mult: float = 1.0
var projectile_radius_mult: float = 1.0
var bonus_pierce: int = 0
var bonus_projectiles: int = 0
var projectile_damage_mult: float = 1.0
var ricochet_count: int = 0
var frenzy_on_kill: bool = false
var explosion_fraction: float = 0.0
var treasure_room_bonus: float = 0.0
var elite_currency_bonus: float = 0.0
var normal_currency_penalty: float = 0.0
var gear_duplicate_chance: float = 0.0
var cheat_death: bool = false
var melee_damage_mult: float = 1.0
var melee_range_mult: float = 1.0

var _attack_timer: float = 0.0
var _melee_flash_timer: float = 0.0
var _active_recall_blade: LootProjectile = null
var _dash_timer: float = 0.0
var _dash_cd_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _invulnerable: bool = false
var _hurt_flash_timer: float = 0.0
var _hurt_speed_timer: float = 0.0
var _frenzy_timer: float = 0.0
var _frenzy_stacks: int = 0
var _cheat_death_available: bool = false
var world_bounds: Rect2 = Rect2(40.0, 80.0, 1200.0, 590.0)
var projectile_parent: Node = null
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
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
	weapon_archetype = String(stats.get("weapon_archetype", "gun"))
	weapon_core = String(stats.get("weapon_core", "repeater"))
	dash_cooldown_mult = float(stats.get("dash_cooldown_mult", 1.0))
	pickup_radius = float(stats.get("pickup_radius", 145.0))
	gear_pickup_heal = float(stats.get("gear_pickup_heal", 0.0))
	kill_heal = float(stats.get("kill_heal", 0.0))
	damage_taken_mult = float(stats.get("damage_taken_mult", 1.0))
	hurt_speed_bonus = float(stats.get("hurt_speed_bonus", 0.0))
	hurt_speed_duration = float(stats.get("hurt_speed_duration", 0.0))
	point_blank_bonus = float(stats.get("point_blank_bonus", 0.0))
	point_blank_range = float(stats.get("point_blank_range", 125.0))
	knockback_mult = float(stats.get("knockback_mult", 1.0))
	projectile_radius_mult = float(stats.get("projectile_radius_mult", 1.0))
	bonus_pierce = int(stats.get("bonus_pierce", 0))
	bonus_projectiles = int(stats.get("bonus_projectiles", 0))
	projectile_damage_mult = float(stats.get("projectile_damage_mult", 1.0))
	ricochet_count = int(stats.get("ricochet_count", 0))
	frenzy_on_kill = bool(stats.get("frenzy_on_kill", false))
	explosion_fraction = float(stats.get("explosion_fraction", 0.0))
	treasure_room_bonus = float(stats.get("treasure_room_bonus", 0.0))
	elite_currency_bonus = float(stats.get("elite_currency_bonus", 0.0))
	normal_currency_penalty = float(stats.get("normal_currency_penalty", 0.0))
	gear_duplicate_chance = float(stats.get("gear_duplicate_chance", 0.0))
	cheat_death = bool(stats.get("cheat_death", false))
	melee_damage_mult = float(stats.get("melee_damage_mult", 1.0))
	melee_range_mult = float(stats.get("melee_range_mult", 1.0))
	_cheat_death_available = cheat_death
	hp_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_melee_flash_timer = maxf(0.0, _melee_flash_timer - delta)
	_dash_timer = maxf(0.0, _dash_timer - delta)
	_dash_cd_timer = maxf(0.0, _dash_cd_timer - delta)
	_hurt_flash_timer = maxf(0.0, _hurt_flash_timer - delta)
	_hurt_speed_timer = maxf(0.0, _hurt_speed_timer - delta)
	_frenzy_timer = maxf(0.0, _frenzy_timer - delta)
	if _frenzy_timer <= 0.0:
		_frenzy_stacks = 0
	if _hurt_flash_timer > 0.0 or _melee_flash_timer > 0.0:
		queue_redraw()

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dash") and _dash_cd_timer <= 0.0 and input_dir.length_squared() > 0.0:
		_dash_dir = input_dir.normalized()
		_dash_timer = dash_duration
		_dash_cd_timer = dash_cooldown * dash_cooldown_mult
		_invulnerable = true

	var movement_mult: float = 1.0 + (hurt_speed_bonus if _hurt_speed_timer > 0.0 else 0.0)
	if _dash_timer > 0.0:
		velocity = _dash_dir * dash_speed
	else:
		_invulnerable = false
		velocity = input_dir * move_speed * movement_mult

	move_and_slide()
	global_position.x = clampf(global_position.x, world_bounds.position.x, world_bounds.end.x)
	global_position.y = clampf(global_position.y, world_bounds.position.y, world_bounds.end.y)

	look_at(get_global_mouse_position())
	var frenzy_mult: float = 1.0 + float(_frenzy_stacks) * 0.08
	if weapon_archetype == "blade" and weapon_core == "throwing":
		if Input.is_action_just_pressed("attack") and _attack_timer <= 0.0:
			if is_instance_valid(_active_recall_blade) and not _active_recall_blade.returning:
				_active_recall_blade.force_return()
				_attack_timer = 0.12
			elif not is_instance_valid(_active_recall_blade):
				_attack_timer = 1.0 / maxf(0.1, attack_speed * _weapon_rate_multiplier() * frenzy_mult)
				_fire()
	elif Input.is_action_pressed("attack") and _attack_timer <= 0.0:
		_attack_timer = 1.0 / maxf(0.1, attack_speed * _weapon_rate_multiplier() * frenzy_mult)
		_fire()

func _weapon_rate_multiplier() -> float:
	if weapon_archetype == "blade":
		match weapon_core:
			"duelist": return 1.35
			"whirlwind": return 0.62
			"throwing": return 0.80
			_: return 0.72
	match weapon_core:
		"scatter": return 0.42
		"piercer": return 0.35
		"sprayer": return 1.80
		_: return 1.0

func _fire() -> void:
	if projectile_parent == null:
		return
	var aim: Vector2 = Vector2.RIGHT.rotated(rotation)
	if weapon_archetype == "blade":
		_fire_blade(aim)
		return

	match weapon_core:
		"scatter":
			var pellet_count: int = 5 + bonus_projectiles * 2
			for pellet in range(pellet_count):
				var centered_index: float = float(pellet) - float(pellet_count - 1) * 0.5
				var spread: float = deg_to_rad(centered_index * 5.5)
				_spawn_projectile(aim.rotated(spread), damage * 0.42 * projectile_damage_mult, projectile_speed * 0.86, 0, 4.5, 145.0)
		"piercer":
			_fire_parallel_shots(aim, damage * 2.4 * projectile_damage_mult, projectile_speed * 1.18, 3, 8.0, 310.0)
		"sprayer":
			var jitter: float = deg_to_rad(rng.randf_range(-5.0, 5.0))
			_fire_parallel_shots(aim.rotated(jitter), damage * 0.52 * projectile_damage_mult, projectile_speed * 1.05, 0, 3.5, 70.0)
		_:
			_fire_parallel_shots(aim, damage * projectile_damage_mult, projectile_speed, 0, 5.0, 110.0)

func _fire_blade(aim: Vector2) -> void:
	match weapon_core:
		"duelist":
			_melee_attack(aim, 115.0 * melee_range_mult, 35.0, damage * 0.90 * melee_damage_mult, 85.0)
		"whirlwind":
			_melee_attack(aim, 78.0 * melee_range_mult, 360.0, damage * 0.80 * melee_damage_mult, 130.0)
		"throwing":
			_spawn_recall_blade(aim)
		_:
			_melee_attack(aim, 82.0 * melee_range_mult, 105.0, damage * 1.35 * melee_damage_mult, 185.0)

func _melee_attack(aim: Vector2, reach: float, arc_degrees: float, hit_damage: float, knockback_force: float) -> void:
	_melee_flash_timer = 0.11
	queue_redraw()
	var half_arc: float = deg_to_rad(arc_degrees * 0.5)
	for node: Node in get_tree().get_nodes_in_group("loot_enemies"):
		if not node is LootEnemy:
			continue
		var enemy := node as LootEnemy
		if not is_instance_valid(enemy) or enemy.hp <= 0.0:
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var distance: float = offset.length()
		if distance > reach + 18.0 or distance <= 0.001:
			continue
		if arc_degrees < 359.0:
			var angle_delta: float = absf(aim.angle_to(offset.normalized()))
			if angle_delta > half_arc:
				continue
		var push_dir: Vector2 = offset.normalized()
		enemy.take_damage(hit_damage, push_dir, knockback_force * knockback_mult)

func _fire_parallel_shots(aim: Vector2, shot_damage: float, shot_speed: float, base_pierce: int, radius: float, knockback_force: float) -> void:
	var shot_count: int = 1 + bonus_projectiles
	for shot_index in range(shot_count):
		var centered_index: float = float(shot_index) - float(shot_count - 1) * 0.5
		var spread: float = deg_to_rad(centered_index * 6.0)
		_spawn_projectile(aim.rotated(spread), shot_damage, shot_speed, base_pierce, radius, knockback_force)

func _spawn_recall_blade(aim: Vector2) -> void:
	var projectile := LootProjectile.new()
	projectile.direction = aim.normalized()
	projectile.damage = damage * 1.15 * melee_damage_mult
	projectile.speed = projectile_speed * 0.78
	projectile.pierces = 99
	projectile.radius = 8.0 * projectile_radius_mult
	projectile.knockback_force = 115.0 * knockback_mult
	projectile.core_id = "throwing"
	projectile.origin_position = global_position
	projectile.return_target = self
	projectile.return_distance = 310.0 * melee_range_mult
	projectile.life = 3.0
	projectile_parent.add_child(projectile)
	projectile.global_position = global_position + aim.normalized() * 28.0
	_active_recall_blade = projectile

func _spawn_projectile(dir: Vector2, shot_damage: float, shot_speed: float, pierce_count: int, radius: float, knockback_force: float) -> void:
	var projectile := LootProjectile.new()
	projectile.direction = dir.normalized()
	projectile.damage = shot_damage
	projectile.speed = shot_speed
	projectile.pierces = pierce_count + bonus_pierce
	projectile.radius = radius * projectile_radius_mult
	projectile.knockback_force = knockback_force * knockback_mult
	projectile.core_id = weapon_core
	projectile.origin_position = global_position
	projectile.point_blank_bonus = point_blank_bonus
	projectile.point_blank_range = point_blank_range
	projectile.ricochets = ricochet_count
	projectile.explosion_fraction = explosion_fraction
	projectile_parent.add_child(projectile)
	projectile.global_position = global_position + dir.normalized() * 25.0

func register_kill() -> void:
	if kill_heal > 0.0:
		heal(kill_heal)
	if frenzy_on_kill:
		_frenzy_stacks = mini(5, _frenzy_stacks + 1)
		_frenzy_timer = 3.0

func register_gear_pickup() -> void:
	if gear_pickup_heal > 0.0:
		heal(gear_pickup_heal)

func heal(amount: float) -> void:
	if hp <= 0.0 or amount <= 0.0:
		return
	var old_hp: float = hp
	hp = minf(max_hp, hp + amount)
	if hp != old_hp:
		hp_changed.emit(hp, max_hp)

func take_damage(amount: float) -> void:
	if _invulnerable or hp <= 0.0:
		return
	var final_damage: float = amount * damage_taken_mult
	if cheat_death and _cheat_death_available and hp - final_damage <= 0.0:
		_cheat_death_available = false
		hp = 1.0
		_hurt_flash_timer = 0.25
		_hurt_speed_timer = hurt_speed_duration
		hp_changed.emit(hp, max_hp)
		queue_redraw()
		return

	hp = maxf(0.0, hp - final_damage)
	_hurt_flash_timer = 0.12
	if hurt_speed_bonus > 0.0:
		_hurt_speed_timer = hurt_speed_duration
	hp_changed.emit(hp, max_hp)
	queue_redraw()
	if hp <= 0.0:
		died.emit()
		queue_free()

func _draw() -> void:
	var body_color := Color(1.0, 0.38, 0.38) if _hurt_flash_timer > 0.0 else Color(0.28, 0.78, 1.0)
	draw_circle(Vector2.ZERO, 16.0, body_color)
	draw_circle(Vector2.ZERO, 10.0, Color(0.08, 0.12, 0.17))

	if weapon_archetype == "blade":
		var blade_color := Color(0.92, 0.91, 0.78)
		draw_line(Vector2(9.0, 0.0), Vector2(34.0, 0.0), blade_color, 5.0)
		draw_line(Vector2(11.0, -7.0), Vector2(11.0, 7.0), Color(0.48, 0.34, 0.20), 4.0)
		if _melee_flash_timer > 0.0:
			var flash_color := Color(1.0, 0.78, 0.32, 0.80)
			match weapon_core:
				"duelist":
					draw_line(Vector2(22.0, 0.0), Vector2(115.0 * melee_range_mult, 0.0), flash_color, 7.0)
				"whirlwind":
					draw_arc(Vector2.ZERO, 78.0 * melee_range_mult, 0.0, TAU, 42, flash_color, 5.0)
				"throwing":
					draw_line(Vector2(22.0, 0.0), Vector2(48.0, 0.0), flash_color, 4.0)
				_:
					draw_arc(Vector2.ZERO, 82.0 * melee_range_mult, deg_to_rad(-52.5), deg_to_rad(52.5), 20, flash_color, 6.0)
	else:
		var gun_color := Color(0.85, 0.88, 0.92)
		match weapon_core:
			"scatter": gun_color = Color(1.0, 0.62, 0.24)
			"piercer": gun_color = Color(0.75, 0.45, 1.0)
			"sprayer": gun_color = Color(0.38, 1.0, 0.62)
		draw_rect(Rect2(8.0, -4.0, 23.0, 8.0), gun_color)

	draw_circle(Vector2(0.0, -6.0), 3.0, Color.WHITE)
