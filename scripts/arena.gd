class_name LootArena
extends Node2D

var bounds: Rect2 = Rect2(40.0, 80.0, 1200.0, 590.0)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(bounds, Color(0.055, 0.065, 0.085))
	var step: int = 64
	for x in range(int(bounds.position.x), int(bounds.end.x) + 1, step):
		draw_line(Vector2(float(x), bounds.position.y), Vector2(float(x), bounds.end.y), Color(0.11,0.125,0.15), 1.0)
	for y in range(int(bounds.position.y), int(bounds.end.y) + 1, step):
		draw_line(Vector2(bounds.position.x, float(y)), Vector2(bounds.end.x, float(y)), Color(0.11,0.125,0.15), 1.0)
	draw_rect(bounds, Color(0.32, 0.38, 0.5), false, 4.0)
