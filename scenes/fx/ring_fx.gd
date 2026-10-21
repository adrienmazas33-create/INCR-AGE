extends Node2D
## Cercle qui s'ouvre jusqu'à un rayon puis s'efface (montre le nouveau rayon de l'aimant).

const LIFETIME := 0.9

var radius := 96.0
var color := Color.WHITE
var _time := 0.0


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	_time += delta
	if _time >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _time / LIFETIME
	var r := radius * (0.55 + 0.45 * (1.0 - pow(1.0 - minf(t * 1.6, 1.0), 3.0)))
	var a := 1.0 if t < 0.6 else 1.0 - (t - 0.6) / 0.4
	draw_arc(Vector2.ZERO, roundf(r), 0.0, TAU, 96, Color(color, a), 1.0, false)
	draw_arc(Vector2.ZERO, roundf(r) - 2.0, 0.0, TAU, 96, Color(color, a * 0.35), 1.0, false)
