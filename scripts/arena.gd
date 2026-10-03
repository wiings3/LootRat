class_name LootArena
extends Node2D

var bounds: Rect2 = Rect2(40.0, 80.0, 1200.0, 590.0)
var room_depth: int = 1
var room_index: int = 1
var total_rooms: int = 5
var room_type: String = "PACK"
var decorations: Array[Vector2] = []

func _ready() -> void:
	configure_room(1, 1, 5, "PACK")

func configure_room(depth_value: int, index_value: int, total_value: int, type_value: String) -> void:
	room_depth = depth_value
	room_index = index_value
	total_rooms = total_value
	room_type = type_value
	decorations.clear()
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(depth_value * 1009 + index_value * 9176 + type_value.hash())
	for _i in range(14):
		decorations.append(Vector2(
			local_rng.randf_range(bounds.position.x + 70.0, bounds.end.x - 70.0),
			local_rng.randf_range(bounds.position.y + 60.0, bounds.end.y - 60.0)
		))
	queue_redraw()

func _draw() -> void:
	var floor_color := Color(0.055, 0.065, 0.085)
	var accent := Color(0.32, 0.38, 0.5)
	match room_type:
		"SWARM":
			floor_color = Color(0.075, 0.052, 0.060)
			accent = Color(0.75, 0.25, 0.28)
		"ELITE":
			floor_color = Color(0.075, 0.058, 0.035)
			accent = Color(1.0, 0.54, 0.08)
		"TREASURE":
			floor_color = Color(0.070, 0.066, 0.035)
			accent = Color(0.94, 0.76, 0.16)
		"BOSS":
			floor_color = Color(0.075, 0.038, 0.070)
			accent = Color(0.78, 0.23, 0.72)

	draw_rect(bounds, floor_color)
	var step: int = 64
	for x in range(int(bounds.position.x), int(bounds.end.x) + 1, step):
		draw_line(Vector2(float(x), bounds.position.y), Vector2(float(x), bounds.end.y), Color(0.11, 0.125, 0.15, 0.72), 1.0)
	for y in range(int(bounds.position.y), int(bounds.end.y) + 1, step):
		draw_line(Vector2(bounds.position.x, float(y)), Vector2(bounds.end.x, float(y)), Color(0.11, 0.125, 0.15, 0.72), 1.0)

	for p: Vector2 in decorations:
		draw_rect(Rect2(p - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), Color(accent.r, accent.g, accent.b, 0.12))
		draw_circle(p, 3.0, Color(accent.r, accent.g, accent.b, 0.32))

	draw_rect(bounds, accent, false, 4.0)
	var door_rect := Rect2(bounds.end.x - 12.0, bounds.get_center().y - 48.0, 18.0, 96.0)
	if room_index < total_rooms:
		draw_rect(door_rect, Color(accent.r, accent.g, accent.b, 0.82))
	else:
		draw_rect(door_rect, Color(0.85, 0.3, 0.8, 0.9))
