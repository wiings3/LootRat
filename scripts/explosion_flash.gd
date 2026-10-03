extends Node2D

var age: float = 0.0
var duration: float = 0.22

func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= duration:
		queue_free()

func _draw() -> void:
	var t: float = clampf(age / duration, 0.0, 1.0)
	var radius: float = lerpf(12.0, 105.0, t)
	var alpha: float = 1.0 - t
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.48, 0.12, alpha * 0.10))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.72, 0.22, alpha * 0.85), 4.0)
