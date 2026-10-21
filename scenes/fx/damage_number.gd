extends Node2D
## Chiffre de dégâts : jaillit, monte en ralentissant, puis s'efface.

const LIFETIME := 0.7
const RISE := 14.0

var _text := PixelText.new()
var _time := 0.0
var _start := Vector2.ZERO
var _drift := 0.0


func setup(text: String, color: Color) -> void:
	_text.text = text
	_text.modulate = color


func _ready() -> void:
	z_index = 6
	_start = position
	_drift = randf_range(-12.0, 12.0)
	_start.y -= randf_range(0.0, 5.0)
	add_child(_text)


func _process(delta: float) -> void:
	_time += delta
	var t := _time / LIFETIME
	if t >= 1.0:
		queue_free()
		return
	var ease_out := 1.0 - pow(1.0 - t, 3.0)
	position = (_start + Vector2(_drift * ease_out, -RISE * ease_out)).round()
	modulate.a = 1.0 if t < 0.6 else 1.0 - (t - 0.6) / 0.4
