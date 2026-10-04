class_name LootHideout
extends Node2D

var bounds: Rect2 = Rect2(70.0, 105.0, 1140.0, 535.0)
var stations: Dictionary = {
	"stash": Vector2(270.0, 270.0),
	"craft": Vector2(640.0, 255.0),
	"claim": Vector2(1010.0, 285.0)
}

func _ready() -> void:
	queue_redraw()

func get_station_position(station_name: String) -> Vector2:
	var value: Variant = stations.get(station_name, bounds.get_center())
	return value as Vector2

func get_station_prompt(station_name: String) -> String:
	match station_name:
		"stash": return "Open Stash"
		"craft": return "Use Crafting Bench"
		"claim": return "Open Claim Table"
		_: return "Interact"

func _draw() -> void:
	draw_rect(bounds, Color(0.040, 0.043, 0.050))
	draw_rect(bounds, Color(0.20, 0.16, 0.11), false, 6.0)

	var tile: int = 72
	for x in range(int(bounds.position.x), int(bounds.end.x), tile):
		for y in range(int(bounds.position.y), int(bounds.end.y), tile):
			var checker: int = int(x / tile) + int(y / tile)
			var alt: float = 0.008 if checker % 2 == 0 else 0.0
			draw_rect(Rect2(float(x), float(y), float(tile - 2), float(tile - 2)), Color(0.055 + alt, 0.058 + alt, 0.064 + alt))

	draw_rect(Rect2(455.0, 420.0, 370.0, 105.0), Color(0.12, 0.075, 0.052))
	draw_rect(Rect2(455.0, 420.0, 370.0, 105.0), Color(0.28, 0.16, 0.09), false, 3.0)

	_draw_stash(stations["stash"] as Vector2)
	_draw_crafting_bench(stations["craft"] as Vector2)
	_draw_claim_table(stations["claim"] as Vector2)

	var clutter: Array[Vector2] = [Vector2(120,150), Vector2(150,560), Vector2(1120,155), Vector2(1160,560)]
	for p: Vector2 in clutter:
		draw_circle(p, 28.0, Color(0.11, 0.09, 0.07))
		draw_circle(p + Vector2(0,-4), 18.0, Color(0.16, 0.12, 0.08))

func _draw_stash(pos: Vector2) -> void:
	draw_circle(pos, 72.0, Color(0.18, 0.15, 0.10, 0.22))
	draw_rect(Rect2(pos - Vector2(75,42), Vector2(150,84)), Color(0.17, 0.12, 0.07))
	draw_rect(Rect2(pos - Vector2(75,42), Vector2(150,84)), Color(0.48, 0.33, 0.14), false, 4.0)
	draw_line(pos + Vector2(-68,-20), pos + Vector2(68,-20), Color(0.52,0.36,0.16), 3.0)
	draw_circle(pos, 7.0, Color(0.85, 0.68, 0.24))
	_draw_station_label(pos + Vector2(0,72), "STASH")

func _draw_crafting_bench(pos: Vector2) -> void:
	draw_circle(pos, 78.0, Color(0.42, 0.20, 0.06, 0.16))
	draw_rect(Rect2(pos - Vector2(88,34), Vector2(176,68)), Color(0.14, 0.10, 0.075))
	draw_rect(Rect2(pos - Vector2(88,34), Vector2(176,68)), Color(0.62, 0.35, 0.12), false, 4.0)
	draw_circle(pos + Vector2(-38,-4), 13.0, Color(0.80, 0.38, 0.08))
	draw_circle(pos + Vector2(0,4), 10.0, Color(0.72, 0.70, 0.64))
	draw_line(pos + Vector2(25,-16), pos + Vector2(58,18), Color(0.70,0.72,0.74), 6.0)
	_draw_station_label(pos + Vector2(0,72), "CRAFTING BENCH")

func _draw_claim_table(pos: Vector2) -> void:
	draw_circle(pos, 82.0, Color(0.25, 0.10, 0.22, 0.18))
	draw_circle(pos, 55.0, Color(0.10, 0.075, 0.09))
	draw_circle(pos, 55.0, Color(0.62, 0.24, 0.52), false, 4.0)
	for i in range(8):
		var angle: float = TAU * float(i) / 8.0
		var a: Vector2 = pos + Vector2.RIGHT.rotated(angle) * 32.0
		var b: Vector2 = pos + Vector2.RIGHT.rotated(angle + 0.5) * 20.0
		draw_line(a, b, Color(0.72,0.32,0.62), 2.0)
	draw_circle(pos, 9.0, Color(0.95, 0.50, 0.82))
	_draw_station_label(pos + Vector2(0,82), "CLAIM TABLE")

func _draw_station_label(pos: Vector2, text_value: String) -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(font, pos - Vector2(width * 0.5, 0), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.78,0.76,0.72))
